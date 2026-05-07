//
//   SectionHeader.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Title + optional "See all" action link used throughout the app.
struct SectionHeader: View {
    let title: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .scaledFont(size: 18, weight: .semibold)
                .foregroundStyle(.primary)
            Spacer()
            if let label = actionLabel {
                Button(action: action ?? {}) {
                    Text(label)
                        .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                        .foregroundStyle(Color.uniBlue)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SectionHeader(title: "Recent Transactions", actionLabel: "See all", action: {})
        SectionHeader(title: "Quick Actions")
    }
    .padding()
}
