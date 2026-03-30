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
    @State private var inviteEmail = ""
    @State private var inviteError = ""
    @State private var isInviting = false
    @State private var customShares: [String: String] = [:]

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

    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Total Amount")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
            AmountInput(text: $amountText, accentColor: Color.uniPurple)
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
            VStack(spacing:24) {
            // Amount input
            amountInputSection

                // Description
                VStack(alignment:.leading,spacing:8) {
                    Text("What's this for?").font(.system(size:14,weight:.medium)).foregroundStyle(Color.primary)
                    TextField("e.g. Dinner, Rent, Utilities",text:$description)
                        .foregroundStyle(Color.primary)
                        .padding(14)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius:12))
                        .overlay(RoundedRectangle(cornerRadius:12).stroke(Color.black.opacity(0.06),lineWidth:1))
                }

                // Split method
                VStack(alignment:.leading,spacing:10) {
                    Text("Split Method").font(.system(size:14,weight:.medium)).foregroundStyle(Color.primary)
                    HStack(spacing:10) {
                        ForEach([("equal","⚖️","Equal"),("custom","✏️","Custom")],id:\.0) { id,emoji,label in
                            Button {
                                splitMethod = id
                            } label: {
                                VStack(spacing:6) {
                                    Text(emoji).font(.system(size:22))
                                    Text(label).font(.system(size:11,weight:.medium)).foregroundStyle(splitMethod==id ? Color.uniPurple : Color.secondary)
                                }
                                .frame(maxWidth:.infinity).padding(.vertical,14)
                                .background(splitMethod == id ? Color.uniPurple.opacity(0.15) : Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius:12))
                                .overlay(RoundedRectangle(cornerRadius:12)
                                    .stroke(splitMethod==id ? Color.uniPurple : Color.clear,lineWidth:1.5))
                            }
                        }
                    }
                }

                // People selection
                VStack(alignment:.leading,spacing:10) {
                    Text("Split with").font(.system(size:14,weight:.medium)).foregroundStyle(Color.primary)

                    HStack(spacing: 10) {
                        TextField("Add by email", text: $inviteEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(12)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius:12))
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(Color.black.opacity(0.06),lineWidth:1))

                        Button {
                            addInviteByEmail()
                        } label: {
                            if isInviting {
                                ProgressView().tint(.white)
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "plus")
                                    .foregroundStyle(Color.white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .background(Color.uniPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !inviteError.isEmpty {
                        Text(inviteError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.expense)
                    }

                    // Self
                    personRow(avatar:"🎓",name:"You",color:Color.uniBlue,isSelected:includeSelf) {
                        includeSelf.toggle()
                    }

                    ForEach(selectedUsers, id: \.id) { user in
                        personRow(avatar:"👤",name:user.name,color:Color.uniPurple,isSelected:true) {
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

                        Text("Custom total: \(customTotal.currencyRS)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(customTotal == amount ? Color.income : Color.secondary)
                    }
                }

                // Preview
                if amount > 0 && totalPeople > 0 && splitMethod == "equal" {
                    VStack(spacing:8) {
                        Text("Each person pays").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                        Text(splitAmount.currencyRS)
                            .font(.system(size:32,weight:.bold,design:.rounded)).foregroundStyle(Color.uniPurple)
                        Text("Split between \(totalPeople) people")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth:.infinity).padding(20)
                    .background(Color.uniPurple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius:16))
                    .overlay(RoundedRectangle(cornerRadius:16).stroke(Color.uniPurple.opacity(0.2),lineWidth:1))
                }

                Button {
                    createSplitBill()
                } label: {
                    Text("Create Split")
                        .font(.system(size:16,weight:.semibold)).foregroundStyle(Color.white)
                        .frame(maxWidth:.infinity).frame(height:52)
                        .background(amount > 0 && totalPeople > 0 ? LinearGradient.ctaGrad : LinearGradient(colors:[Color.white.opacity(0.1)],startPoint:.leading,endPoint:.trailing))
                        .clipShape(RoundedRectangle(cornerRadius:14))
                }
                .disabled(amount == 0 || totalPeople == 0)

                if !appState.splitBills.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your split bills")
                            .font(.system(size:14,weight:.medium))
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

    private func addInviteByEmail() {
        let email = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return }
        if email == currentUserEmail.lowercased() {
            inviteError = "That is your email."
            return
        }
        inviteError = ""
        isInviting = true
        appState.findUserByEmail(email) { result in
            DispatchQueue.main.async {
                isInviting = false
                switch result {
                case .success(let user):
                    if selectedUsers.contains(where: { $0.id == user.id }) {
                        inviteError = "User already added."
                    } else {
                        selectedUsers.append(user)
                        inviteEmail = ""
                    }
                case .failure:
                    inviteError = "No account found for that email."
                }
            }
        }
    }

    private func createSplitBill() {
        guard !currentUserId.isEmpty else { return }
        let title = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? "Split bill" : title
        let method: SplitMethod = splitMethod == "custom" ? .custom : .equal

        var participants: [SplitParticipant] = []

        let myShare: Double
        if includeSelf {
            myShare = method == .equal ? splitAmount : (Double(customShares[selfKey] ?? "") ?? 0)
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
}

#Preview("Split") { NavigationStack { SplitBillView().environmentObject(AppState()) } }
