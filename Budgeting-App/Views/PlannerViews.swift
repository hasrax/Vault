//
//  PlannerViews.swift
// Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Planner Hub
struct PlannerView: View {
    @State private var path = NavigationPath()
    private let modules = MockData.plannerModules

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    // Dark header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient.headerGrad
                            .ignoresSafeArea(edges: .top)
                        LinearGradient.headerGrad
                            .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Campus toolkit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .textCase(.uppercase)
                            Text("My Planner")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                            Text("Everything for budgeting, classes, and campus life.")
                                .font(.subheadline).foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(24)
                        .padding(.top, 44)
                        .padding(.bottom, 24)
                    }

                    // Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(modules) { mod in
                            NavigationLink(value: mod.destination) {
                                plannerGridCard(mod)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    // Horizontal carousel
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Swipeable summaries")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary).textCase(.uppercase)
                            Text("Slide through the toolkit").font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(modules) { mod in
                                    NavigationLink(value: mod.destination) {
                                        plannerCarouselCard(mod)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 24)

                    // Info card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What happens in each area?").font(.system(size: 15, weight: .semibold))
                        ForEach([
                            ("📅","Semester planning","Sync tuition, exam weeks, and assignment reminders"),
                            ("💼","Work shifts","Compare hours versus targets and export the rota"),
                            ("🍽️","Meal & study","Balance swipes, dining rupees, and academic supplies"),
                            ("🎯","Savings","Route rupees toward books, rent, and emergency buffer"),
                            ("🔔","Smart notifications","Keep helpful nudges and snooze the rest"),
                            ("🤝","Split bill","Invite roommates, log each share, send a settle-up link"),
                        ], id:\.0) { emoji, title, desc in
                            HStack(alignment:.top, spacing:10) {
                                Text(emoji).font(.system(size:16))
                                VStack(alignment:.leading,spacing:2) {
                                    Text(title).font(.system(size:13,weight:.semibold))
                                    Text(desc).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .lightCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.clear)
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { dest in
                switch dest {
                case "semesterPlanner": SemesterPlannerView()
                case "workSchedule":    WorkScheduleView()
                case "mealPlan":        MealPlanView()
                case "savings":         SavingsView()
                case "splitBill":       SplitBillView()
                case "analytics":       AnalyticsView()
                default:                Text(dest)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func plannerCarouselCard(_ mod: PlannerModule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mod.pill)
                .font(.system(size:11,weight:.bold)).textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.horizontal,10).padding(.vertical,4)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            Spacer()
            Text(mod.title)
                .font(.system(size:17,weight:.bold))
                .foregroundStyle(Color.white)
            Text(mod.description)
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(3)
            Text("Open →")
                .font(.system(size:13,weight:.semibold)).foregroundStyle(Color.white)
                .padding(.top,4)
        }
        .padding(18)
        .frame(width:200,height:180)
        .background(mod.gradient)
        .clipShape(RoundedRectangle(cornerRadius:18))
    }

    private func plannerGridCard(_ mod: PlannerModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(mod.pill)
                    .font(.system(size:10,weight:.bold)).textCase(.uppercase)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal,8).padding(.vertical,3)
                    .background(mod.gradient)
                    .clipShape(Capsule())
                Spacer()
                Text(mod.icon)
                    .font(.system(size: 14))
                    .frame(width: 26, height: 26)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
            }
            Text(mod.title).font(.system(size:14,weight:.semibold)).foregroundStyle(Color.primary).lineLimit(1)
            Text(mod.description).font(.system(size: 11)).foregroundStyle(Color.secondary).lineLimit(2)
            HStack {
                Spacer()
                Image(systemName:"chevron.right").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth:.infinity, alignment:.leading)
        .lightCard()
    }
}
#Preview("Planner")   { PlannerView().environmentObject(AppState()) }
