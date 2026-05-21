import SwiftUI

extension View {
    @ViewBuilder
    func cborgGlassSurface(cornerRadius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            let baseGlass = tint.map { Glass.regular.tint($0.opacity(0.16)) } ?? .regular
            let glass = interactive ? baseGlass.interactive() : baseGlass

            self.glassEffect(glass, in: shape)
        } else {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            self
                .background(.thinMaterial, in: shape)
                .overlay {
                    shape.stroke((tint ?? Color.secondary).opacity(0.18), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    func cborgGlassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            let baseGlass = tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? .regular
            let glass = interactive ? baseGlass.interactive() : baseGlass

            self.glassEffect(glass, in: Capsule())
        } else {
            self
                .background(.thinMaterial, in: Capsule())
                .overlay {
                    Capsule().stroke((tint ?? Color.secondary).opacity(0.18), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    func cborgPrimaryActionStyle() -> some View {
        if #available(macOS 26.0, *) {
            self
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}
