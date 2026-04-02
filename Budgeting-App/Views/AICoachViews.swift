//
//  AICoachViews.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import Combine
import PhotosUI
import Vision
import VisionKit

// MARK: - AI Coach View
struct AICoachView: View {
    @State private var messages      = MockData.coachMessages
    @State private var inputText     = ""
    @State private var isThinking    = false
    @State private var showAffordSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                riskDashboard
                Divider()
                chatArea
                inputBar
            }
            .background(Color.clear)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAffordSheet = true
                    } label: {
                        Label("Can I afford?", systemImage: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showAffordSheet) { CanIAffordSheet() }
        }
    }

    // MARK: - Risk Dashboard
    private var riskDashboard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                InsightCard(
                    emoji: "⚠️", title: "Needs over budget",
                    message: "Rs.3,000 over limit this month",
                    bgColor: Color.expense.opacity(0.08),
                    borderColor: Color.expense.opacity(0.2)
                ).frame(width: 180)

                InsightCard(
                    emoji: "✅", title: "Wants on track",
                    message: "61% remaining — Rs.6,860 left",
                    bgColor: Color.income.opacity(0.08),
                    borderColor: Color.income.opacity(0.2)
                ).frame(width: 180)

                InsightCard(
                    emoji: "📈", title: "Save more this week",
                    message: "Behind by Rs.1,200",
                    bgColor: Color.warning.opacity(0.08),
                    borderColor: Color.warning.opacity(0.2)
                ).frame(width: 180)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Chat
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        chatBubble(msg).id(msg.id)
                    }
                    if isThinking {
                        HStack(alignment: .bottom, spacing: 8) {
                            coachAvatar
                            ThinkingDots()
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask your coach anything...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button { send() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.isEmpty ? Color.secondary : Color.uniBlue)
            }
            .disabled(inputText.isEmpty || isThinking)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Coach Avatar
    private var coachAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.uniBlue.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14))
                .foregroundStyle(Color.uniBlue)
        }
    }

    // MARK: - Chat Bubble
    @ViewBuilder
    private func chatBubble(_ msg: CoachMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !msg.isFromUser { coachAvatar }

            VStack(alignment: msg.isFromUser ? .trailing : .leading, spacing: 4) {
                if let risk = msg.riskLevel, !msg.isFromUser {
                    HStack(spacing: 4) {
                        Image(systemName: risk.icon).font(.system(size: 11))
                        Text(risk.label).font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(risk.color)
                }

                Text(msg.text)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(msg.isFromUser ? Color.uniBlue : Color(UIColor.systemBackground))
                    .foregroundStyle(msg.isFromUser ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.72,
                alignment: msg.isFromUser ? .trailing : .leading
            )

            if msg.isFromUser { Spacer() }
        }
        .frame(maxWidth: .infinity, alignment: msg.isFromUser ? .trailing : .leading)
    }

    // MARK: - Send
    private func send() {
        let q = inputText
        messages.append(CoachMessage(text: q, isFromUser: true))
        inputText   = ""
        isThinking  = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isThinking = false
            messages.append(generateResponse(for: q))
        }
    }

    private func generateResponse(for query: String) -> CoachMessage {
        let q = query.lowercased()
        if q.contains("afford") || q.contains("buy") {
            return CoachMessage(
                text: "Your Wants budget is 39% used with Rs.6,860 remaining. Under Rs.1,000 is safe — over Rs.3,000 I'd wait until next week.",
                isFromUser: false, riskLevel: .caution
            )
        } else if q.contains("save") || q.contains("saving") {
            return CoachMessage(
                text: "You've saved Rs.5,000 this month — 44% of your savings target. Put aside Rs.1,500 before the weekend to stay on track!",
                isFromUser: false, riskLevel: .safe
            )
        } else {
            return CoachMessage(
                text: "Your Needs category is Rs.3,000 over budget, mainly from rent and groceries. Try reducing dining out this week to compensate.",
                isFromUser: false, riskLevel: .danger
            )
        }
    }
}

