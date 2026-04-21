//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import LocalAuthentication
import UIKit
import FirebaseAuth

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var showSignUp = false
    @State private var savedAccounts: [String] = []
    @State private var faceIdError = ""
    @State private var selectedAccount = ""
    @State private var selectedProvider: String? = nil
    @FocusState private var focusedField: LoginField?

    private enum LoginField {
        case email
        case password
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back
                    BackButton(isDark: false) { dismiss() }
                        .padding(.horizontal, 24).padding(.top, 56)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Sign in to continue budgeting")
                            .font(.subheadline).foregroundStyle(Color.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    VStack(spacing: 20) {
                        // Face ID Card
                        Button(action: authenticateWithBiometrics) {
                            VStack(spacing: 10) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.uniBlue)
                                Text("Sign in with Face ID")
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.primary)
                                Text("Quick and secure access")
                                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1))
                        }

                        if !faceIdError.isEmpty {
                            StatusBanner(text: faceIdError, systemImage: "exclamationmark.circle", style: .error)
                        }

                        // Divider
                        HStack {
                            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                            Text("or sign in with email")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                                .fixedSize()
                            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary)
                            HStack(spacing: 8) {
                                TextField("your@university.lk", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .foregroundStyle(Color.primary)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                                if !savedAccounts.isEmpty {
                                    Menu {
                                        ForEach(savedAccounts, id: \.self) { account in
                                            Button(account) {
                                                selectedAccount = account
                                                email = account
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(Color.secondary)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1))
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                            HStack {
                                Group {
                                    if showPassword { TextField("Enter your password", text: $password) }
                                    else { SecureField("Enter your password", text: $password) }
                                }
                                .foregroundStyle(Color.primary)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { signIn() }
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .padding(14)
                            .background(Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1))
                        }

                        // Forgot
                        Button("Forgot Password?") { resetPassword() }
                            .font(.system(size: 13)).foregroundStyle(Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            SocialIconButton(
                                isLoading: isGoogleLoading,
                                isEnabled: true,
                                action: signInWithGoogle
                            ) {
                                GoogleMark()
                            }
                            SocialIconButton(
                                isLoading: false,
                                isEnabled: false,
                                action: {}
                            ) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        if selectedProvider == "google" {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                Text("Signed in with Google. Set a password to use Face ID.")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)

                            Button("Set password") { resetPassword() }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.uniBlue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !infoMessage.isEmpty {
                            StatusBanner(text: infoMessage, systemImage: "checkmark.circle", style: .success)
                        }

                        // Error
                        if !errorMessage.isEmpty {
                            StatusBanner(text: errorMessage, systemImage: "exclamationmark.circle", style: .error)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            signIn()
                        } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Text("Sign In").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white) }
                            }
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient.ctaGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button {
                            showSignUp = true
                        } label: {
                            Text("Don't have an account? Sign Up")
                                .font(.system(size: 15)).foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 60)
                }
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView(onSignInTap: { showSignUp = false })
        }
        .onChange(of: email) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                selectedAccount = ""
                selectedProvider = nil
            } else {
                selectedAccount = trimmed
                selectedProvider = KeychainService.providerForAccount(trimmed)
            }
        }
        .onAppear {
            refreshSavedAccounts()
        }
    }

    private func refreshSavedAccounts() {
        let cached = KeychainService.savedAccounts()
        savedAccounts = cached
        if selectedAccount.isEmpty {
            selectedAccount = cached.first ?? ""
        }
        if !selectedAccount.isEmpty {
            selectedProvider = KeychainService.providerForAccount(selectedAccount)
        }

        guard !cached.isEmpty else { return }

        let group = DispatchGroup()
        var valid: [String] = []
        var hadValidationError = false

        for email in cached {
            group.enter()
            Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
                if let error {
                    _ = error
                    hadValidationError = true
                    valid.append(email)
                } else if let methods, !methods.isEmpty {
                    valid.append(email)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let validSet = Set(valid)
            let shouldPrune = !validSet.isEmpty && !hadValidationError
            if shouldPrune {
                for email in cached where !validSet.contains(email) {
                    KeychainService.removeAccount(email: email)
                }
            }

            let cleaned = KeychainService.savedAccounts()
            savedAccounts = cleaned
            if selectedAccount.isEmpty || !cleaned.contains(selectedAccount) {
                selectedAccount = cleaned.first ?? ""
            }
            selectedProvider = selectedAccount.isEmpty
                ? nil
                : KeychainService.providerForAccount(selectedAccount)
        }
    }

    private func glassField(label: String, placeholder: String,
                            text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.6))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private func signIn() {
        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetEmail = typedEmail.isEmpty ? selectedAccount : typedEmail
        let trimmedEmail = targetEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }
        isLoading = true
        errorMessage = ""
        infoMessage = ""
        authVM.signIn(email: trimmedEmail, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                if case let .failure(error) = result {
                    errorMessage = error.localizedDescription
                    let nsError = error as NSError
                    if nsError.domain == AuthErrorDomain,
                       let code = AuthErrorCode(rawValue: nsError.code),
                       code == .userNotFound {
                        KeychainService.removeAccount(email: trimmedEmail)
                        savedAccounts = KeychainService.savedAccounts()
                        if selectedAccount == trimmedEmail {
                            selectedAccount = ""
                        }
                    }
                } else {
                    _ = KeychainService.saveCredentials(email: trimmedEmail, password: password)
                    savedAccounts = KeychainService.savedAccounts()
                    selectedProvider = KeychainService.providerForAccount(trimmedEmail)
                }
            }
        }
    }

    private func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter your email to reset your password."
            return
        }
        errorMessage = ""
        infoMessage = ""
        authVM.resetPassword(email: trimmedEmail) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    infoMessage = "Password reset link sent to your email."
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func signInWithGoogle() {
        guard let presenter = topViewController() else {
            errorMessage = "Unable to open Google sign-in."
            return
        }
        isGoogleLoading = true
        errorMessage = ""
        infoMessage = ""
        authVM.signInWithGoogle(presenting: presenter) { result in
            DispatchQueue.main.async {
                isGoogleLoading = false
                if case let .failure(error) = result {
                    errorMessage = error.localizedDescription
                } else if let email = Auth.auth().currentUser?.email {
                    KeychainService.saveAccountEmail(email, provider: "google")
                    savedAccounts = KeychainService.savedAccounts()
                    selectedAccount = email
                    selectedProvider = "google"
                }
            }
        }
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }

    private func authenticateWithBiometrics() {
        guard selectedProvider != "google" else {
            faceIdError = "Google account selected. Set a password first."
            return
        }
        guard authVM.isFaceIDEnabled else {
            faceIdError = "Face ID is turned off in Settings."
            return
        }
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            faceIdError = "Face ID not available. Simulator: Features > Face ID > Enrolled."
            return
        }
        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetEmail = typedEmail.isEmpty ? selectedAccount : typedEmail
        guard !targetEmail.isEmpty else {
            faceIdError = "Enter or select an email first."
            return
        }
        faceIdError = ""
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Sign in to Vault") { success, _ in
            DispatchQueue.main.async {
                if success {
                    KeychainService.loadCredentials(email: targetEmail, reason: "Sign in to Vault") { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let savedPassword):
                                authVM.signIn(email: targetEmail, password: savedPassword) { signInResult in
                                    DispatchQueue.main.async {
                                        if case let .failure(error) = signInResult {
                                            faceIdError = error.localizedDescription
                                        }
                                    }
                                }
                            case .failure:
                                faceIdError = "No saved password for that account."
                            }
                        }
                    }
                } else {
                    faceIdError = "Face ID failed. Use your password."
                }
            }
        }
    }
}

