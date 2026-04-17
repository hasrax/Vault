//
//   DesignSystem.swift.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Combine

// MARK: - Brand Colours
extension Color {
    static let uniBlue    = Color(hex: "#1E3A8A")
    static let uniPurple  = Color(hex: "#8B5CF6")
    static let uniGreen   = Color(hex: "#22C55E")
    static let uniRed     = Color(hex: "#DC2626")
    static let uniOrange  = Color(hex: "#F97316")
    static let uniAmber   = Color(hex: "#F59E0B")
    static let uniTeal    = Color(hex: "#14B8A6")
    static let uniPink    = Color(hex: "#EC4899")

    // Semantic
    static let income     = Color(hex: "#22C55E")
    static let expense    = Color(hex: "#B91C1C")
    static let warning    = Color(hex: "#F59E0B")

    // Header
    static let headerDark = Color(hex: "#1A1A1A")
    static let headerMid  = Color(hex: "#0A0A0A")

    // App surfaces
    static let appBgTop     = Color(hex: "#0B1020")
    static let appBgBottom  = Color(hex: "#101827")
    static let appSurface   = Color(hex: "#141C2E")
    static let appSurface2  = Color(hex: "#1B2438")
    static let appStroke    = Color.white.opacity(0.08)

    // CTA
    static let ctaBlue      = Color(hex: "#1E3A8A")

