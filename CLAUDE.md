# CIRRCULO — Plan de Desarrollo para Claude Code
## Swift Changemakers Hackathon 2026 · Enactus México · Reto 1: Economía Circular

---

## Contexto del proyecto

CIRRCULO es una aplicación nativa para iPhone que conecta a cinco actores del ecosistema de residuos: ciudadanos, pepenadores/recolectores, empresas/restaurantes, puntos de acopio y centros de acopio. El núcleo tecnológico es un motor de clasificación de residuos con visión computacional que corre completamente on-device usando Core ML y Vision Framework.

El objetivo del hackathon es demostrar tres flujos completos (ciudadano, pepenador, empresa) con datos mockeados. Los perfiles de punto de acopio y centro de acopio existen en la app pero con pantallas de referencia, no flujos completos.

---

## Stack técnico obligatorio

- **Lenguaje:** Swift 5.9+
- **UI:** SwiftUI (preferido) con UIKit donde sea necesario
- **IDE:** Xcode 15+
- **Frameworks Apple — On-Device AI (criterio de 10 pts en rúbrica):**
  - `Core ML` — inferencia on-device del modelo de clasificación de residuos
  - `Vision` — procesamiento de imagen y requests de clasificación visual
  - `FoundationModels` — Apple Intelligence on-device LLM para asistente conversacional y generación de instrucciones contextuales (requiere iOS 18.1+, iPhone 15 Pro o superior)
- **Frameworks Apple — resto:**
  - `AVFoundation` — captura de cámara en tiempo real
  - `MapKit` — mapas, rutas y anotaciones
  - `CoreLocation` — GPS y geofencing
  - `SwiftCharts` — gráficas del dashboard de empresa
- **No permitido:** Vision Pro, CreateML en runtime, servicios externos de IA

> **Nota sobre Foundation Models:** El framework `FoundationModels` de Apple da acceso al modelo de lenguaje on-device que impulsa Apple Intelligence. Todo el procesamiento ocurre en el Neural Engine del dispositivo, sin enviar datos a servidores externos. Requiere iPhone 15 Pro / iPad con chip M1 o superior con iOS 18.1+. Para el hackathon, si el dispositivo de demo no lo soporta, implementar con un fallback graceful que muestre las instrucciones hardcodeadas.

---

## Arquitectura general

```
CIRRCULOApp
├── Onboarding
│   └── ProfileSelectorView          ← selección de perfil al abrir
│
├── Ciudadano (TabView)
│   ├── ScannerView                  ← cámara + Core ML (pantalla principal)
│   ├── AsistenteView                ← chat con Foundation Models (on-device LLM)
│   ├── DepositView                  ← QR + foto verificación en punto de acopio
│   ├── MapaAcopioView               ← MapKit con puntos de acopio cercanos
│   └── PerfilCiudadanoView          ← puntos, impacto, historial
│
├── Pepenador (TabView)
│   ├── MapaRutasView                ← MapKit con puntos disponibles
│   ├── DetallePuntoView             ← material, kg estimado, valor
│   ├── EntregaView                  ← confirmar entrega al centro de acopio
│   └── HistorialView                ← recolecciones e ingresos
│
├── Empresa (TabView)
│   ├── DashboardView                ← trazabilidad y métricas
│   ├── ScannerEmpresaView           ← reutiliza ScannerView con modo empresa
│   ├── AhorroFiscalView             ← calculadora de beneficios fiscales
│   ├── ResumenLegalView             ← Foundation Models genera resumen en lenguaje natural
│   └── EquipoView                   ← gestión de empleados
│
├── PuntoAcopio (referencia)
│   ├── PanelContenedoresView
│   └── QREstaticoView              ← QR único del local (se muestra en pared)
│
└── CentroAcopio (referencia)
    ├── ConfirmarRecepcionView
    └── PreciosMaterialView
```

---

## Modelos de datos principales

