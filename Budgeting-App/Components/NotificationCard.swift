//
//  NotificationCard.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Notification list item — colour chip, title, message, timestamp.
/// Used in NotificationsView.
struct NotificationCard: View {
    let notification: AppNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type chip
                Text(notification.type.rawValue.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(notification.type.chipColor)
                    .clipShape(Capsule())

                if !notification.isRead {
                    Circle()
                        .fill(notification.type.chipColor)
                        .frame(width: 6, height: 6)
                }

                Spacer()

                Text(NotificationStore.relativeTimeString(from: notification.createdAt))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text(notification.title)
                .font(.system(size: 15, weight: .semibold))

            Text(notification.message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .lightCard()
        .opacity(notification.isRead ? 0.85 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.type.rawValue) notification: \(notification.title). \(notification.message). \(NotificationStore.relativeTimeString(from: notification.createdAt)).")
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockData.notifications) { n in
            NotificationCard(notification: n)
        }
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
