//
//  SavingsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Savings
struct SavingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var goals = MockData.savingsGoals
    private var totalSaved:  Double { goals.reduce(0){$0+$1.currentAmount} }
    private var totalTarget: Double { goals.reduce(0){$0+$1.targetAmount} }

    var body: some View {
        ScrollView {
            VStack(spacing:16) {
                // Total card
                VStack(spacing:12) {
                    Text("Total Saved").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                    Text(totalSaved.currencyRS)
                        .font(.system(size:36,weight:.bold,design:.rounded)).foregroundStyle(Color.white)
                    Text("of \(totalTarget.currencyRS) goal").font(.subheadline).foregroundStyle(Color.white.opacity(0.8))
                    UniProgressBar(progress:totalSaved/totalTarget,color:.white,height:10)
                }
                .padding(24)
                .background(LinearGradient.savingsGoldGrad)
                .clipShape(RoundedRectangle(cornerRadius:20))

                // Goals
                ForEach(goals) { goal in
                    GoalCard(goal:goal) {}
                }

                // Motivation
                HStack(spacing:14) {
                    Text("🚀").font(.system(size:32))
                    VStack(alignment:.leading,spacing:4) {
                        Text("Keep going!").font(.system(size:15,weight:.semibold))
                        Text("You've saved \(totalSaved.currencyRS). Just \((totalTarget-totalSaved).currencyRS) more to reach all goals!")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    }
                }
                .padding(16)
                .background(Color.uniBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius:14))
                .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.uniBlue.opacity(0.15),lineWidth:1))
            }
            .padding(.horizontal,16).padding(.top,16).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Savings Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement:.topBarTrailing) {
                Button { } label: { Image(systemName:"plus") }
            }
        }
    }
}

#Preview("Savings") { NavigationStack { SavingsView() } }