```swift
// Tipos de residuo reconocidos por la IA
enum TipoResiduo: String, CaseIterable {
    case plasticoPET = "Plástico PET"
    case plasticoHDPE = "Plástico HDPE"
    case carton = "Cartón"
    case papel = "Papel"
    case vidrio = "Vidrio"
    case aluminio = "Aluminio"
    case lata = "Lata"
    case organicoComida = "Orgánico - comida"
    case organicoPoda = "Orgánico - poda"
    case noReciclable = "No reciclable"
    case tetraPak = "Tetra Pak"
}

// Color del contenedor según NADF-024 CDMX
enum ContenedorNADF: String {
    case verde = "Verde"       // orgánicos
    case gris = "Gris"         // inorgánicos reciclables
    case naranja = "Naranja"   // no reciclables
}

// Días de recolección por contenedor en CDMX
// Verde: Martes, Jueves, Sábado
// Gris y Naranja: Lunes, Miércoles, Viernes, Domingo

struct ResultadoClasificacion {
    let tipo: TipoResiduo
    let contenedor: ContenedorNADF
    let confianza: Float           // 0.0 - 1.0
    let proximaRecoleccion: String // ej. "Mañana, Miércoles"
    let instrucciones: String      // texto de ayuda
    let valorMercado: Double       // MXN/kg referencial
}

struct PuntoAcopio: Identifiable {
    let id: UUID
    let nombre: String
    let direccion: String
    let coordenadas: CLLocationCoordinate2D
    let qrCode: String             // identificador único del QR estático
    var materialDisponible: [TipoResiduo: Double]  // tipo → kg acumulados
    var capacidadTotal: Double     // kg máximos
    var activo: Bool
}

struct DepositoTicket {
    let id: UUID
    let ciudadanoId: String
    let puntoAcopioId: UUID
    let materiales: [TipoResiduo: Double]
    let fotoVerificacion: Data?    // imagen tomada en el punto
    let timestamp: Date
    var puntosOtorgados: Int
    var verificado: Bool
}

struct SolicitudRecoleccion {
    let id: UUID
    let puntoAcopio: PuntoAcopio
    let kgEstimados: Double
    let valorEstimado: Double      // MXN
    let materialesPrincipales: [TipoResiduo]
    let timestampPublicacion: Date
    var reclamadaPor: String?      // pepenadorId, nil si disponible
    var estado: EstadoRecoleccion
}

enum EstadoRecoleccion {
    case disponible
    case reclamada
    case enRuta
    case entregada
}

struct RegistroEmpresa {
    let empresaId: String
    var residuosRegistrados: [RegistroResiduo]
    var kgTotalesMes: Double
    var ahorroFiscalEstimado: Double
}

struct RegistroResiduo {
    let tipo: TipoResiduo
    let kg: Double
    let timestamp: Date
    let empleadoId: String
    let destinoCentroAcopio: String?
}
```

---

## FASE 0 — Setup inicial del proyecto
**Objetivo:** Proyecto base corriendo con navegación funcional entre perfiles.

### Tareas:
1. Crear proyecto Xcode nuevo: `CIRRCULO`, SwiftUI, iOS 17+, bundle id `mx.enactus.cirrculo`
2. Crear estructura de carpetas:
   ```
   CIRRCULO/
   ├── App/
   ├── Models/
   ├── ViewModels/
   ├── Views/
   │   ├── Onboarding/
   │   ├── Ciudadano/
   │   ├── Pepenador/
   │   ├── Empresa/
   │   ├── PuntoAcopio/
   │   └── CentroAcopio/
   ├── Services/
   │   ├── ClassifierService.swift
   │   ├── LocationService.swift
   │   └── MockDataService.swift
   ├── Resources/
   │   └── MLModels/
   └── Utils/
   ```
3. Crear `ProfileSelectorView`: pantalla inicial con 5 botones de perfil. Al seleccionar uno, navega al TabView correspondiente. Para el hackathon, esta selección es suficiente como "autenticación".
4. Agregar permisos en `Info.plist`:
   - `NSCameraUsageDescription`
   - `NSLocationWhenInUseUsageDescription`
   - `NSPhotoLibraryUsageDescription`
5. Crear `MockDataService.swift` con datos de prueba: 5 puntos de acopio en CDMX con coordenadas reales, 3 solicitudes de recolección activas, historial de depósitos del ciudadano, registros de empresa.