    // Category
    static let needsBlue    = Color(hex: "#3B82F6")
    static let wantsPurple  = Color(hex: "#8B5CF6")
    static let savingsGreen = Color(hex: "#22C55E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:     Double(r)/255,
                  green:   Double(g)/255,
                  blue:    Double(b)/255,
                  opacity: Double(a)/255)
    }

    func toHex() -> String? {
        guard let c = UIColor(self).cgColor.components, c.count >= 3 else { return nil }
        return String(format: "%02X%02X%02X",
                      Int(c[0]*255), Int(c[1]*255), Int(c[2]*255))
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGrad  = LinearGradient(colors:[Color(hex:"#1E3A8A"),Color(hex:"#1D4ED8")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let purpleGrad   = LinearGradient(colors:[Color(hex:"#8B5CF6"),Color(hex:"#7C3AED")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let greenGrad    = LinearGradient(colors:[Color(hex:"#22C55E"),Color(hex:"#16A34A")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let amberGrad    = LinearGradient(colors:[Color(hex:"#F59E0B"),Color(hex:"#D97706")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let headerGrad   = LinearGradient(colors:[Color(hex:"#1A1A1A"),Color(hex:"#0A0A0A")], startPoint:.top,        endPoint:.bottom)
    static let tealGrad     = LinearGradient(colors:[Color(hex:"#14B8A6"),Color(hex:"#0F766E")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let pinkGrad     = LinearGradient(colors:[Color(hex:"#EC4899"),Color(hex:"#DB2777")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let orangeGrad   = LinearGradient(colors:[Color(hex:"#F97316"),Color(hex:"#EA580C")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let semesterGrad = LinearGradient(colors:[Color(hex:"#4C1D95"),Color(hex:"#7C3AED")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let workGrad     = LinearGradient(colors:[Color(hex:"#0F766E"),Color(hex:"#14B8A6")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let splitGrad    = LinearGradient(colors:[Color(hex:"#7C3AED"),Color(hex:"#8B5CF6")], startPoint:.topLeading, endPoint:.bottomTrailing)
    static let goldGrad     = LinearGradient(colors:[Color(hex:"#F59E0B"),Color(hex:"#FBBF24")], startPoint:.topLeading, endPoint:.bottomTrailing)

    // App background
    static let appBackgroundGrad = LinearGradient(colors:[Color.appBgTop, Color.appBgBottom], startPoint:.topLeading, endPoint:.bottomTrailing)

    // CTA
    static let ctaGrad = LinearGradient(colors:[Color(hex:"#0F1B3A"), Color(hex:"#1E3A8A")], startPoint:.topLeading, endPoint:.bottomTrailing)
}

// MARK: - Budget Category
enum BudgetCategory: String, CaseIterable, Identifiable, Codable {
    case needs   = "Needs"
    case wants   = "Wants"
    case savings = "Savings"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .needs:   return .needsBlue
        case .wants:   return .wantsPurple
        case .savings: return .savingsGreen
        }
    }
    var gradient: LinearGradient {
        switch self {
        case .needs:   return .primaryGrad
        case .wants:   return .purpleGrad
        case .savings: return .greenGrad
        }
    }
    var icon: String {
        switch self {
        case .needs:   return "house.fill"
        case .wants:   return "fork.knife"
        case .savings: return "banknote.fill"
        }
    }
    var emoji: String {
        switch self {
        case .needs:   return "⏰"
        case .wants:   return "✨"
        case .savings: return "🎯"
        }
    }
    var subtitle: String {
        switch self {
        case .needs:   return "Rent, Bills, Groceries"
        case .wants:   return "Food, Entertainment, Shopping"
        case .savings: return "Emergency Fund, Goals"
        }
    }
    var percentage: Double {
        switch self {
        case .needs:   return 0.50
        case .wants:   return 0.25
        case .savings: return 0.25
        }
    }
    var bgGradient: LinearGradient {
        switch self {
        case .needs:
            return LinearGradient(colors:[Color(hex:"#DBEAFE"),Color(hex:"#BFDBFE")], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .wants:
            return LinearGradient(colors:[Color(hex:"#F3E8FF"),Color(hex:"#E9D5FF")], startPoint:.topLeading, endPoint:.bottomTrailing)
        case .savings:
            return LinearGradient(colors:[Color(hex:"#DCFCE7"),Color(hex:"#BBF7D0")], startPoint:.topLeading, endPoint:.bottomTrailing)
        }
    }
}

// MARK: - View Modifiers

/// Glass card — for use on dark/header backgrounds
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.08))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

/// Light card — for use on light/grouped backgrounds
struct LightCardModifier: ViewModifier {
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func glassCard() -> some View            { modifier(GlassCardModifier()) }
    func lightCard(_ r: CGFloat = 16) -> some View { modifier(LightCardModifier(radius: r)) }
    func appBackground() -> some View        { modifier(AppBackgroundModifier()) }
}

// MARK: - Status Bar Style
struct StatusBarStyleSetter: UIViewControllerRepresentable {
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

extension View {
    func statusBarStyle(_ style: UIStatusBarStyle) -> some View {
        background(StatusBarStyleSetter(style: style))
    }
}

// MARK: - App Background
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1020"), Color(hex: "#0F1626"), Color(hex: "#101827")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.uniBlue.opacity(0.30), Color.clear],
                           startPoint: .topTrailing, endPoint: .bottom)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.clear, Color.uniPurple.opacity(0.26)],
                           startPoint: .top, endPoint: .bottomLeading)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.black.opacity(0.35), Color.clear],
                           startPoint: .bottom, endPoint: .center)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Auth / Onboarding Background
struct AuthBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F8FAFC"), Color(hex: "#EDF2F7"), Color(hex: "#E2E8F0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.uniBlue.opacity(0.18), Color.clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 380
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.clear, Color.uniBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Home Header Background
struct HomeHeaderBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#060914"), Color(hex: "#0B1426"), Color(hex: "#0F1B3A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.uniBlue.opacity(0.22), Color.clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 360
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

private struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppBackground()
            content
        }
    }
}

// MARK: - Rounded Corner Shape (for clipping specific corners)
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

// MARK: - Currency Formatting
extension Double {
    /// "Rs. 12,500"
    var currencyRS: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        let str = fmt.string(from: NSNumber(value: self)) ?? "0"
        return "Rs. \(str)"
    }
    /// "Rs.12k"
    var shortCurrency: String {
        self >= 1000
            ? String(format: "Rs.%.0fk", self / 1000)
            : "Rs.\(Int(self))"
    }
}

// MARK: - Font Extensions
extension Font {
    static let headlineLg   = Font.system(size: 22, weight: .bold)
    static let headlineMd   = Font.system(size: 18, weight: .semibold)
    static let headlineSm   = Font.system(size: 15, weight: .semibold)
    static let bodyMd       = Font.system(size: 15, weight: .regular)
    static let bodySm       = Font.system(size: 13, weight: .regular)
    static let caption1     = Font.system(size: 12, weight: .medium)
    static let caption2Text = Font.system(size: 11, weight: .regular)
    static let labelFont    = Font.system(size: 11, weight: .semibold)
}

// MARK: - Missing Gradients
extension LinearGradient {
    static let savingsGoldGrad = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
