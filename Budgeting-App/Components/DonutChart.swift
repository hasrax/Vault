//
//  DonutChart.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Three-segment donut chart matching the React PieChart3D design.
/// Segments: Needs (blue) / Wants (purple) / Savings (green).
struct DonutChart: View {
    var needs:    Double   // percentage 0–100
    var wants:    Double
    var savings:  Double
    var centerText: String
    var centerSub:  String

    // ── internals ──────────────────────────────────────────────────────────
    private struct Seg { let value: Double; let color: Color }

    private var segments: [Seg] {
        [Seg(value: needs, color: .needsBlue),
         Seg(value: wants, color: .wantsPurple),
         Seg(value: savings, color: .savingsGreen)]
    }
    private var total: Double { segments.reduce(0) { $0 + $1.value } }

    private func cumulative(before idx: Int) -> Double {
        (0..<idx).reduce(0) { $0 + segments[$1].value }
    }
    private func startFraction(_ idx: Int) -> Double {
        total > 0 ? cumulative(before: idx) / total : 0
    }
    private func endFraction(_ idx: Int) -> Double {
        total > 0 ? (cumulative(before: idx) + segments[idx].value) / total : 0
    }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 22)

            // Coloured arcs
            ForEach(segments.indices, id: \.self) { i in
                Circle()
                    .trim(from: startFraction(i), to: endFraction(i))
                    .stroke(
                        segments[i].color,
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8).delay(Double(i) * 0.1), value: needs)
            }

            // Centre labels
            VStack(spacing: 2) {
                Text(centerText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(centerSub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 130, height: 130)
        .accessibilityLabel("Budget donut chart: Needs \(Int(needs))%, Wants \(Int(wants))%, Savings \(Int(savings))%")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DonutChart(needs: 50, wants: 25, savings: 25,
                   centerText: "Rs.45k", centerSub: "Monthly")
    }
}
