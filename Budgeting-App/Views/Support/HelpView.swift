//
//  HelpView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Help & Support")
                    .font(.system(size: 24, weight: .bold))
                Text("Need help? Reach out to our support team.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("support@vault.app", systemImage: "envelope")
                    Label("+94 77 000 0000", systemImage: "phone")
                    Label("Mon–Fri · 9am–5pm", systemImage: "clock")
                }
                .font(.system(size: 14, weight: .medium))
                .padding(14)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)

                Text("Troubleshooting")
                    .font(.system(size: 16, weight: .semibold))
                Text("If you are having trouble logging in, try resetting your password or check your internet connection.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { HelpView() }
}