---

## FASE 1 — Motor de clasificación (Core ML + Vision)
**Objetivo:** Scanner funcionando que identifica residuos en tiempo real con la cámara.

> Este es el módulo más importante de la app. Se construye primero porque es compartido entre el perfil ciudadano y el perfil empresa.

### Tareas:

#### 1.1 Obtener el modelo Core ML
Buscar y descargar un modelo pre-entrenado para clasificación de residuos. Opciones en orden de preferencia:
- Buscar en Apple Machine Learning Models (`ml-models.apple.com`) un modelo de clasificación de imágenes compatible
- Buscar en Hugging Face un modelo entrenado en TrashNet o TACO dataset y convertirlo con `coremltools` a formato `.mlmodel`
- Como fallback para el hackathon: usar `VNClassifyImageRequest` de Vision y mapear las categorías más cercanas a tipos de residuo

El modelo debe clasificar al menos: PET, HDPE, cartón, papel, vidrio, aluminio, orgánico, no reciclable.

#### 1.2 Crear `ClassifierService.swift`
```swift
// Responsabilidades:
// - Cargar el modelo .mlmodel al inicio
// - Recibir CVPixelBuffer de la cámara
// - Ejecutar VNCoreMLRequest
// - Retornar ResultadoClasificacion con:
//   · tipo de residuo
//   · contenedor NADF-024 correspondiente
//   · nivel de confianza (Float)
//   · próximo día de recolección en CDMX
//   · instrucciones de preparación
//   · valor de mercado referencial (MXN/kg)
// - Si confianza < 0.70: retornar estado "ambiguo" con dos opciones
```

#### 1.3 Crear `CameraService.swift`
```swift
// Responsabilidades:
// - Configurar AVCaptureSession con preset .vga640x480
// - Capturar frames de la cámara trasera
// - Emitir CVPixelBuffer via Combine/AsyncStream
// - Manejar permisos de cámara
```

#### 1.4 Crear `ScannerView.swift`
Pantalla principal del ciudadano. Debe tener:
- Preview de cámara en tiempo real (cubre 60% de la pantalla)
- Overlay con bounding box animado alrededor del objeto detectado
- Panel inferior con resultado: color del contenedor (verde/gris/naranja), nombre del material, próximo día de recolección
- Indicador de confianza visual (no numérico, solo el color del panel cambia: verde = alta confianza, amarillo = media)
- Si confianza < 0.70: mostrar dos botones con las dos opciones más probables para que el usuario corrija
- Botón "Guardar escaneo" que agrega el resultado al ticket de depósito actual
- El fondo del panel inferior debe coincidir con el color del contenedor (verde, gris, naranja)

#### 1.5 Lógica de clasificación → NADF-024
```swift
// Mapping obligatorio:
// orgánico → contenedor Verde → Martes, Jueves, Sábado
// PET, HDPE, cartón, papel, vidrio, aluminio, lata, tetraPak → contenedor Gris → Lunes, Miércoles, Viernes, Domingo
// noReciclable, unicel contaminado → contenedor Naranja → Lunes, Miércoles, Viernes, Domingo
// El día mostrado debe calcularse dinámicamente desde la fecha actual
```


---

## FASE 1B — Foundation Models (Apple Intelligence on-device LLM)
**Objetivo:** Integrar el LLM on-device de Apple en tres puntos clave de la app para eliminar fricción cognitiva con lenguaje natural.

> Esta fase se construye en paralelo o justo después de la Fase 1. Es el segundo módulo de IA y completa el argumento de "on-device AI" ante los jueces.

### ¿Dónde y por qué usar Foundation Models?

Foundation Models no reemplaza a Core ML, lo complementa. Core ML hace la visión computacional (identificar qué objeto es). Foundation Models hace el razonamiento en lenguaje natural (explicar qué hacer con ese objeto, responder preguntas, generar resúmenes). Los dos juntos demuestran un uso maduro y justificado de on-device AI.

### Tarea 1B.1 — `FoundationModelsService.swift`

