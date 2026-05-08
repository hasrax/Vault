//
//  DarkTextField.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Light-style text field for post-login forms.
/// Renders label above, input field with soft fill and border below.
struct DarkTextField: View {
    let label:       String
    let placeholder: String
    @Binding var text: String
    var keyboard:    UIKeyboardType = .default
    var isSecure:    Bool = false
    var capitalize:  TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                .foregroundStyle(Color.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(capitalize)
                }
            }
            .foregroundStyle(Color.primary)
            .autocorrectionDisabled()
            .padding(14)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        DarkTextField(label: "Email",    placeholder: "your@university.lk", text: .constant(""),     keyboard: .emailAddress, capitalize: .never)
        DarkTextField(label: "Password", placeholder: "Enter your password", text: .constant("test"), isSecure: true)
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
