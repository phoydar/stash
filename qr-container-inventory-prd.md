# PRD: QR Container Inventory — iOS App

**Version:** 1.2
**Author:** Patrick Hoy  
**Status:** Reviewed; ready for Phase 0 validation before full build  
**Target Platform:** iOS 17+  
**Distribution:** Personal use — direct install via Xcode (no App Store)

---

## 1. Overview

A native SwiftUI iOS app for managing physical storage containers (bins, boxes, totes, toolboxes) using QR codes. Each container gets a unique QR label printed from a PDF label sheet on standard desktop-printer adhesive label stock. Scanning the QR code opens that container's contents in the app. All inventory data is stored locally on-device using SwiftData — no backend and no network required.

The recommended QR payload is an app URL (`stash://container/{uuid}`), not a bare UUID. The app remains fully local, but the URL format is more useful: it can be scanned by the in-app scanner, is future-compatible with deep links, and can open the installed app from the iOS Camera app if the URL scheme is registered.

---

## 2. Goals

- Quickly find which container an item is in
- Add, edit, move, and manage items per container from the phone
- Generate QR labels in the app and export printable PDF label sheets
- Scan a physical label and land directly on the matching container
- Work fully offline
- Provide a simple manual export path so local-only data is not trapped on one phone

---

## 3. Non-Goals

- No backend API or server-side account system
- No multi-user or sharing features
- No barcode scanning for individual items in v1
- No App Store distribution
- No direct Bluetooth label-printer integration in v1
- No dependency on vendor-specific label-printer mobile apps in v1

---

## 4. Technical Direction

| Layer | Recommended Choice |
|---|---|
| Language | Swift 5.9+ / current Xcode stable |
| UI Framework | SwiftUI |
| Navigation | `NavigationStack` with typed routes |
| Persistence | SwiftData (iOS 17+) |
| QR Generation | Core Image `CIFilter.qrCodeGenerator()` |
| Label Rendering | `UIGraphicsImageRenderer` for preview, `UIGraphicsPDFRenderer` for sheets |
| QR Scanning | AVFoundation `AVCaptureSession` + `AVCaptureMetadataOutput` |
| Label Handoff | SwiftUI sheet wrapping `UIActivityViewController`, sharing a PDF file URL |
| Minimum iOS | 17.0 |

Key implementation adjustments from the original draft:

- Use a `stash://container/{uuid}` payload and support parsing both the URL format and bare UUIDs for development/backward compatibility.
- Share a generated PDF file URL instead of a raw image; desktop printing needs stable page dimensions and repeatable placement.
- Treat the selected label sheet, printer scaling, and printable margins as calibration data, not fixed truth. Start with Avery 5160/8160-compatible US Letter geometry, then verify print scale and scan reliability on the actual printer and label stock.
- Keep SwiftData model names domain-specific (`StorageContainer`, `InventoryItem`) instead of a broad `Container` type name.
- Explicitly define relationship inverses and cascade behavior.

---

## 5. Data Models

### StorageContainer

```swift
@Model
final class StorageContainer {
    @Attribute(.unique) var qrID: UUID
    var name: String
    var location: String?
    var details: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.container)
    var items: [InventoryItem]

    init(name: String, location: String? = nil, details: String? = nil) {
        self.qrID = UUID()
        self.name = name
        self.location = location
        self.details = details
        self.tags = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.items = []
    }
}
```

### InventoryItem

```swift
@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var notes: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \StorageContainer.items)
    var container: StorageContainer?

    init(name: String, quantity: Int = 1, notes: String? = nil, container: StorageContainer? = nil) {
        self.id = UUID()
        self.name = name
        self.quantity = max(quantity, 1)
        self.notes = notes
        self.tags = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.container = container
    }
}
```

Notes:

- `qrID` is the durable label identity. Do not regenerate it when editing a container.
- `container` is optional to keep SwiftData editing flows simple, but app code should prevent orphaned items.
- If CloudKit sync is added later, re-check SwiftData constraints and relationships before enabling it; do not assume the local schema can be reused unchanged.

---

## 6. Project Structure

