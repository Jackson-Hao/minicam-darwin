import Foundation
import AVFoundation
import AppKit
import Combine
import Dispatch

enum CameraResolution: String, CaseIterable, Identifiable {
    case res4K = "4K (2160p)"
    case res1080p = "1080p (FHD)"
    case res720p = "720p (HD)"
    case res480p = "480p (SD)"
    case resHigh = "Auto (High)"

    var id: String { rawValue }

    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .res4K:
            return .hd4K3840x2160
        case .res1080p:
            return .hd1920x1080
        case .res720p:
            return .hd1280x720
        case .res480p:
            return .vga640x480
        case .resHigh:
            return .high
        }
    }
}

enum CaptureMode: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case video = "Video"
    
    var id: String { rawValue }
}

final class CameraController: NSObject, ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var availableVideoDevices: [AVCaptureDevice] = []
    @Published var availableAudioDevices: [AVCaptureDevice] = []
    @Published var selectedVideoDevice: AVCaptureDevice?
    @Published var selectedAudioDevice: AVCaptureDevice?
    
    @Published var selectedResolution: CameraResolution = .res1080p
    @Published var captureMode: CaptureMode = .photo
    @Published var isMirrored: Bool = false
    
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var isShutterFlashing: Bool = false
    @Published var errorMessage: String?
    
    let session = AVCaptureSession()
    
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private var recordingTimer: Timer?
    private let sessionQueue = DispatchQueue(label: "com.minicam.sessionQueue")
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = true
                self?.refreshDevices()
                self?.setupSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.refreshDevices()
                        self?.setupSession()
                    } else {
                        self?.errorMessage = "Camera access denied. Please grant permission in System Settings."
                    }
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
                self?.errorMessage = "Camera access restricted or denied. Please grant permission in System Settings."
            }
        }
        
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
    }
    
    func refreshDevices() {
        let videoDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        self.availableVideoDevices = videoDiscovery.devices
        
        let audioDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        self.availableAudioDevices = audioDiscovery.devices
        
        if selectedVideoDevice == nil || !availableVideoDevices.contains(where: { $0.uniqueID == self.selectedVideoDevice?.uniqueID }) {
            selectedVideoDevice = availableVideoDevices.first
        }
        if selectedAudioDevice == nil || !availableAudioDevices.contains(where: { $0.uniqueID == self.selectedAudioDevice?.uniqueID }) {
            selectedAudioDevice = availableAudioDevices.first
        }
    }
    
    private func runOnSessionQueue(_ action: @escaping @Sendable () -> Void) {
        sessionQueue.async(execute: DispatchWorkItem(block: action))
    }
    
    private func setupSession() {
        let videoDev = self.selectedVideoDevice
        let audioDev = self.selectedAudioDevice
        let preset = self.selectedResolution.sessionPreset
        
        runOnSessionQueue {
            self.session.beginConfiguration()
            self.applyPreset(preset)
            
            // Video input
            if let videoDevice = videoDev,
               let input = try? AVCaptureDeviceInput(device: videoDevice),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
            }
            
            // Audio input
            if let audioDevice = audioDev,
               let input = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.audioInput = input
            }
            
            // Photo Output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            // Movie Output
            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
    
    private func applyPreset(_ preset: AVCaptureSession.Preset) {
        if session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
        } else if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }
    }
    
    func changeResolution(_ resolution: CameraResolution) {
        selectedResolution = resolution
        let preset = resolution.sessionPreset
        runOnSessionQueue {
            self.session.beginConfiguration()
            self.applyPreset(preset)
            self.session.commitConfiguration()
        }
    }
    
    func changeVideoDevice(_ device: AVCaptureDevice) {
        selectedVideoDevice = device
        runOnSessionQueue {
            self.session.beginConfiguration()
            if let currentInput = self.videoInput {
                self.session.removeInput(currentInput)
            }
            if let newInput = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoInput = newInput
            }
            self.session.commitConfiguration()
        }
    }
    
    func changeAudioDevice(_ device: AVCaptureDevice) {
        selectedAudioDevice = device
        runOnSessionQueue {
            self.session.beginConfiguration()
            if let currentInput = self.audioInput {
                self.session.removeInput(currentInput)
            }
            if let newInput = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.audioInput = newInput
            }
            self.session.commitConfiguration()
        }
    }
    
    func toggleMirror() {
        isMirrored.toggle()
    }
    
    // MARK: - Capture Actions
    func takePhoto() {
        guard isAuthorized else { return }
        
        triggerShutterEffect()
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard isAuthorized, !movieOutput.isRecording else { return }
        
        let outputURL = MediaManager.shared.getNewMovieURL()
        
        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = isMirrored
            }
        }
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.recordingDuration = 0
            self?.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1.0
            }
        }
    }
    
    private func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
        }
    }
    
    private func triggerShutterEffect() {
        DispatchQueue.main.async { [weak self] in
            self?.isShutterFlashing = true
            NSSound(named: "Tink")?.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.isShutterFlashing = false
            }
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let photoData = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        
        var finalData = photoData
        if self.isMirrored, let image = NSImage(data: photoData), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let flippedImage = NSImage(size: image.size, flipped: false) { rect in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.translateBy(x: rect.width, y: 0)
                context.scaleBy(x: -1.0, y: 1.0)
                context.draw(cgImage, in: rect)
                return true
            }
            if let tiff = flippedImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.95]) {
                finalData = jpeg
            }
        }
        
        _ = MediaManager.shared.savePhoto(data: finalData)
    }
}

// MARK: - Video Recording Delegate
extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
            if error == nil {
                MediaManager.shared.updateLatestVideo(url: outputFileURL)
            } else {
                print("Recording error: \(String(describing: error))")
            }
        }
    }
}
