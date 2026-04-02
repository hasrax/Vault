//
//  MainTabView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",    systemImage: "house.fill") }
                .tag(0)

            SearchView(showBack: false)
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(1)

            AICoachView()
                .tabItem { Label("AI Coach", systemImage: "brain.head.profile") }
                .tag(2)

            PlannerView()
                .tabItem { Label("Planner", systemImage: "calendar") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.uniBlue)
    }
}

#Preview {
    MainTabView().environmentObject(AppState())
}
