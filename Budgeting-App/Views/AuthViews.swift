//
//  Untitled.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import LocalAuthentication

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back
                    BackButton(isDark: true) { dismiss() }
                        .padding(.horizontal, 24).padding(.top, 56)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Sign in to continue budgeting")
                            .font(.subheadline).foregroundStyle(Color.white.opacity(0.55))
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
                                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                Text("Quick and secure access")
                                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.uniBlue.opacity(0.3), lineWidth: 1))
                        }

                        // Divider
                        HStack {
                            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                            Text("or sign in with email")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.4))
                                .fixedSize()
                            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                        }

                        // Email
                        glassField(label: "Email", placeholder: "your@university.lk",
                                   text: $email, keyboard: .emailAddress)

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.6))
                            HStack {
                                Group {
                                    if showPassword { TextField("Enter your password", text: $password) }
                                    else { SecureField("Enter your password", text: $password) }
                                }
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(Color.white.opacity(0.4))
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }

                        // Forgot
                        Button("Forgot Password?") {}
                            .font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Error
                        if !errorMessage.isEmpty {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.expense)
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
                                .font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 60)
                }
            }
        }
        .fullScreenCover(isPresented: $showSignUp) { SignUpView() }
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
        isLoading = true
        errorMessage = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            appState.isAuthenticated = true
        }
    }

    private func authenticateWithBiometrics() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Simulator fallback
            appState.isAuthenticated = true
            return
        }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                           localizedReason: "Sign in to Vault") { success, _ in
            DispatchQueue.main.async {
                if success { appState.isAuthenticated = true }
                else { errorMessage = "Face ID failed. Use your password." }
            }
        }
    }
}

// MARK: - Sign Up
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false

    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword && agreedToTerms
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    BackButton(isDark: true) { dismiss() }
                        .padding(.horizontal, 24).padding(.top, 56)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Start your smart budgeting journey")
                            .font(.subheadline).foregroundStyle(Color.white.opacity(0.55))
                    }
                    .padding(.horizontal, 24).padding(.top, 28)

                    VStack(spacing: 18) {
                        ForEach([
                            ("Full Name",        "Enter your name",          name,            false),
                            ("Email",            "your@university.lk",       email,           false),
                            ("Password",         "Create a password",        password,        true),
                            ("Confirm Password", "Confirm your password",    confirmPassword, true),
                        ], id: \.0) { label, ph, _, isSecure in
                            darkFormField(label: label, placeholder: ph,
                                          text: fieldBinding(label), isSecure: isSecure)
                        }

                        HStack(spacing: 10) {
                            Button {
                                agreedToTerms.toggle()
                            } label: {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(agreedToTerms ? Color.uniBlue : Color.white.opacity(0.3))
                                    .font(.system(size: 20))
                            }
                            Text("I agree to the Terms & Privacy Policy")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 32)

                    VStack(spacing: 12) {
                        Button {
                            appState.isAuthenticated = true
                        } label: {
                            Text("Create Account")
                                .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(LinearGradient.ctaGrad)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button { dismiss() } label: {
                            Text("Already have an account? Sign In")
                                .font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 60)
                }
            }
        }
    }

    private func fieldBinding(_ label: String) -> Binding<String> {
        switch label {
        case "Full Name":        return $name
        case "Email":            return $email
        case "Password":         return $password
        default:                 return $confirmPassword
        }
    }

    @ViewBuilder
    private func darkFormField(label: String, placeholder: String,
                               text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.6))
            Group {
                if isSecure { SecureField(placeholder, text: text) }
                else {
                    TextField(placeholder, text: text)
                        .keyboardType(label == "Email" ? .emailAddress : .default)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(label == "Email" ? .never : .words)
                }
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
}

#Preview("Login")  { LoginView().environmentObject(AppState()) }
#Preview("SignUp") { SignUpView().environmentObject(AppState()) }