// MARK: - Can I Afford Sheet
struct CanIAffordSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var amount   = ""
    @State private var category: BudgetCategory = .wants
    @State private var result: AffordResult? = nil

    enum AffordResult {
        case yes, maybe, no
        var color:   Color  { self == .yes ? Color.income : self == .maybe ? Color.warning : Color.expense }
        var icon:    String { self == .yes ? "checkmark.circle.fill" : self == .maybe ? "exclamationmark.triangle.fill" : "xmark.circle.fill" }
        var message: String {
            switch self {
            case .yes:   return "Yes, you can afford this — it fits within your budget."
            case .maybe: return "Be careful — this brings you close to your limit."
            case .no:    return "Not recommended — you're already at or over your limit."
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("How much do you want to spend?") {
                    HStack {
                        Text("Rs.")
                        TextField("Amount", text: $amount)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Which category?") {
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Check") { checkAfford() }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(Color.uniBlue)
                        .fontWeight(.semibold)
                }
                if let r = result {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: r.icon)
                                .font(.system(size: 44))
                                .foregroundStyle(r.color)
                            Text(r.message)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Can I afford this?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func checkAfford() {
        guard let value = Double(amount) else { return }
        guard let limit = MockData.budgetLimits.first(where: { $0.category == category }) else { return }
        if value <= limit.remaining * 0.5      { result = .yes }
        else if value <= limit.remaining       { result = .maybe }
        else                                   { result = .no }
    }
}

// MARK: - Receipt Scanner
struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScanning      = false
    @State private var scannedAmount: Double? = nil
    @State private var showAdd         = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var receiptImageUrl: String?
    @State private var receiptImageBase64: String?
    @State private var isUploading = false
    @State private var uploadError = ""
    @State private var saveReceiptImage = true
    @State private var useLiveScanner = false
    @State private var liveScanText = ""
    @State private var showFullScreenScanner = false
    @State private var showImagePreview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Text("Scan mode")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Picker("Scan mode", selection: $useLiveScanner) {
                        Text("Gallery").tag(false)
                        Text("Live Camera").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                .padding(.horizontal, 4)

                cameraFrame
                howItWorksCard
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationTitle("Receipt Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView(
                prefillAmount: scannedAmount,
                prefillReceiptUrl: receiptImageUrl,
                prefillReceiptBase64: receiptImageBase64
            )
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            ReceiptImagePreviewView(
                image: receiptImage,
                onCancel: {
                    showImagePreview = false
                },
                onScan: {
                    if let image = receiptImage {
                        recognizeText(in: image)
                    }
                    showImagePreview = false
                }
            )
        }
        .fullScreenCover(isPresented: $showFullScreenScanner) {
            LiveScannerFullScreenView(
                text: $liveScanText,
                onCancel: { showFullScreenScanner = false },
                onUseText: {
                    scanLiveText()
                    showFullScreenScanner = false
                }
            )
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(item: newItem)
        }
    }

    // MARK: - Camera Frame
    private var cameraFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 300)

            if let img = receiptImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                    .overlay(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            if useLiveScanner {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerView(text: $liveScanText)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.badge.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text("Live scan not available")
                            .foregroundStyle(Color.white.opacity(0.7))
                            .font(.subheadline)
                    }
                }
            } else if isScanning {
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Scanning receipt...")
                        .foregroundStyle(Color.white.opacity(0.7))
                        .font(.subheadline)
                }
            } else if let amount = scannedAmount {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.income)
                    Text("Receipt scanned!")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(amount.currencyRS)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.income)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text("Point camera at receipt")
                        .foregroundStyle(Color.white.opacity(0.6))
                        .font(.subheadline)
                    scanCorners
                }
            }
        }
    }

    private var scanCorners: some View {
        ZStack {
            let s: CGFloat = 20
            let t: CGFloat = 3
            let w: CGFloat = 180
            let h: CGFloat = 100
            Path { p in
                p.move(to: CGPoint(x: 0,   y: s)); p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: s, y: 0))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: w,   y: s)); p.addLine(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w-s, y: 0))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: 0,   y: h-s)); p.addLine(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: s, y: h))
            }.stroke(Color.white, lineWidth: t)
            Path { p in
                p.move(to: CGPoint(x: w,   y: h-s)); p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: w-s, y: h))
            }.stroke(Color.white, lineWidth: t)
        }
        .frame(width: 180, height: 100)
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works").font(.system(size: 18, weight: .semibold))
            Label("Pick a receipt photo or use live scan",             systemImage: "1.circle.fill").font(.subheadline)
            Label("Vision reads the total amount automatically",       systemImage: "2.circle.fill").font(.subheadline)
            Label("Transaction is logged straight to your budget",     systemImage: "3.circle.fill").font(.subheadline)
        }
        .padding(16)
        .lightCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Toggle("Save receipt image (compressed)", isOn: $saveReceiptImage)
                .font(.system(size: 13, weight: .medium))

            if isUploading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color.uniBlue)
                    Text("Uploading receipt...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
            } else if !uploadError.isEmpty {
                Text(uploadError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.expense)
            }

            if scannedAmount != nil {
                Button { prepareToAddTransaction() } label: {
                    Label("Log this transaction", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.greenGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if useLiveScanner {
                Button { scanLiveText() } label: {
                    Label("Scan from Live View", systemImage: "text.viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(isScanning
                                    ? LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isScanning)

                Button { showFullScreenScanner = true } label: {
                    Label("Open Full Screen Scanner", systemImage: "viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!(DataScannerViewController.isSupported && DataScannerViewController.isAvailable))
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(scannedAmount == nil ? "Choose Receipt Photo" : "Choose Another",
                          systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(isScanning
                                    ? LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.primaryGrad)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isScanning)
            }
        }
    }

    private func loadPhoto(item: PhotosPickerItem) {
        isScanning = true
        scannedAmount = nil
        uploadError = ""
        receiptImageUrl = nil
        receiptImageBase64 = nil

        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data, let image = UIImage(data: data) else {
                        isScanning = false
                        uploadError = "Unable to load image."
                        return
                    }
                    receiptImage = image
                    isScanning = false
                    showImagePreview = true
                case .failure:
                    isScanning = false
                    uploadError = "Failed to read image."
                }
            }
        }
    }

    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            isScanning = false
            uploadError = "Invalid image."
            return
        }
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isScanning = false
                if let _ = error {
                    self.uploadError = "Text scan failed."
                    return
                }
                let strings = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                self.scannedAmount = extractAmount(from: strings)
                if self.scannedAmount == nil {
                    self.uploadError = "Could not find a total amount."
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func extractAmount(from lines: [String]) -> Double? {
        let lower = lines.map { $0.lowercased() }
        let keywords = ["total", "amount", "subtotal", "balance", "due"]
        let prioritized = lower.filter { line in
            keywords.contains { line.contains($0) }
        }

        let candidates = (prioritized.isEmpty ? lower : prioritized)
            .flatMap { extractNumbers(from: $0) }

        return candidates.max()
    }

    private func extractNumbers(from text: String) -> [Double] {
        let pattern = "([0-9]+(?:[\\.,][0-9]{2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            let raw = text[r].replacingOccurrences(of: ",", with: ".")
            return Double(raw)
        }
    }

    private func prepareToAddTransaction() {
        guard saveReceiptImage, let image = receiptImage else {
            showAdd = true
            return
        }
        uploadError = ""
        if let encoded = ReceiptImageService.encodeReceiptImage(image: image, maxDimension: 640, quality: 0.55) {
            receiptImageBase64 = encoded
            showAdd = true
        } else {
            uploadError = "Unable to save receipt image."
        }
    }

    private func scanLiveText() {
        let lines = liveScanText
            .split(separator: "\n")
            .map { String($0) }
        scannedAmount = extractAmount(from: lines)
        if scannedAmount == nil {
            uploadError = "Could not find a total amount."
        }
    }
}