Servicio singleton que encapsula toda la interacción con el LLM on-device:

```swift
import FoundationModels

actor FoundationModelsService {

    static let shared = FoundationModelsService()
    private var session: LanguageModelSession?

    private let systemPrompt = """
    Eres el asistente de CIRRCULO, app de economía circular en México.
    Ayuda con dudas sobre reciclaje y la norma NADF-024 de la Ciudad de México.
    Responde siempre en español, de forma concisa (máximo 3 oraciones).
    NADF-024: Verde=orgánicos(Mar,Jue,Sáb), Gris=reciclables(Lun,Mié,Vie,Dom),
    Naranja=no reciclables(Lun,Mié,Vie,Dom).
    """

    func iniciarSesion() async throws {
        session = LanguageModelSession(instructions: systemPrompt)
    }

    func pregunta(_ texto: String) async throws -> String {
        guard let session else { throw NSError(domain: "FM", code: 0) }
        let respuesta = try await session.respond(to: texto)
        return respuesta.content
    }

    func instruccionesParaMaterial(_ resultado: ResultadoClasificacion) async throws -> String {
        let prompt = """
        El usuario escaneó: \(resultado.tipo.rawValue) → contenedor \(resultado.contenedor.rawValue).
        Da una instrucción breve y práctica de cómo preparar este material antes de depositarlo.
        """
        return try await pregunta(prompt)
    }

    func resolverAmbiguedad(opcion1: TipoResiduo, opcion2: TipoResiduo) async throws -> String {
        let prompt = "¿Cómo distingo visualmente \(opcion1.rawValue) de \(opcion2.rawValue)? Una oración."
        return try await pregunta(prompt)
    }

    func resumenEjecutivoEmpresa(_ registro: RegistroEmpresa) async throws -> String {
        let prompt = """
        Empresa registró este mes: \(String(format: "%.1f", registro.kgTotalesMes)) kg de residuos,
        \(registro.residuosRegistrados.count) registros documentados,
        ahorro fiscal estimado: $\(String(format: "%.0f", registro.ahorroFiscalEstimado)) MXN.
        Genera un párrafo ejecutivo de 2 oraciones para presentar ante auditor de SEDEMA,
        destacando cumplimiento de LGPGIR.
        """
        return try await pregunta(prompt)
    }
}
```

### Tarea 1B.2 — `AsistenteView.swift` (perfil Ciudadano)

Pantalla de chat conversacional en el tab del ciudadano:
- Interfaz tipo mensajes: burbujas de usuario (derecha, verde) y asistente (izquierda, gris)
- Campo de texto con botón enviar
- Respuestas via `FoundationModelsService.shared.pregunta()`
- Sugerencias rápidas al abrir (botones que pre-llenan la pregunta):
  - "¿Cómo limpio una botella antes de reciclarla?"
  - "¿El tetra pak va en gris o naranja?"
  - "¿Qué hago con pilas usadas?"
  - "¿Puedo reciclar ropa?"
- Indicador "Escribiendo..." mientras el LLM genera respuesta
- Texto fijo al pie: "Procesado en tu dispositivo · Sin conexión a internet"
- Tab icon: SF Symbol `sparkles` con badge "IA"

### Tarea 1B.3 — Instrucciones dinámicas en `ScannerView`

Cuando confianza > 0.70, mostrar instrucciones generadas por el LLM debajo del resultado:

```swift
.task(id: resultado?.tipo) {
    guard let resultado, resultado.confianza > 0.70 else { return }
    instruccionesDinamicas = try? await FoundationModelsService.shared
        .instruccionesParaMaterial(resultado)
}
// Fallback si Foundation Models no disponible: instrucciones del diccionario hardcodeado
```

### Tarea 1B.4 — Resolución de ambigüedad con pista del LLM

Cuando confianza < 0.70, el LLM genera una pista visual para ayudar al usuario a decidir:

```swift
// Ejemplo de output del LLM:
// "El PET suena hueco al golpearlo; el HDPE es más rígido y opaco."
// Se muestra encima de los dos botones de selección manual
```

