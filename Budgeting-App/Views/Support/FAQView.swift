//
//  FAQView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI

struct FAQView: View {
    private let faqs: [(String, String)] = [
        ("How do I add a transaction?", "Go to Home or History and tap the + button."),
        ("How is my budget calculated?", "Budgets are split by Needs, Wants, and Savings percentages."),
        ("Can I edit my budget later?", "Yes. Go to Budget Settings and tap the slider icon."),
        ("How do I reset my password?", "Use the Forgot Password link on the login screen."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Frequently Asked Questions")
                    .font(.system(size: 24, weight: .bold))

                ForEach(faqs.indices, id: \.self) { idx in
                    let item = faqs[idx]
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(.system(size: 16, weight: .semibold))
                        Text(item.1)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                }
            }
            .padding(20)
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { FAQView() }
}
