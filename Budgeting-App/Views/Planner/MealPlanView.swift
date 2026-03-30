//
//  MealPlanView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

// MARK: - Meal Plan
struct MealPlanView: View {
    @Environment(\.dismiss) var dismiss
    @State private var activeTab = "meals"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tab switcher
                HStack(spacing: 4) {
                    ForEach([("meals","🍽️ Meal Plan"),("study","📚 Study Costs")],id:\.0) { id,label in
                        Button {
                            withAnimation(.spring(duration: 0.25)) { activeTab = id }
                        } label: {
                            Text(label)
                                .font(.system(size:14,weight:.semibold))
                                .foregroundStyle(activeTab == id ? Color.white : Color.secondary)
                                .frame(maxWidth:.infinity).frame(height:44)
                                .background(activeTab == id ? Color.uniBlue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius:10))
                        }
                    }
                }
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius:14))

                if activeTab == "meals" { mealsTab }
                else { studyTab }
            }
            .padding(.horizontal,16).padding(.top,16).padding(.bottom,40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Campus Life")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
    }

    private var mealsTab: some View {
        VStack(spacing:14) {
            // Plan info
            HStack(spacing:12) {
                Text("🎓").font(.system(size:28))
                VStack(alignment:.leading,spacing:3) {
                    Text("Gold Meal Plan").font(.system(size:15,weight:.semibold))
                    Text("58 days left in semester").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                }
                Spacer()
                Text("58d").font(.system(size:12,weight:.bold)).foregroundStyle(Color.uniBlue)
                    .padding(.horizontal,8).padding(.vertical,4).background(Color.uniBlue.opacity(0.1)).clipShape(Capsule())
            }
            .padding(16).lightCard()

            // Swipes card
            VStack(spacing:14) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Meal Swipes").font(.system(size:13)).foregroundStyle(Color.white.opacity(0.9))
                        Text("63").font(.system(size:40,weight:.bold)).foregroundStyle(Color.white)
                        Text("remaining").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment:.trailing,spacing:4) {
                        Text("This Week").font(.system(size:12)).foregroundStyle(Color.white.opacity(0.9))
                        Text("9/14").font(.system(size:22,weight:.semibold)).foregroundStyle(Color.white)
                    }
                }
                UniProgressBar(progress:0.42, color:.white, height:8)
                Text("💡 Use ~1.8 swipes/day to last the semester")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(LinearGradient.amberGrad)
            .clipShape(RoundedRectangle(cornerRadius:18))

            // Dining dollars + flex
            HStack(spacing:12) {
                VStack(alignment:.leading,spacing:8) {
                    Text("Dining Dollars").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text("Rs.2,655").font(.system(size:20,weight:.bold)).foregroundStyle(Color.income)
                    UniProgressBar(progress:0.47,color:Color.income,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).lightCard()
                VStack(alignment:.leading,spacing:8) {
                    Text("Flex Points").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.secondary)
                    Text("Rs.1,217").font(.system(size:20,weight:.bold)).foregroundStyle(Color.uniBlue)
                    UniProgressBar(progress:0.39,color:Color.uniBlue,height:6)
                }
                .padding(16).frame(maxWidth:.infinity).lightCard()
            }

            InsightCard(emoji:"⚠️",title:"Low Swipes Alert",
                        message:"Running low on meal swipes. Consider using dining dollars.",
                        bgColor:Color.expense.opacity(0.08),borderColor:Color.expense.opacity(0.2))
        }
    }

    private var studyTab: some View {
        VStack(spacing:14) {
            VStack(spacing:8) {
                Text("Study Expenses This Month").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.9))
                Text("Rs.4,965").font(.system(size:36,weight:.bold)).foregroundStyle(Color.white)
                Text("5 transactions").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.8))
            }
            .frame(maxWidth:.infinity).padding(24)
            .background(LinearGradient.purpleGrad)
            .clipShape(RoundedRectangle(cornerRadius:18))

            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:4),spacing:10) {
                ForEach([("🖨️","Printing"),("📚","Books"),("👨‍🏫","Tutoring"),("📝","Supplies")],id:\.0) { emoji,label in
                    VStack(spacing:6) {
                        Text(emoji).font(.system(size:22))
                        Text(label).font(.system(size:11,weight:.medium)).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth:.infinity).padding(.vertical,14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius:12))
                }
            }

            InsightCard(emoji:"💡",title:"Save on Textbooks",
                        message:"Check the library reserve or rent from Chegg before buying new textbooks!",
                        bgColor:Color.income.opacity(0.08),borderColor:Color.income.opacity(0.2))
        }
    }
}

#Preview("Meal Plan") { NavigationStack { MealPlanView() } }
