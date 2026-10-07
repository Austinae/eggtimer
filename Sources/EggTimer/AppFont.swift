import AppKit
import CoreText
import SwiftUI

enum AppFont {
    static let playfulName = "TropicalAsianDEMO-Regular"

    static func register() {
        guard let url = Bundle.module.url(forResource: "playful", withExtension: "ttf") else {
            return
        }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }

    static func playful(size: CGFloat) -> Font {
        .custom(playfulName, size: size)
    }
}

enum EggTheme {
    static let brown = Color(red: 0.45, green: 0.30, blue: 0.18)
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let yolk = Color(red: 0.92, green: 0.62, blue: 0.18)
}

struct EggPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.playful(size: 24))
            .foregroundStyle(EggTheme.brown)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .background(EggTheme.cream.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(EggTheme.yolk.opacity(0.45), lineWidth: 1)
            }
    }
}

extension View {
    func eggControlPanel() -> some View {
        font(AppFont.playful(size: 14))
            .foregroundStyle(EggTheme.brown)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(EggTheme.cream.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(EggTheme.yolk.opacity(0.35), lineWidth: 1)
            }
            .background(WindowDragBlocker())
    }
}

struct WindowDragBlocker: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NonDraggableView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class NonDraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
}
