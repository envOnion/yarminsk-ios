import SwiftUI

public struct YarCheckbox: View {
    @Binding public var isChecked: Bool
    public let label: AnyView

    public init<V: View>(
        isChecked: Binding<Bool>,
        @ViewBuilder label: () -> V
    ) {
        self._isChecked = isChecked
        self.label = AnyView(label())
    }

    public init(
        _ text: String,
        isChecked: Binding<Bool>
    ) {
        self._isChecked = isChecked
        self.label = AnyView(
            Text(text)
                .font(.yarBodySRegular)
                .foregroundColor(.yarSubject20)
                .multilineTextAlignment(.leading)
        )
    }

    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isChecked.toggle()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox square
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isChecked ? Color.yarSecondary : Color.yarSubject60, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isChecked ? Color.yarSecondary.opacity(0.18) : Color.clear)
                        )
                        .frame(width: 22, height: 22)

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yarSecondary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 22, height: 22)

                label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.yarSubject95.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 20) {
            YarCheckbox("Соглашаюсь на обработку и хранение персональных данных", isChecked: .constant(true))
            YarCheckbox("Не отмечено", isChecked: .constant(false))
        }
        .padding()
    }
}
