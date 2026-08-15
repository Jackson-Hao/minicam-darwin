import SwiftUI
import AVFoundation
import AppKit

struct ContentView: View {
    @StateObject private var cameraController = CameraController()
    @StateObject private var mediaManager = MediaManager.shared
    
    @State private var isHovering: Bool = false
    @State private var showSettings: Bool = false
    @State private var isAlwaysOnTop: Bool = false
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // 1. Camera Preview Layer
            if cameraController.isAuthorized {
                CameraPreviewView(cameraController: cameraController)
                    .ignoresSafeArea()
            } else {
                permissionWarningView
            }
            
            // 2. Shutter Flash Effect
            if cameraController.isShutterFlashing {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // 3. Recording Red Border Glow
            if cameraController.isRecording {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(pulseAnimation ? 0.9 : 0.4), lineWidth: 3)
                    .ignoresSafeArea()
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                    .onAppear { pulseAnimation = true }
                    .onDisappear { pulseAnimation = false }
            }
            
            // 4. Floating UI Controls Overlay
            VStack {
                topBar
                    .opacity(isHovering || showSettings || cameraController.isRecording ? 1.0 : 0.0)
                
                Spacer()
                
                // Recording duration timer in center top if recording
                if cameraController.isRecording {
                    recordingBadge
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                bottomControlBar
                    .opacity(isHovering || showSettings || cameraController.isRecording ? 1.0 : 0.0)
            }
            .padding(12)
            .animation(.easeInOut(duration: 0.22), value: isHovering)
            .animation(.easeInOut(duration: 0.22), value: cameraController.isRecording)
            
            // 5. Settings Popover / Overlay Drawer
            if showSettings {
                settingsOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(minWidth: 320, minHeight: 240)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
        .onReceive(NotificationCenter.default.publisher(for: .takePhotoShortcut)) { _ in
            cameraController.takePhoto()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleRecordingShortcut)) { _ in
            cameraController.toggleRecording()
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 8) {
            // Resolution Picker Menu
            Menu {
                Text("Camera Resolution").font(.caption).foregroundColor(.secondary)
                Divider()
                ForEach(CameraResolution.allCases) { res in
                    Button(action: {
                        cameraController.changeResolution(res)
                    }) {
                        HStack {
                            Text(res.rawValue)
                            if cameraController.selectedResolution == res {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                    Text(cameraController.selectedResolution.rawValue.components(separatedBy: " ").first ?? "HD")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .menuStyle(BorderlessButtonMenuStyle())
            
            // Mirror Toggle
            Button(action: {
                cameraController.toggleMirror()
            }) {
                Image(systemName: cameraController.isMirrored ? "arrow.left.and.right.righttriangle.left.righttriangle.right.fill" : "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(cameraController.isMirrored ? .yellow : .white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help(cameraController.isMirrored ? "Mirroring Enabled" : "Mirroring Disabled")
            
            Spacer()
            
            // Always on top toggle
            Button(action: {
                toggleAlwaysOnTop()
            }) {
                Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isAlwaysOnTop ? .orange : .white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help(isAlwaysOnTop ? "Pin Window (Always on Top Active)" : "Pin Window to Top")
            
            // Settings Toggle
            Button(action: {
                withAnimation(.spring()) {
                    showSettings.toggle()
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Camera & Audio Settings")
        }
    }
    
    // MARK: - Recording Indicator Badge
    private var recordingBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(pulseAnimation ? 1.0 : 0.2)
            Text(formattedDuration(cameraController.recordingDuration))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.75))
        .clipShape(Capsule())
    }
    
    // MARK: - Bottom Control Bar
    private var bottomControlBar: some View {
        VStack(spacing: 10) {
            // Mode Selector (Photo / Video)
            if !cameraController.isRecording {
                HStack(spacing: 12) {
                    ForEach(CaptureMode.allCases) { mode in
                        Button(action: {
                            cameraController.captureMode = mode
                        }) {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: cameraController.captureMode == mode ? .bold : .medium))
                                .foregroundColor(cameraController.captureMode == mode ? .yellow : .white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(cameraController.captureMode == mode ? Color.white.opacity(0.18) : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            // Main Shutter Area
            HStack {
                // Thumbnail / Recent Gallery Button
                Button(action: {
                    mediaManager.openInFinder(url: mediaManager.lastCapturedURL)
                }) {
                    ZStack {
                        if let img = mediaManager.lastCapturedImage {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .frame(width: 38, height: 38)
                                .overlay(Image(systemName: "photo.on.rectangle").foregroundColor(.white.opacity(0.8)))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open in Finder / Photos")
                
                Spacer()
                
                // Big Shutter Button
                Button(action: {
                    if cameraController.captureMode == .photo {
                        cameraController.takePhoto()
                    } else {
                        cameraController.toggleRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 3.5)
                            .frame(width: 58, height: 58)
                        
                        if cameraController.captureMode == .photo {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 46, height: 46)
                        } else {
                            if cameraController.isRecording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                                    .frame(width: 24, height: 24)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 46, height: 46)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                // Open Folder Button
                Button(action: {
                    mediaManager.openSaveDirectory()
                }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open MiniCam Directory")
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Settings Overlay
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showSettings = false }
                }
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("MiniCam Settings")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { withAnimation { showSettings = false } }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                
                // Camera Source
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camera Device").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { cameraController.selectedVideoDevice?.uniqueID ?? "" },
                        set: { newId in
                            if let dev = cameraController.availableVideoDevices.first(where: { $0.uniqueID == newId }) {
                                cameraController.changeVideoDevice(dev)
                            }
                        }
                    )) {
                        ForEach(cameraController.availableVideoDevices, id: \.uniqueID) { device in
                            Text(device.localizedName).tag(device.uniqueID)
                        }
                    }
                    .labelsHidden()
                }
                
                // Audio Source
                VStack(alignment: .leading, spacing: 4) {
                    Text("Microphone Device").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { cameraController.selectedAudioDevice?.uniqueID ?? "" },
                        set: { newId in
                            if let dev = cameraController.availableAudioDevices.first(where: { $0.uniqueID == newId }) {
                                cameraController.changeAudioDevice(dev)
                            }
                        }
                    )) {
                        ForEach(cameraController.availableAudioDevices, id: \.uniqueID) { device in
                            Text(device.localizedName).tag(device.uniqueID)
                        }
                    }
                    .labelsHidden()
                }
                
                // Resolution Selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capture Resolution").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { cameraController.selectedResolution },
                        set: { newRes in cameraController.changeResolution(newRes) }
                    )) {
                        ForEach(CameraResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .labelsHidden()
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 280)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Permission Warning View
    private var permissionWarningView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Camera Permission Required")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(cameraController.errorMessage ?? "Please grant camera and microphone access to use MiniCam.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
    }
    
    private func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        if let window = NSApplication.shared.windows.first {
            window.level = isAlwaysOnTop ? .floating : .normal
        }
    }
    
    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