```text
ContainerInventory/
├── ContainerInventoryApp.swift
├── Config.swift
├── Models/
│   ├── StorageContainer.swift
│   └── InventoryItem.swift
├── Navigation/
│   ├── AppRoute.swift
│   └── AppRouter.swift
├── Services/
│   ├── DeepLinkParser.swift
│   ├── QRCodeService.swift
│   ├── QRLabelService.swift
│   └── InventoryExportService.swift
├── Views/
│   ├── ContentView.swift
│   ├── ContainerListView.swift
│   ├── ContainerDetailView.swift
│   ├── AddEditContainerView.swift
│   ├── AddEditItemView.swift
│   ├── ScannerView.swift
│   └── SearchView.swift
└── Components/
    ├── ActivityView.swift
    ├── TagInputView.swift
    └── QRCodeImageView.swift
```

---

## 7. App Entry Point

```swift
@main
struct ContainerInventoryApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: StorageContainer.self, InventoryItem.self)
        } catch {
            fatalError("Failed to initialize SwiftData model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

`ContentView` owns the tab view and navigation routes. It should also handle `onOpenURL` so URLs from the iOS Camera app route to the matching container.

---

## 8. Navigation & Tab Structure

```text
TabView
├── Tab 1: Containers
│     └── NavigationStack
│           └── ContainerListView
│                 └── tap row -> ContainerDetailView
│                       ├── item list
│                       ├── + Add Item -> AddEditItemView sheet
│                       ├── Edit Container -> AddEditContainerView sheet
│                       ├── QR Code preview
│                       └── Export Label Sheet -> ActivityView share sheet
│
├── Tab 2: Search
│     └── NavigationStack
│           └── SearchView
│                 └── tap result -> ContainerDetailView
│
└── Tab 3: Scan
      └── ScannerView
            ├── valid scan -> ContainerDetailView
            └── unknown container -> alert
```

Use typed route values instead of passing raw model objects through long navigation chains:

```swift
enum AppRoute: Hashable {
    case container(UUID)
}
```

---

## 9. Feature Specifications

### 9.1 Container List (`ContainerListView`)

- `@Query(sort: \StorageContainer.name)` to load all containers
- Each row shows name, location if set, item count, and tag chips
- Swipe-to-delete with confirmation alert
- `+` toolbar button opens `AddEditContainerView`
- Empty state: "No containers yet. Tap + to create your first one."
- Optional filter chips by tag and location after MVP

### 9.2 Container Detail (`ContainerDetailView`)

- Header: container name, location, details, tags
- QR code preview image, with tap-to-enlarge in Phase 2
- **Export Label Sheet** button generates a PDF label sheet and opens `ActivityView`
- Items section lists name, quantity, notes, and tags
- Add, edit, delete, and move items
- Edit button opens `AddEditContainerView` pre-populated
- Show the raw/deep-link QR value in a developer/debug-only copy action if needed during testing

### 9.3 Add/Edit Container (`AddEditContainerView`)

Fields:

- Name (required, `TextField`)
- Location (optional, `TextField`, placeholder: "e.g. Basement > Shelf 2")
- Details (optional, `TextEditor`)
- Tags (optional, `TagInputView`)

Behavior:

- Save button disabled until trimmed name is non-empty
- Trim whitespace on save
- Update `updatedAt` whenever mutable fields change
- New containers get one `qrID` and keep it permanently
- Cancel dismisses without saving

### 9.4 Add/Edit Item (`AddEditItemView`)

Fields:

- Name (required, `TextField`)
- Quantity (`Stepper`, min 1)
- Notes (optional, `TextEditor`)
- Tags (optional, `TagInputView`)

Behavior:

- Save button disabled until trimmed name is non-empty
- Automatically associates new items with the parent container
- Update `updatedAt` on edit
- Moving an item between containers is Phase 2 unless it is trivial during MVP

### 9.5 QR Scanner (`ScannerView`)

- Full-screen camera view using `AVCaptureSession`
- Request camera permission and show a useful denied-permission state
- Add `AVCaptureMetadataOutput`; set `metadataObjectTypes` to `.qr` only after confirming `.qr` is in `availableMetadataObjectTypes`
- Parse both supported payload formats:
  - `stash://container/{uuid}`
  - `{uuid}` during development/backward compatibility
