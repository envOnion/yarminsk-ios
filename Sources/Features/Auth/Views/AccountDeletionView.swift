import SwiftUI

public struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AccountDeletionViewModel
    @State private var password = ""
    @State private var showConfirmation = false
    private let email: String

    public init(container: AppContainer) {
        email = container.authService.currentUser()?.email ?? ""
        _viewModel = StateObject(wrappedValue: AccountDeletionViewModel(
            authService: container.authService, discountService: container.discountService,
            sessionStorage: container.sessionStorage
        ))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 44)).foregroundColor(.yarError)
                    Text("УДАЛЕНИЕ АККАУНТА").font(.yarHeadline3)
                    if !email.isEmpty { Text(email).font(.yarBodySRegular).foregroundColor(.yarSubject40) }
                    Text("Ваш аккаунт, персональные данные в приложении и карта лояльности будут удалены. Восстановить карту после удаления нельзя.")
                        .font(.yarBodySRegular)
                    if viewModel.provider == .password {
                        SecureField("Текущий пароль", text: $password)
                            .textContentType(.password)
                            .font(.yarBodyMRegular)
                            .padding(16).background(Color.yarSubject90).cornerRadius(12)
                            .disabled(viewModel.isDeleting)
                    } else {
                        Text("Для подтверждения откроется окно входа \(viewModel.provider == .apple ? "Apple" : "Google"). Выберите тот же аккаунт.")
                            .font(.yarBodySRegular).foregroundColor(.yarSubject40)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).font(.yarBodySRegular).foregroundColor(.yarError)
                    }
                    Button(role: .destructive) { showConfirmation = true } label: {
                        HStack {
                            Spacer()
                            if viewModel.isDeleting { ProgressView().tint(.white) }
                            Text(viewModel.isDeleting ? "УДАЛЯЕМ…" : "УДАЛИТЬ АККАУНТ")
                                .font(.yarBodySBold)
                            Spacer()
                        }
                        .padding(18).background(Color.yarError).foregroundColor(.white).cornerRadius(12)
                    }
                    .disabled(viewModel.isDeleting || (viewModel.provider == .password && password.isEmpty))
                }
                .padding(24)
            }
            .background(Color.yarSubject95)
            .navigationTitle("АККАУНТ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") { dismiss() }.disabled(viewModel.isDeleting)
                }
            }
            .confirmationDialog("Удалить аккаунт навсегда?", isPresented: $showConfirmation, titleVisibility: .visible) {
                Button("Удалить аккаунт и карту", role: .destructive) {
                    Task {
                        let enteredPassword = password
                        password = ""
                        await viewModel.deleteAccount(password: enteredPassword)
                        if viewModel.didDeleteAccount { dismiss() }
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие нельзя отменить.")
            }
            .interactiveDismissDisabled(viewModel.isDeleting)
        }
    }
}