### Tarea 1B.5 — `ResumenLegalView.swift` (perfil Empresa)

Nueva pantalla en el perfil empresa:
- Botón "Generar resumen para auditoría"
- Llama a `resumenEjecutivoEmpresa()` con datos del dashboard
- Muestra el texto generado con opción de copiar al portapapeles
- Nota visible: "Generado con Apple Intelligence · Todo el procesamiento ocurre en este dispositivo"
- Refuerza privacidad: los datos de la empresa nunca salen del iPhone

### Fallback obligatorio

```swift
// Siempre verificar disponibilidad antes de usar Foundation Models:
guard LanguageModelSession.isAvailable else {
    // usar respuestas hardcodeadas — el flujo debe funcionar igual
    return instruccionesHardcodeadas[resultado.tipo] ?? ""
}
```


---

## FASE 2 — Perfil Ciudadano completo
**Objetivo:** Flujo completo del ciudadano: escanear → acumular → ir al punto → verificar → ganar puntos.

### Tareas:

#### 2.1 `DepositView.swift` — Generar ticket y verificar depósito
Esta pantalla tiene dos modos:

**Modo 1 — Generar ticket (en casa):**
- Lista de materiales escaneados en la sesión actual con kg estimados
- Total de puntos que se ganarán al depositar
- Botón "Ir a depositar" que abre el mapa con puntos de acopio cercanos

**Modo 2 — Verificar depósito (en el punto de acopio):**
- Instrucciones: "Escanea el QR del local"
- Lector de QR usando `AVCaptureMetadataOutput`
- Al detectar QR válido de un punto de acopio: abrir cámara para foto del material
- La IA analiza la foto y detecta que hay material reciclable presente (reutiliza `ClassifierService`)
- Si la IA confirma material → marcar ticket como verificado → otorgar puntos → animación de celebración
- Si la IA no detecta material → mensaje de error → reintentar

#### 2.2 `MapaAcopioView.swift`
- Mapa con `MapKit` centrado en ubicación actual del usuario
- Anotaciones personalizadas para cada punto de acopio: círculo con color según capacidad disponible (verde = espacio, amarillo = medio lleno, rojo = lleno)
- Al tocar un punto: sheet con nombre, dirección, materiales aceptados, capacidad disponible
- Botón "Cómo llegar" que abre Apple Maps con la dirección

#### 2.3 `PerfilCiudadanoView.swift`
- Puntos acumulados (número grande, visual)
- Equivalencia de impacto: "Has reciclado X kg = Y kg de CO₂ evitados"
- Racha de días activos (gamificación)
- Historial de últimos depósitos con fecha, punto y puntos ganados
- Sección de cupones disponibles (datos mockeados: 10% de descuento en Farmacia, café gratis, etc.)

---

## FASE 3 — Perfil Pepenador
**Objetivo:** Mapa con solicitudes disponibles, sistema de claim, confirmación de entrega.

### Tareas:

#### 3.1 `MapaRutasView.swift`
- Mapa como pantalla principal del pepenador
- Anotaciones para cada solicitud de recolección disponible
- Cada anotación muestra: icono de tipo de material principal + kg estimados + valor estimado en MXN
- Al tocar una anotación: `DetallePuntoView` como sheet
- Anotaciones en gris si ya están reclamadas por otro pepenador

#### 3.2 `DetallePuntoView.swift`
- Nombre y dirección del punto de acopio
- Desglose de materiales disponibles con kg y valor por material (usar precios del MockDataService: aluminio $22/kg, PET $8.50/kg, cartón $0.70/kg, etc.)
- Total estimado de ingresos para el pepenador
- Botón "Reclamar recolección" — al presionar, el punto se marca como reclamado y desaparece del mapa de otros pepenadores
- Botón "Cómo llegar" con ruta en MapKit

#### 3.3 `EntregaView.swift`
- Checklist del material recogido del punto de acopio
- Campo para ingresar kg reales recogidos por material
- Sección "Entregar en centro de acopio"
- Lista de centros de acopio cercanos con sus precios actuales (datos mockeados)
- Botón "Confirmar entrega" — genera el registro de trazabilidad que cierra el ciclo
- Pantalla de confirmación con: ingresos del viaje, kg entregados, centro de acopio destino

