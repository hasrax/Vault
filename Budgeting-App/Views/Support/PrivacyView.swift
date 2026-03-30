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
                    .font(.system(size: 24, weight: .bold))
                Text("Last updated: March 30, 2026")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("1. Data We Collect")
                    .font(.system(size: 16, weight: .semibold))
                Text("We collect your profile info and budgeting data to provide the service.")

                Text("2. How We Use Data")
                    .font(.system(size: 16, weight: .semibold))
                Text("Your data is used to personalize budgets, insights, and reminders.")

                Text("3. Security")
                    .font(.system(size: 16, weight: .semibold))
                Text("We protect your data with industry-standard security practices.")

                Text("4. Your Choices")
                    .font(.system(size: 16, weight: .semibold))
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
