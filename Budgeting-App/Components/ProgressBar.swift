//
//  ProgressBar.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI

/// Animated capsule progress bar.
/// Colour is passed in — caller decides safe/warning/danger.
struct UniProgressBar: View {
    let progress: Double      // 0.0 – 1.0
    let color: Color
    var height: CGFloat = 8
    var animates: Bool  = true

    private var safeProgress: Double {
        guard progress.isFinite else { return 0 }
        return max(0, min(progress, 1.0))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: height)

                Capsule()
                    .fill(color)
                    .frame(
                        width: max(geo.size.width * safeProgress, height),
                        height: height
                    )
                    .animation(
                        animates ? .spring(duration: 0.6) : nil,
                        value: safeProgress
                    )
            }
        }
        .frame(height: height)
        .accessibilityValue("\(Int(safeProgress * 100)) percent")
    }
}

#Preview {
    VStack(spacing: 16) {
        UniProgressBar(progress: 0.35, color: .uniBlue)
        UniProgressBar(progress: 0.78, color: .uniAmber)
        UniProgressBar(progress: 1.05, color: .expense)
        UniProgressBar(progress: 0.5,  color: .uniGreen, height: 12)
    }
    .padding()
}
