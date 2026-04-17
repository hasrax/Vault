//
//  PlannerViews.swift
// Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import UIKit

// MARK: - Planner Hub
struct PlannerView: View {
    @EnvironmentObject var appState: AppState
    @State private var path = NavigationPath()
    @State private var showThemePicker = false
    private let modules = MockData.plannerModules

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    plannerHeader

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
            // KEY: ignoresSafeArea on the ScrollView lets plannerHeader
            // extend its background behind the status bar (same as HomeView)
            .ignoresSafeArea(edges: .top)
            .background(Color.clear)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
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
        }
        .statusBarStyle(.lightContent)
        .sheet(isPresented: $showThemePicker) {
            PlannerThemePickerView()
        }
    }

    private var plannerHeader: some View {
        let topInset: CGFloat = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 47

        return ZStack(alignment: .bottom) {
            // Background fills all the way to top behind status bar
            HomeHeaderBackground()
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))

            // Content row: titles LEFT, palette button RIGHT
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Campus toolkit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                    Text("My Planner")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("Everything for budgeting, classes, and campus life.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                Spacer()
                // Theme customise button
                Button {
                    showThemePicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                }
                .accessibilityLabel("Customise planner theme")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(height: topInset + 140)
    }

    private func plannerCarouselCard(_ mod: PlannerModule) -> some View {
        let grad = appState.plannerTheme.gradient(for: mod.id)
        return VStack(alignment: .leading, spacing: 12) {
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
        .background(grad)
        .clipShape(RoundedRectangle(cornerRadius:18))
    }

    private func plannerGridCard(_ mod: PlannerModule) -> some View {
        let accent = appState.plannerTheme.color(for: mod.id)
        let grad   = appState.plannerTheme.gradient(for: mod.id)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(mod.pill)
                    .font(.system(size:10,weight:.bold)).textCase(.uppercase)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal,8).padding(.vertical,3)
                    .background(grad)
                    .clipShape(Capsule())
                Spacer()
                Text(mod.icon)
                    .font(.system(size: 14))
                    .frame(width: 26, height: 26)
                    .background(accent.opacity(0.12))
                    .clipShape(Circle())
            }
            Text(mod.title).font(.system(size:14,weight:.semibold)).foregroundStyle(Color.primary).lineLimit(1)
            Text(mod.description).font(.system(size: 11)).foregroundStyle(Color.secondary).lineLimit(2)
            HStack {
                Spacer()
                Image(systemName:"chevron.right").font(.system(size: 12, weight: .medium)).foregroundStyle(accent)
            }
        }
        .padding(14)
        .frame(maxWidth:.infinity, alignment:.leading)
        .lightCard()
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - Planner Theme Picker Sheet

struct PlannerThemePickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // Local draft — only committed when the user taps Save
    @State private var draft: PlannerTheme = PlannerTheme()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PlannerTheme.allModuleIds, id: \.self) { moduleId in
                        HStack(spacing: 14) {
                            // Module icon in its current accent colour
                            ZStack {
                                Circle()
                                    .fill(draft.color(for: moduleId))
                                    .frame(width: 38, height: 38)
                                Text(PlannerTheme.moduleIcon(for: moduleId))
                                    .font(.system(size: 18))
                            }

                            Text(PlannerTheme.moduleName(for: moduleId))
                                .font(.system(size: 15, weight: .medium))

                            Spacer()

                            // Native colour picker
                            ColorPicker("", selection: colorBinding(for: moduleId), supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 36, height: 36)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Choose a colour for each planner module")
                        .font(.system(size: 12, weight: .medium))
                        .textCase(.none)
                        .padding(.bottom, 4)
                }

                Section {
                    Button("Reset to defaults") {
                        withAnimation { draft = PlannerTheme() }
                    }
                    .foregroundStyle(Color.expense)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Planner Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        appState.plannerTheme = draft
                        appState.savePlannerTheme()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .onAppear { draft = appState.plannerTheme }
    }

    // Two-way binding between ColorPicker and the draft's hex string
    private func colorBinding(for moduleId: String) -> Binding<Color> {
        Binding(
            get: { draft.color(for: moduleId) },
            set: { newColor in
                // Convert SwiftUI Color -> hex (via UIColor)
                let uiColor = UIColor(darkenedColor(newColor))
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                let hex = String(format: "#%02X%02X%02X",
                                 Int(r * 255), Int(g * 255), Int(b * 255))
                draft.setHex(hex, for: moduleId)
            }
        )
    }

    private func darkenedColor(_ color: Color) -> Color {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let mix: CGFloat = 0.22
        let nr = r * (1.0 - mix)
        let ng = g * (1.0 - mix)
        let nb = b * (1.0 - mix)
        return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: 1.0)
    }
}

#Preview("Planner")   { PlannerView().environmentObject(AppState()) }

private struct StatusBarStyleSetter: UIViewControllerRepresentable {
    var style: UIStatusBarStyle

    func makeUIViewController(context: Context) -> UIViewController {
        StyleController(style: style)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? StyleController else { return }
        controller.style = style
        controller.setNeedsStatusBarAppearanceUpdate()
    }

    private final class StyleController: UIViewController {
        var style: UIStatusBarStyle

        init(style: UIStatusBarStyle) {
            self.style = style
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var preferredStatusBarStyle: UIStatusBarStyle {
            style
        }
    }
}

private extension View {
    func statusBarStyle(_ style: UIStatusBarStyle) -> some View {
        background(StatusBarStyleSetter(style: style))
    }
}
