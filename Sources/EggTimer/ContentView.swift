import AppKit
import SwiftUI

enum TimerDuration: Int, CaseIterable, Identifiable {
    case ten = 10
    case fifteen = 900
    case thirty = 1800
    case sixty = 3600

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .ten: "10s (test)"
        case .fifteen: "15m"
        case .thirty: "30m"
        case .sixty: "1h"
        }
    }
}

private enum EggAsset {
    static let image: NSImage? = {
        guard let url = Bundle.module.url(forResource: "egg", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}

struct ContentView: View {
    @State private var duration: TimerDuration = .thirty
    @State private var secondsRemaining = TimerDuration.thirty.rawValue
    @State private var isRunning = false
    @State private var isDone = false
    @State private var showChrome = false

    private let eggHeight: CGFloat = 114
    private let controlsHeight: CGFloat = 68
    private let windowWidth: CGFloat = 120
    private let windowHeight: CGFloat = 114 + 68
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let resetAnimation = Animation.timingCurve(0.33, 1, 0.68, 1, duration: 0.85)
    private let tickAnimation = Animation.timingCurve(0.33, 1, 0.68, 1, duration: 1.0)
    private var timeLeftFraction: Double {
        guard duration.rawValue > 0 else { return 0 }
        return Double(secondsRemaining) / Double(duration.rawValue)
    }

    private var isSessionActive: Bool {
        !isDone && (isRunning || secondsRemaining < duration.rawValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    EggProgressView(timeLeftFraction: timeLeftFraction)
                        .frame(width: 88, height: eggHeight)

                    if isDone {
                        Text("Done")
                            .font(AppFont.playful(size: 15))
                            .foregroundStyle(EggTheme.brown)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(EggTheme.cream.opacity(0.95), in: Capsule())
                            .overlay {
                                Capsule().stroke(EggTheme.yolk.opacity(0.45), lineWidth: 1)
                            }
                    }
                }

                Button(action: closeApp) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                }
                .buttonStyle(.plain)
                .padding(2)
                .opacity(showChrome ? 1 : 0)
                .allowsHitTesting(showChrome)
            }
            .frame(height: eggHeight)

            VStack(spacing: 6) {
                if isSessionActive {
                    HStack(spacing: 12) {
                        if isRunning {
                            Button(action: pauseTimer) {
                                Image(systemName: "pause.fill")
                            }
                            .accessibilityLabel("Pause")
                        } else {
                            Button(action: resumeTimer) {
                                Image(systemName: "play.fill")
                            }
                            .accessibilityLabel("Continue")
                        }

                        Button(action: restartTimer) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Restart")

                        Button(action: stopTimer) {
                            Image(systemName: "stop.fill")
                        }
                        .accessibilityLabel("Stop")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(EggTheme.brown)
                    .font(.system(size: 11, weight: .semibold))
                } else {
                    Button("Start", action: startTimer)
                        .buttonStyle(EggPillButtonStyle())

                    Picker("Duration", selection: $duration) {
                        ForEach(TimerDuration.allCases) { option in
                            Text(option.label)
                                .font(AppFont.playful(size: 14))
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(EggTheme.brown)
                }
            }
            .eggControlPanel()
            .opacity(showChrome ? 1 : 0)
            .allowsHitTesting(showChrome)
            .frame(height: controlsHeight)
        }
        .frame(width: windowWidth, height: windowHeight, alignment: .top)
        .background(Color.clear)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: showChrome)
        .onHover { hovering in
            showChrome = hovering
        }
        .onChange(of: duration) { _, newDuration in
            guard !isRunning, !isDone else { return }
            secondsRemaining = newDuration.rawValue
        }
        .onReceive(timer) { _ in
            guard isRunning, secondsRemaining > 0 else { return }

            withAnimation(tickAnimation) {
                secondsRemaining -= 1
                if secondsRemaining == 0 {
                    isRunning = false
                    isDone = true
                }
            }

            if secondsRemaining == 0 {
                SoundEffects.playEnd()
            }
        }
    }

    private func pauseTimer() {
        SoundEffects.playStartStop()
        isRunning = false
    }

    private func resumeTimer() {
        SoundEffects.playStartStop()
        isRunning = true
    }

    private func startTimer() {
        SoundEffects.playStartStop()

        if isDone || secondsRemaining == 0 {
            withAnimation(resetAnimation) {
                secondsRemaining = duration.rawValue
                isDone = false
            }
            isRunning = true
            return
        }

        isRunning = true
    }

    private func restartTimer() {
        if isDone || secondsRemaining == 0 {
            withAnimation(resetAnimation) {
                secondsRemaining = duration.rawValue
                isDone = false
            }
            isRunning = true
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            secondsRemaining = duration.rawValue
            isDone = false
        }
        isRunning = true
    }

    private func stopTimer() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            secondsRemaining = duration.rawValue
            isRunning = false
            isDone = false
        }
    }

    private func closeApp() {
        NSApp.windows.forEach { $0.orderOut(nil) }
        NSApp.terminate(nil)
    }
}

private struct EggProgressView: View {
    let timeLeftFraction: Double

    var body: some View {
        eggImage
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    let overlayHeight = geo.size.height * (1 - timeLeftFraction)
                    Rectangle()
                        .fill(Color.white.opacity(0.88))
                        .frame(height: overlayHeight, alignment: .top)
                }
            }
            .mask(eggImage)
            .frame(width: 88, height: 114)
    }

    @ViewBuilder
    private var eggImage: some View {
        if let egg = EggAsset.image {
            Image(nsImage: egg)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "oval.fill")
                .resizable()
                .aspectRatio(0.78, contentMode: .fit)
                .foregroundStyle(.orange.opacity(0.7))
        }
    }
}
