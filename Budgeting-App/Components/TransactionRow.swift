//
//  TransactionRow.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Single transaction row used in HomeView and TransactionsView.
/// Shows coloured icon circle, title + subtitle, and coloured amount.
struct TransactionRow: View {
    let transaction: Transaction
    @State private var showReceipt = false

    private var icon: String {
        if let category = transaction.category {
            return category.icon
        }
        if transaction.type == .expense {
            return transaction.budgetCategory.emoji
        }
        return transaction.incomeSource?.icon ?? "💰"
    }
    private var iconColor: Color {
        if let category = transaction.category {
            return category.color
        }
        if transaction.type == .expense {
            return transaction.budgetCategory.color
        }
        return Color.income
    }
    private var categoryLabel: String {
        if let category = transaction.category {
            return category.rawValue
        }
        if transaction.type == .expense {
            return transaction.budgetCategory.rawValue
        }
        return transaction.incomeSource?.rawValue ?? "Other"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(icon)
                    .font(.system(size: 18))
            }
            .accessibilityHidden(true)

            // Title + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(categoryLabel)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.secondary)
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                    Text(transaction.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            if let thumb = receiptThumbnail {
                Button {
                    showReceipt = true
                } label: {
                    thumb
                }
                .buttonStyle(.plain)
            }

            // Amount
            Text(
                "\(transaction.type == .income ? "+" : "−")\(transaction.amount.currencyRS)"
            )
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(transaction.type == .income ? Color.income : Color.expense)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(transaction.name), \(categoryLabel), \(transaction.type == .income ? "income" : "expense") \(transaction.amount.currencyRS)"
        )
        .sheet(isPresented: $showReceipt) {
            ReceiptPreview(
                image: receiptImage,
                url: receiptUrl
            )
        }
    }

    private var receiptImage: UIImage? {
        if let base64 = transaction.receiptImageBase64,
           let data = Data(base64Encoded: base64),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    private var receiptUrl: URL? {
        if let urlStr = transaction.receiptImageUrl {
            return URL(string: urlStr)
        }
        return nil
    }

    private var receiptThumbnail: AnyView? {
        if let image = receiptImage {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        if let url = receiptUrl {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(UIColor.secondarySystemBackground)
                    }
                }
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            )
        }
        return nil
    }
}

private struct ReceiptPreview: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage?
    let url: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit().padding()
                        default:
                            ProgressView().tint(.white)
                        }
                    }
                } else {
                    Text("No receipt")
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        TransactionRow(transaction: MockData.transactions[0])
            .padding(.horizontal)
        Divider().padding(.leading, 72)
        TransactionRow(transaction: MockData.transactions[2])
            .padding(.horizontal)
    }
    .padding(.vertical, 8)
    .background(Color(UIColor.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding()
}