// MARK: - Sign Up
struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var onSignInTap: (() -> Void)? = nil
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @FocusState private var focusedField: SignUpField?

    private enum SignUpField {
        case name
        case email
        case password
        case confirm
    }

    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword && agreedToTerms
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BackButton(isDark: false) { dismiss() }
                        .padding(.horizontal, 24).padding(.top, 56)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Text("Start your smart budgeting journey")
                            .font(.subheadline).foregroundStyle(Color.secondary)
                    }
                    .padding(.horizontal, 24).padding(.top, 28)

                    VStack(spacing: 18) {
                        darkFormField(
                            label: "Full Name",
                            placeholder: "Enter your name",
                            text: $name,
                            isSecure: false,
                            focus: $focusedField,
                            field: .name,
                            submitLabel: .next
                        ) {
                            focusedField = .email
                        }

                        darkFormField(
                            label: "Email",
                            placeholder: "your@university.lk",
                            text: $email,
                            isSecure: false,
                            focus: $focusedField,
                            field: .email,
                            submitLabel: .next
                        ) {
                            focusedField = .password
                        }

                        darkFormField(
                            label: "Password",
                            placeholder: "Create a password",
                            text: $password,
                            isSecure: true,
                            focus: $focusedField,
                            field: .password,
                            submitLabel: .next
                        ) {
                            focusedField = .confirm
                        }

                        darkFormField(
                            label: "Confirm Password",
                            placeholder: "Confirm your password",
                            text: $confirmPassword,
                            isSecure: true,
                            focus: $focusedField,
                            field: .confirm,
                            submitLabel: .go
                        ) {
                            signUp()
                        }

                        HStack(spacing: 12) {
                            SocialIconButton(
                                isLoading: isGoogleLoading,
                                isEnabled: true,
                                action: signUpWithGoogle
                            ) {
                                GoogleMark()
                            }
                            SocialIconButton(
                                isLoading: false,
                                isEnabled: false,
                                action: {}
                            ) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        HStack(spacing: 10) {
                            Button {
                                agreedToTerms.toggle()
                            } label: {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(agreedToTerms ? Color.uniBlue : Color.secondary)
                                    .font(.system(size: 20))
                            }
                            Text("I agree to the Terms & Privacy Policy")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 32)

                    VStack(spacing: 12) {
                        Button {
                            signUp()
                        } label: {
                            Group {
                                if isLoading { ProgressView().tint(.white) }
                                else { Text("Create Account") }
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient.ctaGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button { dismiss() } label: {
                            Text("Already have an account? Sign In")
                                .font(.system(size: 15)).foregroundStyle(Color.secondary)
                        }
                        if !errorMessage.isEmpty {
                            StatusBanner(text: errorMessage, systemImage: "exclamationmark.circle", style: .error)
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 60)
                }
            }
        }
    }

    private func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValid else {
            errorMessage = "Please complete all fields and accept terms."
            return
        }
        isLoading = true
        errorMessage = ""
        authVM.signUp(name: name, email: trimmedEmail, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                if case let .failure(error) = result {
                    errorMessage = error.localizedDescription
                } else {
                    _ = KeychainService.saveCredentials(email: trimmedEmail, password: password)
                }
            }
        }
    }

    private func signUpWithGoogle() {
        guard let presenter = topViewController() else {
            errorMessage = "Unable to open Google sign-in."
            return
        }
        isGoogleLoading = true
        errorMessage = ""
        authVM.signInWithGoogle(presenting: presenter) { result in
            DispatchQueue.main.async {
                isGoogleLoading = false
                if case let .failure(error) = result {
                    errorMessage = error.localizedDescription
                }
                if let email = Auth.auth().currentUser?.email {
                    KeychainService.saveAccountEmail(email, provider: "google")
                }
            }
        }
    }

    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }

    @ViewBuilder
    private func darkFormField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        focus: FocusState<SignUpField?>.Binding,
        field: SignUpField,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
            Group {
                if isSecure { SecureField(placeholder, text: text) }
                else {
                    TextField(placeholder, text: text)
                        .keyboardType(label == "Email" ? .emailAddress : .default)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(label == "Email" ? .never : .words)
                }
            }
            .focused(focus, equals: field)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
            .foregroundStyle(Color.primary)
            .padding(14)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
    }

}

