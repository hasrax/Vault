//
//  ReceiptScannerView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-26.
//

import SwiftUI
import PhotosUI
import Vision
import VisionKit
import UIKit

// MARK: - Receipt Scanner
struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var shouldCloseAll: Bool
    @State private var isScanning      = false
    @State private var scannedAmount: Double? = nil
    @State private var amountCandidates: [Double] = []
    @State private var selectedCandidate: Double? = nil
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

    init(shouldCloseAll: Binding<Bool> = .constant(false)) {
        _shouldCloseAll = shouldCloseAll
    }

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
                prefillReceiptBase64: receiptImageBase64,
                onSaveAndCloseAll: { shouldCloseAll = true }
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
        .onChange(of: shouldCloseAll) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    // MARK: - Camera Frame
    private var cameraFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 300)

            if let img = receiptImage {
                Button {
                    showImagePreview = true
                } label: {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
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
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.income)
                        Text("Receipt scanned")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    Text(amount.currencyRS)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.income)
                    Text("Tap Log this transaction to continue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .padding(16)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.income.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 16)
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

            if scannedAmount == nil, !amountCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Detected totals")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    ForEach(amountCandidates, id: \.self) { value in
                        Button {
                            selectedCandidate = value
                        } label: {
                            HStack {
                                Text(value.currencyRS)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                if selectedCandidate == value {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.uniBlue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Confirm Amount") {
                        if let selectedCandidate {
                            scannedAmount = selectedCandidate
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LinearGradient.primaryGrad)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(selectedCandidate == nil)
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
        amountCandidates = []
        selectedCandidate = nil
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
                let amounts = extractAmounts(from: strings)
                self.amountCandidates = amounts
                self.selectedCandidate = amounts.first
                if amounts.isEmpty {
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

    private func extractAmounts(from lines: [String]) -> [Double] {
        let lower = lines.map { $0.lowercased() }
        let keywords = ["total", "amount", "subtotal", "balance", "due", "payable", "grand", "net"]
        let prioritized = lower.filter { line in
            keywords.contains { line.contains($0) }
        }

        let sourceLines = prioritized.isEmpty ? lower : prioritized
        let candidates = sourceLines.flatMap { extractNumbers(from: $0) }
        if !candidates.isEmpty {
            return normalizeCandidates(candidates)
        }

        let fallbackCandidates = lower.flatMap { extractNumbers(from: $0) }
        return normalizeCandidates(fallbackCandidates)
    }

    private func extractNumbers(from text: String) -> [Double] {
        let pattern = "([0-9]{1,3}(?:[\\.,][0-9]{3})*(?:[\\.,][0-9]{2})?|[0-9]+(?:[\\.,][0-9]{2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            let raw = String(text[r])
            let normalized = normalizeNumberString(raw)
            return Double(normalized)
        }
    }

    private func normalizeNumberString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(",") && trimmed.contains(".") {
            return trimmed.replacingOccurrences(of: ",", with: "")
        }

        if trimmed.contains(",") {
            let parts = trimmed.split(separator: ",")
            if let last = parts.last, last.count == 2 {
                let intPart = parts.dropLast().joined()
                return intPart + "." + last
            }
            return trimmed.replacingOccurrences(of: ",", with: "")
        }

        return trimmed
    }

    private func normalizeCandidates(_ values: [Double]) -> [Double] {
        let unique = Array(Set(values))
        let sorted = unique.sorted(by: >)
        return Array(sorted.prefix(5))
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
        let amounts = extractAmounts(from: lines)
        amountCandidates = amounts
        selectedCandidate = amounts.first
        if amounts.isEmpty {
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
                        Label("Scan This Receipt", systemImage: "text.viewfinder")
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

#Preview("Scanner")  { NavigationStack { ReceiptScannerView() }.environmentObject(AppState()) }
