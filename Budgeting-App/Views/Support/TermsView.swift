//
//  TermsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.system(size: 24, weight: .bold))
                Text("Last updated: March 30, 2026")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("1. Acceptance of Terms")
                    .font(.system(size: 16, weight: .semibold))
                Text("By using Vault, you agree to these terms. Replace this placeholder with your legal terms.")

                Text("2. Use of the App")
                    .font(.system(size: 16, weight: .semibold))
                Text("Use Vault responsibly. Do not misuse, reverse engineer, or attempt unauthorized access.")

                Text("3. Account Security")
                    .font(.system(size: 16, weight: .semibold))
                Text("You are responsible for safeguarding your login credentials.")

                Text("4. Changes")
                    .font(.system(size: 16, weight: .semibold))
                Text("We may update these terms. Continued use means acceptance of updates.")
            }
            .padding(20)
        }
        .navigationTitle("Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { TermsView() }
}
