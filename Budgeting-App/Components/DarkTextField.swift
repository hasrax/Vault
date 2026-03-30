//
//  DarkTextField.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Glass-style text field for use on dark backgrounds (onboarding, auth, add transaction).
/// Renders label above, input field with glass fill and border below.
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(capitalize)
                }
            }
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
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
    .background(Color(hex: "#1A1A1A"))
}
