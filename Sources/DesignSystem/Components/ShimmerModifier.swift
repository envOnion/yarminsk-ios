import SwiftUI

public struct ShimmerModifier: ViewModifier {
    public let active: Bool
    public let duration: Double

    @State private var phase: CGFloat = 0

    public init(active: Bool = true, duration: Double = 1.6) {
        self.active = active
        self.duration = duration
    }

    public func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { proxy in
                        let size = proxy.size
                        let gradientWidth = max(size.width, 100) * 1.5

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.22), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: gradientWidth, height: size.height)
                        .offset(x: -gradientWidth + (phase * (size.width + gradientWidth)))
                    }
                    .mask(content)
                )
                .onAppear {
                    phase = 0
                    withAnimation(
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

public extension View {
    func shimmering(active: Bool = true, duration: Double = 1.6) -> some View {
        modifier(ShimmerModifier(active: active, duration: duration))
    }
}

public struct ShimmerBox: View {
    public let cornerRadius: CGFloat
    public let height: CGFloat?

    public init(cornerRadius: CGFloat = 8, height: CGFloat? = nil) {
        self.cornerRadius = cornerRadius
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.yarSubject80)
            .frame(height: height)
            .shimmering()
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(spacing: 16) {
            ShimmerBox(cornerRadius: 12, height: 60)
            ShimmerBox(cornerRadius: 24, height: 180)
            Text("Загрузка карточки...")
                .font(.yarBodySBold)
                .foregroundColor(.yarSubject40)
                .shimmering()
        }
        .padding()
    }
}
