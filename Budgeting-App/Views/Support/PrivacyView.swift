//
//  PrivacyView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .scaledFont(size: 24, weight: .bold, relativeTo: .headline)
                Text("Last updated: March 30, 2026")
                    .scaledFont(size: 12, relativeTo: .body)
                    .foregroundStyle(.secondary)

                Text("1. Data We Collect")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("We collect your profile info and budgeting data to provide the service.")

                Text("2. How We Use Data")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("Your data is used to personalize budgets, insights, and reminders.")

                Text("3. Security")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("We protect your data with industry-standard security practices.")

                Text("4. Your Choices")
                    .scaledFont(size: 16, weight: .semibold, relativeTo: .headline)
                Text("You can edit or delete your account data at any time.")
            }
            .padding(20)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PrivacyView() }
}
