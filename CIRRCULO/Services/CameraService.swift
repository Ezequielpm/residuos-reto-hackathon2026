import AVFoundation
import Combine
import UIKit

final class CameraService: NSObject, ObservableObject {

    @Published var pixelBuffer: CVPixelBuffer?
    @Published var error: String?
    @Published var permisoConcedido = false

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "mx.enactus.cirrculo.camera", qos: .userInteractive)
    private let output = AVCaptureVideoDataOutput()

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
            self.session.sessionPreset = .vga640x480

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
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.pixelBuffer = buffer
        }
    }
}