private enum StatusBannerStyle {
    case success, error

    var background: Color {
        switch self {
        case .success: return Color.income.opacity(0.18)
        case .error: return Color.expense.opacity(0.18)
        }
    }

    var foreground: Color {
        switch self {
        case .success: return Color.income
        case .error: return Color.expense
        }
    }
}

private struct StatusBanner: View {
    let text: String
    let systemImage: String
    let style: StatusBannerStyle

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style.foreground.opacity(0.4), lineWidth: 1)
            )
    }
}

private struct SocialAuthButton<Icon: View>: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    let icon: Icon

    init(
        title: String,
        isLoading: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon
                    .frame(width: 20, height: 20)
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white.opacity(isEnabled ? 0.08 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(isEnabled ? 0.12 : 0.06), lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

private struct SocialIconButton<Icon: View>: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    let icon: Icon

    init(
        isLoading: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(isEnabled ? 0.04 : 0.02))
                Circle()
                    .stroke(Color.black.opacity(isEnabled ? 0.10 : 0.05), lineWidth: 1)
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    icon
                }
            }
            .frame(width: 44, height: 44)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

private struct GoogleMark: View {
    var body: some View {
        if let image = UIImage(named: "G") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        } else {
            ZStack {
                Circle().fill(Color(hex: "#EA4335")).frame(width: 20, height: 20)
                Text("G")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("Login")  {
    let state = AppState()
    return LoginView().environmentObject(AuthViewModel(appState: state))
}
#Preview("SignUp") {
    let state = AppState()
    return SignUpView().environmentObject(AuthViewModel(appState: state))
}
