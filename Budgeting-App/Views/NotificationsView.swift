//
//  NotificationsView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = NotificationStore.shared
    @State private var filter: Filter = .recent

    private enum Filter: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case unread = "Unread"
        case all = "All"

        var id: String { rawValue }
    }

    private var filteredItems: [AppNotification] {
        let sorted = store.items.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .recent:
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return sorted.filter { $0.createdAt >= cutoff }
        case .unread:
            return sorted.filter { !$0.isRead }
        case .all:
            return sorted
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    if filteredItems.isEmpty {
                        Text("No notifications yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(filteredItems) { n in
                            NavigationLink {
                                NotificationDetailView(notification: n)
                            } label: {
                                NotificationCard(notification: n)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.clear)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all read") { store.markAllRead() }
                }
            }
        }
    }
}

private struct NotificationDetailView: View {
    @ObservedObject private var store = NotificationStore.shared
    let notification: AppNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(notification.title)
                .font(.system(size: 20, weight: .bold))

            Text(notification.message)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 8) {
                Text("Type:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text(notification.type.rawValue.capitalized)
                    .font(.system(size: 12, weight: .semibold))
            }

            HStack(spacing: 8) {
                Text("Time:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text(NotificationStore.absoluteTimeString(from: notification.createdAt))
                    .font(.system(size: 12, weight: .semibold))
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markRead(notification.id) }
    }
}

#Preview { NotificationsView() }
