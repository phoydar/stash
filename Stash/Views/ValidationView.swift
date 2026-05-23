import SwiftUI

struct ValidationView: View {
    private let container = ValidationContainer.sample
    private let labelService = QRLabelService()

    @State private var labelImage: UIImage?
    @State private var shareItem: ShareItem?
    @State private var errorMessage: String?
    @State private var scannerIsPresented = false
    @State private var scannerResult = "No scan yet"
    @State private var parsedID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    validationHeader
                    payloadSection
                    labelPreviewSection
                    actionsSection
                    scannerSection
                }
                .padding(20)
            }
            .background(Color.sbCanvas.ignoresSafeArea())
            .tint(.sbBuzz)
            .navigationTitle("Stash phase 0")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: refreshLabelPreview)
            .onOpenURL { handleScannedValue($0.absoluteString) }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .sheet(isPresented: $scannerIsPresented) {
                ScannerView { value in
                    scannerIsPresented = false
                    handleScannedValue(value)
                }
                .ignoresSafeArea()
            }
            .alert("Validation error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var validationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(container.name)
                .font(.title2.bold())
            Text(container.location)
                .font(.subheadline)
                .foregroundStyle(Color.sbTextSecondary)
            HStack {
                ForEach(container.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.sbBuzz)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.sbBuzzSoft)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payload")
                .font(.headline)
            Text(container.payload)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Color.sbTextPrimary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sbCard(fill: .sbSurface)
        }
    }

    private var labelPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Single label preview")
                .font(.headline)

            if let labelImage {
                Image(uiImage: labelImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.sbBorder, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                refreshLabelPreview()
            } label: {
                Label("Regenerate label", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SBSecondaryButtonStyle())

            Button {
                shareLabelSheet()
            } label: {
                Label("Share label sheet PDF", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SBPrimaryButtonStyle())

            Text("Print the exported PDF from a desktop at actual size / 100% scale on 10-up 2 x 4 label sheets.")
                .font(.caption)
                .foregroundStyle(Color.sbTextTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan validation")
                .font(.headline)

            Text(scannerResult)
                .font(.subheadline)
                .foregroundStyle(Color.sbTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .sbCard(fill: .sbSurface)

            Button {
                scannerIsPresented = true
            } label: {
                Label("Open scanner", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SBSecondaryButtonStyle())

            Button {
                handleScannedValue(container.payload)
            } label: {
                Label("Validate sample payload", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SBSecondaryButtonStyle())
        }
    }

    private func refreshLabelPreview() {
        do {
            labelImage = try labelService.renderLabelImage(for: container)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func shareLabelSheet() {
        do {
            shareItem = ShareItem(url: try labelService.writeLabelSheetPDF(for: container))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleScannedValue(_ value: String) {
        guard let uuid = QRPayload.parse(value) else {
            parsedID = nil
            scannerResult = "Invalid payload: \(value)"
            return
        }

        parsedID = uuid
        if uuid == container.id {
            scannerResult = "Matched test container: \(uuid.uuidString)"
        } else {
            scannerResult = "Valid QR, but unknown container: \(uuid.uuidString)"
        }
    }
}

private struct ShareItem: Identifiable {
    let url: URL

    var id: String {
        url.absoluteString
    }
}
