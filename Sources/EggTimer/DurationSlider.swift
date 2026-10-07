import AppKit
import SwiftUI

struct TimerDurationOption: Identifiable {
    let id: Int
    let seconds: Int
    let label: String
    let tickLabel: String

    static let all: [TimerDurationOption] = [
        TimerDurationOption(id: 0, seconds: 300, label: "5m", tickLabel: "5"),
        TimerDurationOption(id: 1, seconds: 600, label: "10m", tickLabel: "10"),
        TimerDurationOption(id: 2, seconds: 900, label: "15m", tickLabel: "15"),
        TimerDurationOption(id: 3, seconds: 1800, label: "30m", tickLabel: "30"),
        TimerDurationOption(id: 4, seconds: 2700, label: "45m", tickLabel: "45"),
        TimerDurationOption(id: 5, seconds: 3600, label: "1h", tickLabel: "1h"),
        TimerDurationOption(id: 6, seconds: 7200, label: "2h", tickLabel: "2h"),
    ]
}

struct DurationSlider: View {
    @Binding var selectedIndex: Int
    @State private var dragThumbPoint: CGPoint?

    private let options = TimerDurationOption.all
    private let lightYellow = Color(red: 0.94, green: 0.90, blue: 0.76)
    private let darkYellow = Color(red: 0.70, green: 0.56, blue: 0.26)

    var body: some View {
        VStack(spacing: 4) {
            Text(options[selectedIndex].label)
                .font(AppFont.playful(size: 26))
                .foregroundStyle(EggTheme.brown)

            GeometryReader { geo in
                let layout = ArcLayout(in: geo.size)
                let thumbPoint = dragThumbPoint ?? layout.point(for: selectedIndex, count: options.count)

                ZStack {
                    RainbowArc(layout: layout)
                        .stroke(
                            LinearGradient(
                                colors: [lightYellow, darkYellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )

                    ForEach(options) { option in
                        let point = layout.point(for: option.id, count: options.count)
                        Circle()
                            .fill(EggTheme.brown.opacity(0.28))
                            .frame(width: 4, height: 4)
                            .position(point)
                    }

                    ForEach(options) { option in
                        let point = layout.point(for: option.id, count: options.count)
                        Text(option.tickLabel)
                            .font(AppFont.playful(size: 12))
                            .foregroundStyle(EggTheme.brown.opacity(0.55))
                            .position(x: point.x, y: min(point.y + 8, geo.size.height - 3))
                    }

                    Circle()
                        .fill(darkYellow)
                        .overlay {
                            Circle().stroke(EggTheme.cream.opacity(0.85), lineWidth: 1.5)
                        }
                        .frame(width: 13, height: 13)
                        .position(thumbPoint)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = layout.fraction(for: value.location)
                            selectedIndex = layout.index(forFraction: fraction, count: options.count)
                            dragThumbPoint = layout.point(forFraction: fraction)
                        }
                        .onEnded { value in
                            let fraction = layout.fraction(for: value.location)
                            selectedIndex = layout.index(forFraction: fraction, count: options.count)
                            dragThumbPoint = nil
                        }
                )
            }
            .frame(height: 38)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(WindowDragBlocker())
    }
}

private struct RainbowArc: Shape {
    let layout: ArcLayout

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: layout.center,
            radius: layout.radius,
            startAngle: .radians(layout.startAngle),
            endAngle: .radians(layout.endAngle),
            clockwise: false
        )
        return path
    }
}

private struct ArcLayout {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double

    init(in size: CGSize) {
        let padX: CGFloat = 10
        let padTop: CGFloat = 8
        let delta = Double.pi * 0.24

        startAngle = Double.pi + delta
        endAngle = Double.pi * 2 - delta
        radius = (size.width / 2 - padX) / cos(delta)
        center = CGPoint(x: size.width / 2, y: padTop + radius)
    }

    func point(for index: Int, count: Int) -> CGPoint {
        point(forFraction: CGFloat(index) / CGFloat(count - 1))
    }

    func point(forFraction fraction: CGFloat) -> CGPoint {
        let t = min(max(fraction, 0), 1)
        let angle = startAngle + Double(t) * (endAngle - startAngle)
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    func fraction(for location: CGPoint) -> CGFloat {
        var angle = atan2(location.y - center.y, location.x - center.x)
        if angle < 0 {
            angle += 2 * .pi
        }

        let clamped = min(max(angle, startAngle), endAngle)
        return CGFloat((clamped - startAngle) / (endAngle - startAngle))
    }

    func index(forFraction fraction: CGFloat, count: Int) -> Int {
        let raw = Int((fraction * CGFloat(count - 1)).rounded())
        return min(max(raw, 0), count - 1)
    }
}
