//
//  GoalCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct GoalCard: View {
    let goal: SavingsGoal
    let onAddMoney: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Header
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(goal.color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Text(goal.icon).scaledFont(size: 26, relativeTo: .title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(goal.name)
                            .scaledFont(size: 17, weight: .semibold, relativeTo: .headline)
                            .lineLimit(1)
                        if goal.isComplete {
                            Text("Done")
                                .scaledFont(size: 11, weight: .bold, relativeTo: .caption2)
                                .foregroundStyle(Color.income)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Color.income.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text(
                        goal.isComplete        ? "Goal achieved! 🎉" :
                        goal.daysLeft != nil   ? "\(goal.daysLeft!) days left" :
                                                 "No deadline"
                    )
                    .scaledFont(size: 13, relativeTo: .subheadline)
                    .foregroundStyle(Color.secondary)
                }
                Spacer()
            }

            // Amount + progress bar
            HStack {
                Text(goal.currentAmount.currencyRS)
                    .scaledFont(size: 20, weight: .bold, relativeTo: .title3)
                    .foregroundStyle(goal.color)
                Spacer()
                Text("of \(goal.targetAmount.currencyRS)")
                    .scaledFont(size: 13, relativeTo: .subheadline)
                    .foregroundStyle(Color.secondary)
            }
            UniProgressBar(progress: goal.progress, color: goal.color, height: 10)

            // Footer
            if !goal.isComplete {
                HStack {
                    Text("\((goal.targetAmount - goal.currentAmount).currencyRS) to go")
                        .scaledFont(size: 13, relativeTo: .subheadline)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Button(action: onAddMoney) {
                        Text("+ Add Money")
                            .scaledFont(size: 13, weight: .semibold, relativeTo: .subheadline)
                            .foregroundStyle(goal.color)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(goal.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Add money to \(goal.name)")
                }
            }
        }
        .padding(20)
        .plannerModuleCard(accent: goal.color)
    }
}

#Preview {
    VStack(spacing: 14) {
        ForEach(MockData.savingsGoals) { goal in
            GoalCard(goal: goal, onAddMoney: {})
        }
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
