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
                    .scaledFont(size: 24, weight: .bold, relativeTo: .headline)
                Text("Need help? Reach out to our support team.")
                    .scaledFont(size: 14, relativeTo: .body)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("support@vault.app", systemImage: "envelope")
                    Label("+94 77 000 0000", systemImage: "phone")
                    Label("Mon–Fri · 9am–5pm", systemImage: "clock")
                }
                .scaledFont(size: 14, weight: .medium, relativeTo: .headline)
                .padding(14)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)

                Text("Troubleshooting")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("If you are having trouble logging in, try resetting your password or check your internet connection.")
                    .scaledFont(size: 14, relativeTo: .body)
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
