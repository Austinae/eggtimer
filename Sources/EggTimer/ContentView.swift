import AppKit
import SwiftUI

private enum EggAsset {
    static let image: NSImage? = {
        guard let url = Bundle.module.url(forResource: "egg", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}

struct ContentView: View {
    @State private var durationIndex = 3
    @State private var secondsRemaining = TimerDurationOption.all[3].seconds
    @State private var isRunning = false
    @State private var isDone = false
    @State private var showChrome = false

    private let eggHeight: CGFloat = 114
    private let idleControlsHeight: CGFloat = 152
    private let activeControlsHeight: CGFloat = 40
    private let windowWidth: CGFloat = 160

    private var controlsHeight: CGFloat {
        isSessionActive ? activeControlsHeight : idleControlsHeight
    }

    private var windowHeight: CGFloat {
        eggHeight + controlsHeight
    }
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let resetAnimation = Animation.timingCurve(0.33, 1, 0.68, 1, duration: 0.85)
    private let tickAnimation = Animation.timingCurve(0.33, 1, 0.68, 1, duration: 1.0)

    private var durationSeconds: Int {
        TimerDurationOption.all[durationIndex].seconds
    }

    private var timeLeftFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return Double(secondsRemaining) / Double(durationSeconds)
    }

    private var isSessionActive: Bool {
        !isDone && (isRunning || secondsRemaining < durationSeconds)
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

            VStack(spacing: 8) {
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
                    DurationSlider(selectedIndex: $durationIndex)

                    Button("Start", action: startTimer)
                        .buttonStyle(EggPillButtonStyle())
                }
            }
            .eggControlPanel()
            .opacity(showChrome ? 1 : 0)
            .allowsHitTesting(showChrome)
            .frame(height: controlsHeight, alignment: .top)
        }
        .frame(width: windowWidth, height: windowHeight, alignment: .top)
        .preference(
            key: WindowSizePreferenceKey.self,
            value: CGSize(width: windowWidth, height: windowHeight)
        )
        .background(Color.clear)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: showChrome)
        .onHover { hovering in
            showChrome = hovering
        }
        .onChange(of: durationIndex) { _, newIndex in
            guard !isRunning, !isDone else { return }
            secondsRemaining = TimerDurationOption.all[newIndex].seconds
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
                secondsRemaining = durationSeconds
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
                secondsRemaining = durationSeconds
                isDone = false
            }
            isRunning = true
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            secondsRemaining = durationSeconds
            isDone = false
        }
        isRunning = true
    }

    private func stopTimer() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            secondsRemaining = durationSeconds
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
