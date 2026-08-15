import SwiftUI
import AppKit

@main
struct MiniCamApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 280, minHeight: 210)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Camera") {
                Button("Take Photo") {
                    NotificationCenter.default.post(name: .takePhotoShortcut, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
                
                Button("Toggle Recording") {
                    NotificationCenter.default.post(name: .toggleRecordingShortcut, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let takePhotoShortcut = Notification.Name("takePhotoShortcut")
    static let toggleRecordingShortcut = Notification.Name("toggleRecordingShortcut")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.title = "MiniCam"
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.backgroundColor = .black
                window.isOpaque = false
                window.hasShadow = true
                window.setContentSize(NSSize(width: 440, height: 330))
                window.center()
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
