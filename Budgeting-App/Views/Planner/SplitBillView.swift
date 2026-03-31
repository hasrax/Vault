//
//  SplitBillView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Split Bill
struct SplitBillView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var amountText = ""
    @State private var description = ""
    @State private var splitMethod = "equal"
    @State private var includeSelf = true
    @State private var selectedUsers: [UserProfile] = []
    @State private var searchQuery = ""
    @State private var searchResults: [UserProfile] = []
    @State private var searchError = ""
    @State private var isSearching = false
    @State private var customShares: [String: String] = [:]

    private let splitOptions: [(id: String, emoji: String, label: String)] = [
        ("equal", "⚖️", "Equal"),
        ("custom", "✏️", "Custom")
    ]

    private var amount: Double { Double(amountText) ?? 0 }
    private var totalPeople: Int { selectedUsers.count + (includeSelf ? 1 : 0) }
    private var splitAmount: Double { totalPeople > 0 ? amount / Double(totalPeople) : 0 }
    private var currentUserId: String { appState.currentUser?.id ?? "" }
    private var currentUserName: String { appState.currentUser?.name ?? "You" }
    private var currentUserEmail: String { appState.currentUser?.email ?? "" }
    private var selfKey: String { currentUserId.isEmpty ? "self" : currentUserId }
    private var customTotal: Double {
        let selfShare = includeSelf ? (Double(customShares[selfKey] ?? "") ?? 0) : 0
        let others = selectedUsers.reduce(0.0) { sum, user in
            sum + (Double(customShares[user.id] ?? "") ?? 0)
        }
        return selfShare + others
    }

    private var currentUserShare: Double {
        if splitMethod == "custom" {
            return includeSelf ? (Double(customShares[selfKey] ?? "") ?? 0) : 0
        }
        return splitAmount
    }

    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
            AmountInput(text: $amountText, accentColor: Color.uniBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Amount + description
                amountInputSection

                VStack(alignment: .leading, spacing: 8) {
                    Text("What's this for?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primary)
                    TextField("e.g. Dinner, Rent, Utilities", text: $description)
                        .foregroundStyle(Color.primary)
                        .padding(14)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1))
                }

                // Split method + preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Split Method")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primary)
                    HStack(spacing: 10) {
                        ForEach(splitOptions, id: \.id) { option in
                            Button {
                                splitMethod = option.id
                            } label: {
                                VStack(spacing: 6) {
                                    Text(option.emoji).font(.system(size: 22))
                                    Text(option.label)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(splitMethod == option.id ? Color.uniBlue : Color.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(splitMethod == option.id ? Color.uniBlue.opacity(0.15) : Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(splitMethod == option.id ? Color.uniBlue : Color.clear, lineWidth: 1.5))
                            }
                        }
                    }

                    if amount > 0 && totalPeople > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Split preview")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary)
                            Text("Each pays \(currentUserShare.currencyRS)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.uniBlue)
                            Text("Split between \(totalPeople) people")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondary)
                            if splitMethod == "custom" {
                                Text("Custom total: \(customTotal.currencyRS)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(customTotal == amount ? Color.income : Color.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.uniBlue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.uniBlue.opacity(0.2), lineWidth: 1))
                    }
                }

                // People selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Split with")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primary)

                    HStack(spacing: 8) {
                        TextField("Search by name or email", text: $searchQuery)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(12)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1))
                            .onSubmit { performSearch() }

                        Button {
                            performSearch()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.white)
                                .frame(width: 44, height: 44)
                                .background(Color.uniBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    if isSearching {
                        Text("Searching...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    } else if !searchError.isEmpty {
                        Text(searchError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.expense)
                    }

                    if !searchResults.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(searchResults, id: \.id) { user in
                                Button {
                                    selectedUsers.append(user)
                                    searchResults.removeAll { $0.id == user.id }
                                    searchQuery = ""
                                    searchError = ""
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle().fill(Color.uniBlue.opacity(0.2)).frame(width: 34, height: 34)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.primary)
                                            Text(user.email)
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color.secondary)
                                        }
                                        Spacer()
                                        Text("Add")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Color.uniBlue)
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1))
                                }
                            }
                        }
                    }

                    // Self
                    personRow(avatar: "🎓", name: "You", color: Color.uniBlue, isSelected: includeSelf) {
                        includeSelf.toggle()
                    }

                    ForEach(selectedUsers, id: \.id) { user in
                        personRow(avatar: "👤", name: user.name, color: Color.uniBlue, isSelected: true) {
                            selectedUsers.removeAll { $0.id == user.id }
                            customShares[user.id] = nil
                        }
                    }
                }

                if splitMethod == "custom" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom shares")
                            .font(.system(size:14,weight:.medium))
                            .foregroundStyle(Color.primary)

                        if includeSelf {
                            shareRow(name: "You", binding: shareBinding(for: selfKey))
                        }
                        ForEach(selectedUsers, id: \.id) { user in
                            shareRow(name: user.name, binding: shareBinding(for: user.id))
                        }

                    }
                }

                Button {
                    createSplitBill()
                } label: {
                    Text("Send Request")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(amount > 0 && totalPeople > 0 ? LinearGradient.ctaGrad : LinearGradient(colors:[Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(amount == 0 || totalPeople == 0)

                if !appState.splitBills.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Requests")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.primary)

                        ForEach(appState.splitBills) { bill in
                            splitBillCard(bill)
                        }
                    }
                }
            }
            .padding(20).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Split Bill")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                searchResults = []
                searchError = ""
                isSearching = false
                return
            }
        }
    }

    private func personRow(avatar:String,name:String,color:Color,isSelected:Bool,toggle:@escaping()->Void) -> some View {
        Button(action:toggle) {
            HStack(spacing:14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width:44,height:44)
                    Text(avatar).font(.system(size:20))
                }
                VStack(alignment:.leading,spacing:2) {
                    Text(name).font(.system(size:15,weight:.medium)).foregroundStyle(Color.primary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.uniPurple : Color(UIColor.tertiarySystemFill))
                        .frame(width:24,height:24)
                    if isSelected {
                        Image(systemName:"checkmark").font(.system(size:11,weight:.bold)).foregroundStyle(Color.white)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color.uniPurple.opacity(0.1) : Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius:14))
            .overlay(RoundedRectangle(cornerRadius:14)
                .stroke(isSelected ? Color.uniPurple : Color.black.opacity(0.06),lineWidth:isSelected ? 1.5 : 1))
        }
    }

    private func shareRow(name: String, binding: Binding<String>) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            TextField("0", text: binding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius:12))
        .overlay(RoundedRectangle(cornerRadius:12).stroke(Color.black.opacity(0.06),lineWidth:1))
    }

    private func shareBinding(for key: String) -> Binding<String> {
        Binding(
            get: { customShares[key] ?? "" },
            set: { customShares[key] = $0 }
        )
    }


    private func createSplitBill() {
        guard !currentUserId.isEmpty else { return }
        let title = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? "Split bill" : title
        let method: SplitMethod = splitMethod == "custom" ? .custom : .equal

        var participants: [SplitParticipant] = []

        let myShare: Double
        if includeSelf {
            myShare = method == .equal ? splitAmount : remainingForSelf
        } else {
            myShare = 0
        }
        let me = SplitParticipant(
            userId: currentUserId,
            name: currentUserName,
            email: currentUserEmail,
            shareAmount: myShare,
            status: .accepted,
            isCreator: true
        )
        participants.append(me)

        for user in selectedUsers {
            let share = method == .equal ? splitAmount : (Double(customShares[user.id] ?? "") ?? 0)
            let p = SplitParticipant(
                userId: user.id,
                name: user.name,
                email: user.email,
                shareAmount: share,
                status: .invited,
                isCreator: false
            )
            participants.append(p)
        }

        appState.createSplitBill(
            title: finalTitle,
            totalAmount: amount,
            splitMethod: method,
            participants: participants
        )

        amountText = ""
        description = ""
        splitMethod = "equal"
        includeSelf = true
        selectedUsers = []
        customShares = [:]
    }

    private func splitBillCard(_ bill: SplitBill) -> some View {
        let me = bill.participants.first { $0.userId == currentUserId }
        let isCreator = bill.createdBy == currentUserId
        let confirmedCount = bill.participants.filter { !$0.isCreator && $0.status == .accepted }.count
        let invitedCount = bill.participants.filter { !$0.isCreator }.count
        let allPaid = bill.participants
            .filter { !$0.isCreator && $0.status != .declined }
            .allSatisfy { $0.status == .paid }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.title)
                        .font(.system(size:15,weight:.semibold))
                    Text(bill.totalAmount.currencyRS)
                        .font(.system(size:12,weight:.medium))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Text(bill.status.rawValue.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal,8).padding(.vertical,4)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            if let me = me {
                Text("Your share: \(me.shareAmount.currencyRS)")
                    .font(.system(size:12,weight:.medium))
                    .foregroundStyle(Color.secondary)
            }

            if isCreator {
                Text("Confirmed: \(confirmedCount)/\(invitedCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
            } else if let me = me, me.status == .accepted {
                Text("Status: Confirmed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bill.participants.filter { !$0.isCreator }) { participant in
                    HStack {
                        Text(participant.name)
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        statusBadge(participant.status)
                    }
                }
            }

            HStack(spacing: 10) {
                if bill.status == .settled {
                    Text("Settled")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.income)
                } else if isCreator {
                    if allPaid {
                        Button("Settle") {
                            appState.settleSplitBill(bill)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Waiting for payments")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                } else if let me = me {
                    switch me.status {
                    case .invited:
                        Button("Accept") { appState.acceptSplitBill(bill) }
                            .buttonStyle(.borderedProminent)
                        Button("Decline") { appState.declineSplitBill(bill) }
                            .buttonStyle(.bordered)
                    case .accepted:
                        Button("Mark Paid") { appState.markSplitBillPaid(bill) }
                            .buttonStyle(.borderedProminent)
                    case .paid:
                        Text("Paid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.income)
                    case .declined:
                        Text("Declined")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .padding(16)
        .lightCard()
    }

    private func statusBadge(_ status: SplitParticipantStatus) -> some View {
        Text(statusLabel(status))
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusLabel(_ status: SplitParticipantStatus) -> String {
        switch status {
        case .invited: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .paid: return "Paid"
        }
    }

    private func statusColor(_ status: SplitParticipantStatus) -> Color {
        switch status {
        case .invited: return Color.warning
        case .accepted: return Color.uniBlue
        case .declined: return Color.expense
        case .paid: return Color.income
        }
    }

    private func performSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchError = ""

        if trimmed.contains("@") {
            appState.findUserByEmail(trimmed) { emailResult in
                DispatchQueue.main.async {
                    switch emailResult {
                    case .success(let user):
                        if !selectedUsers.contains(where: { $0.id == user.id }) {
                            searchResults = [user]
                            searchError = ""
                        }
                        isSearching = false
                    case .failure:
                        self.performNameSearch(query: trimmed)
                    }
                }
            }
            return
        }

        performNameSearch(query: trimmed)
    }

    private func performNameSearch(query: String) {
        appState.searchUsers(query: query) { result in
            DispatchQueue.main.async {
                isSearching = false
                switch result {
                case .success(let users):
                    let filtered = users.filter { user in
                        user.id != currentUserId && !selectedUsers.contains(where: { $0.id == user.id })
                    }
                    searchResults = filtered
                    searchError = filtered.isEmpty ? "No matches" : ""
                case .failure(let error):
                    searchResults = []
                    searchError = error.localizedDescription
                }
            }
        }
    }
}

#Preview("Split") { NavigationStack { SplitBillView().environmentObject(AppState()) } }
