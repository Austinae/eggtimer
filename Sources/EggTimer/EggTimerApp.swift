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
            WindowRoot {
                ContentView()
                    .onAppear {
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 160, height: 266)
    }
}

struct WindowSizePreferenceKey: PreferenceKey {
    static let defaultValue = CGSize(width: 160, height: 266)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct WindowRoot<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var contentSize = WindowSizePreferenceKey.defaultValue

    var body: some View {
        content()
            .onPreferenceChange(WindowSizePreferenceKey.self) { contentSize = $0 }
            .background(WindowAccessor(size: contentSize))
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView {
        TransparentWindowView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? TransparentWindowView)?.configureWindow(size: size)
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

    func configureWindow(size: CGSize = WindowSizePreferenceKey.defaultValue) {
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

        let targetSize = NSSize(width: size.width, height: size.height)
        if window.frame.size != targetSize {
            window.setContentSize(targetSize)
        }

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
