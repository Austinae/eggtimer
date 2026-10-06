import AppKit
import SwiftUI

@main
struct EggTimerApp: App {
    init() {
        AppFont.register()
        SoundEffects.preload()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 120, height: 182)
    }
}

private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        TransparentWindowView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? TransparentWindowView)?.configureWindow()
    }
}

private final class TransparentWindowView: NSView {
    private nonisolated(unsafe) var spaceObserver: NSObjectProtocol?

    deinit {
        if let spaceObserver {
            NotificationCenter.default.removeObserver(spaceObserver)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.configureWindow()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    func configureWindow() {
        guard let window else { return }

        window.styleMask = [.borderless, .fullSizeContentView, .closable]
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.setContentSize(NSSize(width: 120, height: 182))
        window.orderFrontRegardless()

        if spaceObserver == nil {
            spaceObserver = NotificationCenter.default.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: NSWorkspace.shared,
                queue: .main
            ) { [weak window] _ in
                Task { @MainActor in
                    window?.orderFrontRegardless()
                }
            }
        }
    }
}
