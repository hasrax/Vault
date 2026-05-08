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
                    .scaledFont(size: 24, weight: .bold, relativeTo: .headline)
                Text("Last updated: March 30, 2026")
                    .scaledFont(size: 12, relativeTo: .body)
                    .foregroundStyle(.secondary)

                Text("1. Acceptance of Terms")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("By using Vault, you agree to these terms. Replace this placeholder with your legal terms.")

                Text("2. Use of the App")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("Use Vault responsibly. Do not misuse, reverse engineer, or attempt unauthorized access.")

                Text("3. Account Security")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("You are responsible for safeguarding your login credentials.")

                Text("4. Changes")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
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