#### 3.4 `HistorialPepenadorView.swift`
- Lista de recolecciones completadas con fecha, punto de origen, kg y ganancia
- Total acumulado del mes
- Indicador de "viajes realizados este mes" (construcción de historial formal)

---

## FASE 4 — Perfil Empresa
**Objetivo:** Dashboard de trazabilidad con calculadora fiscal y escáner corporativo.

### Tareas:

#### 4.1 `DashboardEmpresaView.swift`
Pantalla principal. Debe mostrar:
- Métricas del mes: kg totales registrados, desglose por tipo de material
- Gráfica de barras simple con SwiftUI Charts: kg por semana del mes actual
- Cadena de custodia: número de registros con destino documentado
- Card de ahorro fiscal estimado (cálculo en tiempo real)
- Indicador de cumplimiento NADF-024: porcentaje de residuos correctamente clasificados

#### 4.2 `ScannerEmpresaView.swift`
- Reutilizar `ClassifierService` de la Fase 1 completamente
- La diferencia con el scanner del ciudadano: cada escaneo se registra automáticamente en el dashboard de la empresa con: tipo de material, kg estimados, empleado que escaneó, timestamp
- Sin ticket de depósito ni QR de punto de acopio — el registro es directo

#### 4.3 `AhorroFiscalView.swift`
Calculadora interactiva:
- Input: kg de residuos totales generados en el mes
- Input: porcentaje que fue a reciclaje (calculado automáticamente de los registros)
- Output: reducción de impuesto sobre nómina aplicable (20%, 30% o 40% según NADF-024)
- Texto explicativo: "Presentando este reporte ante SEDEMA puedes obtener X% de reducción en nómina"
- Botón "Exportar reporte PDF" (puede ser una pantalla con el resumen, no necesita exportar realmente para el hackathon)

#### 4.4 `EquipoView.swift`
- Lista de empleados registrados (datos mockeados)
- Por cada empleado: número de escaneos del mes y kg registrados
- Botón "Agregar empleado" (modal con nombre, puede ser solo UI sin lógica real)

---

## FASE 5 — Perfiles de referencia
**Objetivo:** Pantallas funcionales pero sin flujo profundo para punto de acopio y centro de acopio.

### Tareas:

#### 5.1 `QREstaticoView.swift` (Punto de Acopio)
- Genera y muestra un QR grande con el identificador único del punto de acopio
- Este QR es el que se imprime/muestra en la pared del local
- Instrucciones: "Imprime este código y pégalo en tu contenedor de reciclaje"
- Botón de compartir con `ShareLink`

#### 5.2 `PanelContenedoresView.swift` (Punto de Acopio)
- Tres barras de progreso: Verde, Gris, Naranja con % de capacidad
- Lista de depósitos recibidos hoy (datos mockeados)
- Botón "Solicitar recolección" cuando algún contenedor pase del 70%

#### 5.3 `PreciosMaterialView.swift` (Centro de Acopio)
- Tabla editable de precios por material (datos mockeados con precios reales de mercado)
- Lista de recepciones pendientes de confirmar
- Botón "Confirmar recepción" con kg y monto

---

## FASE 6 — Polish y preparación demo
**Objetivo:** App lista para presentar. Datos mockeados robustos, sin crashes, flujo de demo ensayado.

### Tareas:

#### 6.1 MockDataService robusto
Asegurarse de que todos los datos mockeados sean realistas:
- 5 puntos de acopio en colonias reales de CDMX con coordenadas correctas
- 3 solicitudes de recolección activas con materiales y valores reales
- Historial del ciudadano con 8 depósitos en los últimos 30 días
- Dashboard de empresa con datos de un mes completo
- Precios de materiales actualizados (aluminio $22, PET $8.50, cobre $130, cartón $0.70, vidrio $0.30)