- On scan:
  - Debounce so one QR code does not trigger repeated navigation
  - Look up `StorageContainer.qrID` in SwiftData
  - If found, navigate to `ContainerDetailView`
  - If not found, show: "Container not found. It may have been deleted or belongs to another device."
- Torch toggle button when the device supports torch
- Stop the capture session when leaving the scanner view

### 9.6 Search (`SearchView`)

- Single search bar searches container names, locations, tags, item names, item notes, and item tags
- Results grouped into Containers and Items
- Item results show parent container name and location as subtitle
- Tap container result -> `ContainerDetailView`
- Tap item result -> `ContainerDetailView`; scroll to item if practical
- Empty state when no query entered: "Search containers and items"
- No results state: "No results for '{query}'"

For v1 personal-scale data, in-memory filtering over queried containers/items is acceptable. If the database grows large enough to feel slow, replace it with SwiftData predicates or a small denormalized search index.

---

## 10. QR Payload & Label Service

### Payload Format

```swift
enum QRPayload {
    static let scheme = "stash"

    static func makeURL(for container: StorageContainer) -> URL {
        URL(string: "\(scheme)://container/\(container.qrID.uuidString)")!
    }

    static func parse(_ value: String) -> UUID? {
        if let uuid = UUID(uuidString: value) {
            return uuid
        }

        guard
            let url = URL(string: value),
            url.scheme == scheme,
            url.host == "container"
        else {
            return nil
        }

        return UUID(uuidString: url.pathComponents.dropFirst().first ?? "")
    }
}
```

### QR Generation

```swift
func generateQRCode(from string: String, size: CGSize) -> UIImage {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    filter.correctionLevel = "Q"

    guard let ciImage = filter.outputImage else { return UIImage() }

    let scaleX = size.width / ciImage.extent.width
    let scaleY = size.height / ciImage.extent.height
    let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

    let context = CIContext()
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
        return UIImage()
    }

    return UIImage(cgImage: cgImage)
}
```

### Label Composition

Start with **Avery 5160/8160-compatible US Letter sheets**: 30 labels per page, 3 columns by 10 rows, each label 2.625 in by 1 in. The first build must include a physical print calibration pass because printer drivers, printable margins, label stock, and "fit to page" defaults can change the final scale.

Recommended v1 label layout for each 2.625 in by 1 in label:

```text
┌──────────────────────────────┐
│ [QR]  Container Name         │
│       Location               │
│       #tag1 #tag2            │
└──────────────────────────────┘
```

Label rendering requirements:

- Render black on white only for print clarity.
- Keep a quiet zone around the QR code.
- Use dynamic text fitting or truncation for long container names.
- Store/share sheet output as PDF, not JPEG.
- Include a preview before export so bad layout is obvious before printing.
- Print PDF output at actual size / 100% scale.

### PDF Sheet Export

Use a SwiftUI sheet with a small `UIViewControllerRepresentable` wrapper around `UIActivityViewController`.

```swift
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
```

Print flow:

1. Tap **Export Label Sheet** in `ContainerDetailView`
2. App generates a PDF label sheet file in a temporary directory
3. SwiftUI presents `ActivityView`
4. User saves, AirDrops, emails, or otherwise moves the PDF to the desktop print path
5. User prints the PDF at actual size / 100% scale on the selected adhesive label sheet
6. User scans the printed QR with the app to verify it resolves

---

## 11. Info.plist Requirements

```xml
<!-- Camera access for QR scanner -->
<key>NSCameraUsageDescription</key>
<string>Used to scan QR codes on storage containers.</string>

<!-- Local app URL scheme for QR labels -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.patrickhoy.containerinventory</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>stash</string>
        </array>
    </dict>
</array>
```

---

## 12. Config

```swift
enum Config {
    static let appURLScheme = "stash"

    // Starting point only. Verify against the actual printer and label sheet.
    static let sheetPageSizePoints = CGSize(width: 612, height: 792) // US Letter at 72 pt/in.
    static let sheetLabelSizePoints = CGSize(width: 189, height: 72) // Avery 5160/8160.
    static let sheetColumns = 3
    static let sheetRows = 10
    static let sheetLeftMarginPoints: CGFloat = 13.5
    static let sheetTopMarginPoints: CGFloat = 36
    static let sheetHorizontalPitchPoints: CGFloat = 198
    static let sheetVerticalPitchPoints: CGFloat = 72
    static let sheetQRSizePoints: CGFloat = 52
    static let sheetLabelPaddingPoints: CGFloat = 7
}
```

