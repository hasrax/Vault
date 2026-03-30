//
//  ChangePasswordView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("New Password") {
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }

            if !errorMessage.isEmpty {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(Color.expense)
                }
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    save()
                } label: {
                    if isSaving { ProgressView() }
                    else { Text("Save") }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() {
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isSaving = true
        errorMessage = ""
        appState.changePassword(newPassword: newPassword) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView().environmentObject(AppState())
    }
}
