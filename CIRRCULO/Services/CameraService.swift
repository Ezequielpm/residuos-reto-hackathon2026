import AVFoundation
import Combine
import UIKit
import CoreImage

final class CameraService: NSObject, ObservableObject {

    /// CGImage listo para clasificar (convertido síncronamente en el thread de cámara)
    var currentFrame: CGImage?
    /// Counter que se incrementa con cada frame — usar con onChange para detectar nuevos frames
    @Published var frameCount: Int = 0
    @Published var error: String?
    @Published var permisoConcedido = false

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "mx.enactus.cirrculo.camera", qos: .userInteractive)
    private let output = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()

    var captureSession: AVCaptureSession { session }

    // MARK: - Setup

    func solicitarPermiso() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            await MainActor.run { permisoConcedido = true }
            configurar()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run { permisoConcedido = granted }
            if granted { configurar() }
        default:
            await MainActor.run {
                error = "Permiso de cámara denegado. Ve a Configuración > Privacidad > Cámara."
            }
        }
    }

    private func configurar() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let dispositivo = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: dispositivo),
                  self.session.canAddInput(input) else {
                DispatchQueue.main.async { self.error = "No se pudo acceder a la cámara." }
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)

            self.output.setSampleBufferDelegate(self, queue: self.queue)
            self.output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            if let conn = self.output.connection(with: .video),
               conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func detener() {
        queue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Convertir a CGImage AQUÍ, síncronamente, ANTES de que el buffer se recicle
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = cgImage
            self?.frameCount += 1
        }
    }
}