---

## 13. Build Phases

### Phase 0 — Print/Scan Validation (Target: 2-4 hours)

- [ ] Create a throwaway SwiftUI screen or utility that generates one printable PDF label sheet
- [ ] Print the PDF at actual size / 100% scale on the intended desktop-printer label sheet
- [ ] Verify the printed QR scans reliably from normal phone distances
- [ ] Confirm whether iOS Camera opens the app via `stash://container/{uuid}`
- [ ] Adjust sheet stock, QR size, margins, and text layout based on the physical print

### Phase 1 — MVP (Target: 1 weekend)

- [ ] Xcode project setup with SwiftData `ModelContainer`
- [ ] `StorageContainer` and `InventoryItem` models
- [ ] `ContainerListView` with add, edit, delete
- [ ] `ContainerDetailView` with item list and item CRUD
- [ ] QR payload parser and QR generation
- [ ] Label preview and PDF label-sheet export
- [ ] `ScannerView` with camera permission handling and QR lookup
- [ ] Basic search across containers and items
- [ ] Manual JSON export

### Phase 2 — Usability (Target: 2-3 evenings)

- [ ] Tag filtering on container list and search results
- [ ] Location suggestions or predefined location picker
- [ ] Tap-to-enlarge QR preview
- [ ] Move item between containers
- [ ] Import from exported JSON if worth the added complexity

### Phase 3 — Nice to Have

- [ ] CloudKit sync or iCloud document backup
- [x] Item and bin photo support, stored as files with SwiftData filename references
- [ ] Quantity low flag ("need to restock")
- [ ] Siri Shortcuts or Spotlight integration for quick lookup

---

## 14. Known Constraints & Risks

- **iOS 17+ required** — SwiftData is unavailable on older iOS versions.
- **Desktop print scaling must be controlled** — labels must be printed at actual size / 100%, not fit-to-page.
- **Label sheet alignment must be tested** — printer margins, sheet feed accuracy, and label stock geometry are the highest-risk assumptions.
- **Direct Xcode install has signing/provisioning friction** — personal installs may need periodic redeploying unless signed with a paid developer account or another durable distribution path.
- **Local-only storage can be lost** — iCloud device backup may help, but the app should provide manual JSON export in MVP.
- **URL scheme collisions are possible** — `stash` is convenient but not globally unique. If this ever ships beyond personal use, use a more specific scheme.
- **Printed labels are durable external references** — never regenerate a container's `qrID` during normal edits.

---

## 15. Acceptance Criteria

| Feature | Criteria |
|---|---|
| Create container | Container appears in list with correct name, location, tags, and stable `qrID` |
| Add item | Item appears under correct container with name and quantity |
| Edit item/container | Changes persist after app relaunch |
| Generate QR | QR decodes to `stash://container/{uuid}` and parser extracts the UUID |
| Print label | Share sheet opens with a PDF label sheet; the desktop print path preserves actual size |
| Physical scan | Printed QR scans reliably and opens the correct container |
| Unknown scan | Unknown/deleted IDs show a clear not-found message |
| Search | Typing a term returns matching containers and items |
| Delete | Deleting a container removes its items through cascade behavior |
| Export | User can export all inventory data as JSON |
| Offline | Core inventory, QR generation, scanning, and search work with no network connection |

---

## 16. Open Decisions

- Exact label stock size to optimize for: Avery 5160/8160 is the starting assumption, but validate against the sheets you actually plan to use.
- App name and URL scheme: `Stash` / `stash://` are concise, but a more unique scheme avoids future collisions.
- Whether search belongs in the first weekend MVP depends on expected inventory size. Because "find which container an item is in" is the core job, this PRD keeps basic search in Phase 1.
- Whether JSON import is worth building immediately. Export is important for safety; import can wait unless you plan to migrate between devices soon.