#### 6.2 Diseño visual consistente
- Color primario: verde oscuro `#1B5E20`
- Color secundario: verde medio `#388E3C`
- Colores de contenedor: verde `#4CAF50`, gris `#607D8B`, naranja `#FF5722`
- Tipografía: SF Pro (default iOS)
- Íconos: SF Symbols exclusivamente
- Cada perfil tiene su color de acento distintivo: ciudadano (verde), pepenador (ámbar), empresa (azul)

#### 6.3 Flujo de demo (3 flujos para presentar en 10 minutos)

**Demo 1 — Ciudadano (3 min):**
Selector de perfil → Scanner apunta a una botella PET → clasificación instantánea con color gris + "Lunes próximo" → guardar escaneo → ver ticket → mapa con puntos cercanos → llegar a punto de acopio → escanear QR → foto del material → IA confirma → puntos aparecen → ver impacto

**Demo 2 — Pepenador (3 min):**
Selector → mapa con 3 puntos disponibles → tocar el más cercano → ver materiales y valor estimado → reclamar → ruta en MapKit → marcar llegada → ingresar kg reales → confirmar entrega al centro de acopio → ver ingreso del viaje

**Demo 3 — Empresa (3 min):**
Selector → dashboard con métricas del mes → abrir scanner corporativo → escanear 3 objetos → ver cómo las métricas se actualizan → ir a ahorro fiscal → calculadora muestra 30% de reducción de nómina → ver reporte

#### 6.4 Checklist pre-entrega
- [ ] App compila sin warnings en Xcode
- [ ] Todos los flujos de demo corren sin crashes
- [ ] Scanner funciona en dispositivo real o simulador con cámara simulada
- [ ] Permisos de cámara y ubicación correctamente configurados
- [ ] No hay texto hardcodeado en inglés visible en la UI
- [ ] MockDataService tiene datos suficientes para 10 minutos de demo
- [ ] Presentación en Keynote incluye lista de frameworks utilizados

---

## Notas técnicas importantes

### Sobre el modelo Core ML
Si no se encuentra un modelo pre-entrenado adecuado, usar este fallback para el hackathon:
```swift
// Usar VNClassifyImageRequest con Vision y mapear los 
// identificadores de ImageNet más cercanos a categorías de residuos:
// "plastic_bag", "bottle" → PET
// "cardboard" → Cartón  
// "tin_can", "beer_can" → Aluminio
// "wine_glass", "jar" → Vidrio
// "banana_peel", "apple_core" → Orgánico
// El mapping puede ser una simple función switch en ClassifierService
```

### Sobre el QR del punto de acopio
```swift
// Generar QR con Core Image:
import CoreImage.CIFilterBuiltins
let filter = CIFilter.qrCodeGenerator()
filter.message = Data("CIRRCULO-PUNTO-\(puntoId)".utf8)
let qrImage = filter.outputImage
// El lector de QR del ciudadano valida que el prefijo sea "CIRRCULO-PUNTO-"
```

### Sobre el cálculo del próximo día de recolección
```swift
// Contenedor Verde: recolección Martes(3), Jueves(5), Sábado(7)
// Contenedor Gris/Naranja: recolección Lunes(2), Miércoles(4), Viernes(6), Domingo(1)
// Calcular días desde Calendar.current hasta el próximo día válido
// Mostrar como: "Hoy", "Mañana", "En 2 días (Miércoles)"
```

### Sobre el sistema de puntos
```swift
// Puntos por kg por material (referencia):
// Aluminio: 50 pts/kg (valor alto)
// PET: 20 pts/kg
// Cartón: 10 pts/kg
// Vidrio: 5 pts/kg
// Orgánico: 15 pts/kg
// No reciclable: 0 pts (pero se registra en NADF-024)
// 100 puntos = $1 MXN en valor de cupón
```

---

## Restricciones del hackathon

- Todo el código debe estar en Swift
- No usar Vision Pro ni CreateML en runtime
- Entregar en repositorio iCloud asignado
- La demo debe correr en simulador Xcode o dispositivo iPhone/iPad real
- La presentación debe ser en Keynote e incluir lista de tecnologías utilizadas
- Hora límite de entrega: definida en el evento (no entregar tarde o hay descalificación)
