import SwiftData
import SwiftUI

struct ScanHomeView: View {
    @Binding var path: [AppRoute]
    let onRouteToContainer: (UUID) -> Void

    @Query(sort: \StorageContainer.name) private var containers: [StorageContainer]

    @State private var scannerIsPresented = false
    @State private var scanMessage = "No scan yet"
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Text(scanMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.sbTextSecondary)

                    Button {
                        scannerIsPresented = true
                    } label: {
                        Label("Open scanner", systemImage: "camera.viewfinder")
                    }
                }
                .listRowBackground(Color.sbSurface)

                Section("Known containers") {
                    if containers.isEmpty {
                        Text("Create a container before scanning a Stash label.")
                            .foregroundStyle(Color.sbTextSecondary)
                    } else {
                        ForEach(containers) { container in
                            NavigationLink(value: AppRoute.container(container.qrID)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(container.name)
                                        .foregroundStyle(Color.sbTextPrimary)
                                    Text(container.qrID.uuidString)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.sbTextTertiary)
                                }
                            }
                            .listRowBackground(Color.sbSurface)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .sbGroupedBackground()
            .tint(.sbBuzz)
            .navigationTitle("Scan")
            .sheet(isPresented: $scannerIsPresented) {
                ScannerView { value in
                    scannerIsPresented = false
                    handleScannedValue(value)
                }
                .ignoresSafeArea()
            }
            .alert("Scan result", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .container(let uuid):
                    ContainerDetailView(qrID: uuid)
                }
            }
        }
    }

    private func handleScannedValue(_ value: String) {
        guard let uuid = QRPayload.parse(value) else {
            scanMessage = "Invalid payload: \(value)"
            alertMessage = "This QR code is not a Stash container label."
            return
        }

        guard containers.contains(where: { $0.qrID == uuid }) else {
            scanMessage = "Unknown container: \(uuid.uuidString)"
            alertMessage = "This is a valid Stash container QR code, but it does not match a saved container on this device."
            return
        }

        scanMessage = "Matched container: \(uuid.uuidString)"
        onRouteToContainer(uuid)
    }
}
