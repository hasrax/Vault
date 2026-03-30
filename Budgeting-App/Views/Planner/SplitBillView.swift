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
    @State private var amountText = ""
    @State private var description = ""
    @State private var splitMethod = "equal"
    @State private var includeSelf = true
    @State private var selectedPeople: Set<UUID> = []
    private let roommates = MockData.roommates

    private var amount: Double { Double(amountText) ?? 0 }
    private var totalPeople: Int { selectedPeople.count + (includeSelf ? 1 : 0) }
    private var splitAmount: Double { totalPeople > 0 ? amount / Double(totalPeople) : 0 }

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
                        ForEach([("equal","⚖️","Equal"),("custom","✏️","Custom"),("percentage","📊","Percent")],id:\.0) { id,emoji,label in
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

                    // Self
                    personRow(avatar:"🎓",name:"You",color:Color.uniBlue,isSelected:includeSelf) {
                        includeSelf.toggle()
                    }

                    ForEach(roommates) { r in
                        let sel = selectedPeople.contains(r.id)
                        personRow(avatar:r.avatar,name:r.name,color:r.color,isSelected:sel) {
                            if sel { selectedPeople.remove(r.id) }
                            else   { selectedPeople.insert(r.id) }
                        }
                    }
                }

                // Preview
                if amount > 0 && totalPeople > 0 {
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
                } label: {
                    Text("Create Split")
                        .font(.system(size:16,weight:.semibold)).foregroundStyle(Color.white)
                        .frame(maxWidth:.infinity).frame(height:52)
                        .background(amount > 0 && totalPeople > 0 ? LinearGradient.ctaGrad : LinearGradient(colors:[Color.white.opacity(0.1)],startPoint:.leading,endPoint:.trailing))
                        .clipShape(RoundedRectangle(cornerRadius:14))
                }
                .disabled(amount == 0 || totalPeople == 0)
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
}

#Preview("Split") { NavigationStack { SplitBillView() } }
