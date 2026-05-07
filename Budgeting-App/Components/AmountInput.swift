//
//  AmountInput.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Large centred amount input — "Rs." prefix + big numeric field.
/// Used in AddTransactionView and SplitBillView.
struct AmountInput: View {
    @Binding var text: String
    var accentColor: Color = .uniBlue
    var currency:    String = "Rs."

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(currency)
                .scaledFont(size: 32, weight: .bold, design: .rounded, relativeTo: .title2)
                .foregroundStyle(accentColor.opacity(0.6))

            TextField("0", text: $text)
                .scaledFont(size: 48, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                .foregroundStyle(accentColor)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(minWidth: 80)
        }
        .accessibilityLabel("Amount input")
        .accessibilityValue(text.isEmpty ? "0" : text)
    }
}

#Preview {
    VStack(spacing: 32) {
        AmountInput(text: .constant("3200"), accentColor: .expense)
        AmountInput(text: .constant(""), accentColor: .uniPurple)
    }
    .padding(24)
    .background(Color(UIColor.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
}