@available(iOS 16.0, *)
private struct DataScannerView: UIViewControllerRepresentable {
    @Binding var text: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            updateText(items: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate items: [RecognizedItem], allItems: [RecognizedItem]) {
            updateText(items: allItems)
        }

        private func updateText(items: [RecognizedItem]) {
            let lines = items.compactMap { item -> String? in
                if case let .text(textItem) = item { return textItem.transcript }
                return nil
            }
            text.wrappedValue = lines.joined(separator: "\n")
        }
    }
}

private struct LiveScannerFullScreenView: View {
    @Binding var text: String
    var onCancel: () -> Void
    var onUseText: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerView(text: $text)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text("Live scan not available")
                        .foregroundStyle(Color.white.opacity(0.8))
                        .font(.subheadline)
                    Button("Close") { onCancel() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            VStack {
                HStack {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 10) {
                    Text("Fill the screen with the receipt")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Button { onUseText() } label: {
                        Label("Use Detected Text", systemImage: "text.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.primaryGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct ReceiptImagePreviewView: View {
    let image: UIImage?
    var onCancel: () -> Void
    var onScan: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                ZoomableImageView(image: image)
                    .ignoresSafeArea()
            } else {
                Text("No image")
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            VStack {
                HStack {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 10) {
                    Text("Pinch to zoom, then scan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Button { onScan() } label: {
                        Label("Scan This Image", systemImage: "text.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.primaryGrad)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.delegate = context.coordinator

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}

// ProfileView is in Views/Profile/ProfileView.swift

#Preview("AI Coach") { AICoachView().environmentObject(AppState()) }
#Preview("Scanner")  { NavigationStack { ReceiptScannerView() }.environmentObject(AppState()) }
