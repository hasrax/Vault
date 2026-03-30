//
//  MoreView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - More View
// Matches React: MoreScreen.jsx — gradient feature grid with 6 coloured cards
struct MoreView: View {
    @State private var path = NavigationPath()

    private struct Feature: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let emoji: String
        let gradient: LinearGradient
    }

    private let features: [Feature] = [
        Feature(id:"semesterPlanner", title:"Semester Planner",  subtitle:"Schedule & deadlines",  emoji:"📅", gradient:.semesterGrad),
        Feature(id:"workSchedule",    title:"Work Schedule",     subtitle:"Shifts & earnings",      emoji:"💼", gradient:.workGrad),
        Feature(id:"mealPlan",        title:"Meal Plan",         subtitle:"Weekly nutrition",        emoji:"🍽️", gradient:LinearGradient(colors:[Color(hex:"#4facfe"),Color(hex:"#00f2fe")],startPoint:.topLeading,endPoint:.bottomTrailing)),
        Feature(id:"analytics",       title:"Analytics",         subtitle:"Spending insights",       emoji:"📊", gradient:.tealGrad),
        Feature(id:"savings",         title:"Savings Goals",     subtitle:"Track your goals",        emoji:"🎯", gradient:LinearGradient(colors:[Color(hex:"#fa709a"),Color(hex:"#fee140")],startPoint:.topLeading,endPoint:.bottomTrailing)),
        Feature(id:"splitBill",       title:"Split Bill",        subtitle:"Share with friends",      emoji:"🤝", gradient:.splitGrad),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    // Dark header matching React MoreScreen
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.headerGrad
                            .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Budgify")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text("More Features")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("All your campus life tools")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(24)
                        .padding(.top, 44)
                        .padding(.bottom, 28)
                    }

                    // Feature grid — 2 columns of coloured cards
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(features) { feature in
                            NavigationLink(value: feature.id) {
                                featureCard(feature)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Student life hub banner
                    HStack(spacing: 14) {
                        Text("🎓").font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Student Life Hub")
                                .font(.system(size: 15, weight: .semibold))
                            Text("6 tools to help manage university life")
                                .font(.caption1)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color.uniBlue.opacity(0.08), Color.uniPurple.opacity(0.08)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.uniBlue.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { dest in
                switch dest {
                case "semesterPlanner": SemesterPlannerView()
                case "workSchedule":    WorkScheduleView()
                case "mealPlan":        MealPlanView()
                case "analytics":       AnalyticsView()
                case "savings":         SavingsView()
                case "splitBill":       SplitBillView()
                default:                Text(dest)
                }
            }
        }
    }

    // Individual gradient card matching React more-card style
    private func featureCard(_ feature: Feature) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Gradient icon circle
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(feature.gradient)
                    .frame(width: 52, height: 52)
                Text(feature.emoji).font(.system(size: 24))
            }

            Spacer()

            Text(feature.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(feature.subtitle)
                .font(.caption1)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Arrow row
            HStack {
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview { MoreView() }
