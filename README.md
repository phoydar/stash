# Stash

Stash is a native iOS app for managing physical storage containers with QR labels. The app lets a user create containers, add inventory items, generate printable QR label sheets, and scan a physical label to open the matching container on-device.

The project is in Phase 1 MVP implementation after the initial Phase 0 print/scan loop was proven manually. The full product direction lives in [qr-container-inventory-prd.md](qr-container-inventory-prd.md).

## Product Goal

The core job is simple: quickly answer "where did I put this?" without relying on memory, spreadsheets, or cloud services.

Stash should:

- Store inventory locally on the phone.
- Generate stable QR labels for storage containers.
- Export printable PDF label sheets for desktop printing on adhesive label stock.
- Scan a printed label and open the matching container.
- Work offline.
- Provide manual export so local-only data is not trapped on one device.

## Current Status

Status: Phase 1 app foundation started.

Phase 0 manually proved the export/scan/deep-link loop:

1. Generate a QR payload like `stash://container/{uuid}`.
2. Render it into a black-on-white label.
3. Export a US Letter PDF label sheet.
4. Scan the exported label from the phone.
5. Confirm the payload parses and opens Stash.

The remaining Phase 0 documentation task is physical print calibration: print at 100% scale, test the adhesive label in realistic conditions, and record the calibrated sheet stock, printer settings, label size, QR size, and margins.

## Phase 1 App

The repo now includes a SwiftUI iOS app backed by SwiftData.

Open the generated Xcode project:

```bash
open Stash.xcodeproj
```

If the project needs to be regenerated after editing `project.yml`:

```bash
xcodegen generate
```

Build from the command line without code signing:

```bash
xcodebuild -project Stash.xcodeproj -scheme Stash -destination generic/platform=iOS -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Compile the app and test bundle:

```bash
xcodebuild -project Stash.xcodeproj -scheme Stash -destination generic/platform=iOS -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

The app currently provides:

- SwiftData `StorageContainer` and `InventoryItem` models.
- Reusable saved locations for container create/edit flows.
- Container create, read, update, and delete flows.
- Item create, read, update, delete, and quantity tracking.
- Local bin and item photo attachments stored as files and shown as thumbnails.
- Usage and declutter tracking for first-added dates, bin opens/scans, item use, review status, and optional local review reminders.
- All-items inventory view with tag, location, usage-age, and review-status filters.
- A stable `stash://container/{uuid}` payload per container.
- A black-on-white QR label preview per container.
- A share-sheet handoff that exports a printable PDF label sheet for desktop printing.
- An AVFoundation QR scanner with permission handling and torch support.
- Deep-link and in-app scanner routing to matching local containers.
- Basic search across containers, locations, details, tags, and item text.

Physical validation should be recorded in:

- [docs/phase-0-test-plan.md](docs/phase-0-test-plan.md)
- [docs/phase-0-label-calibration.md](docs/phase-0-label-calibration.md)

## Planned Stack

| Area | Direction |
| --- | --- |
| Platform | iOS 17+ |
| Language | Swift |
| UI | SwiftUI |
| Persistence | SwiftData |
| Navigation | `NavigationStack` with typed routes |
| QR generation | Core Image |
| QR scanning | AVFoundation |
| Review reminders | Local notifications through `UserNotifications` |
| Label rendering | `UIGraphicsImageRenderer` for preview, `UIGraphicsPDFRenderer` for sheets |
| Printing | Desktop printer from PDF label sheets |
| Distribution | Personal install through Xcode |

## QR Payload

The recommended QR payload format is:

```text
stash://container/{uuid}
```

The app should also support parsing a bare UUID during development and for backward compatibility, but new labels should use the app URL format. The URL format keeps the app local-only while leaving room for iOS deep linking and future app flows.

## Phase 0 Acceptance Criteria

Phase 0 is complete when:

- A generated PDF label sheet prints at 100% scale on the selected adhesive label stock.
- The printed QR scans reliably.
- The printed QR decodes to `stash://container/{uuid}`.
- The parser extracts the expected UUID.
- The validation app can route the scanned UUID to a known local test container or validation result.
- Final sheet stock, printer settings, label dimensions, QR size, quiet zone, and margins are documented.

## Phase 1 MVP Scope

Phase 1 MVP scope:

- [x] SwiftData models for containers and items.
- [x] Container create, read, update, and delete flows.
- [x] Item create, read, update, delete, and basic quantity tracking.
- [x] Bin and item photo thumbnails backed by local files.
- [x] Usage and declutter tracking with local review reminders.
- [x] QR payload generation and parsing.
- [x] Label preview and PDF label-sheet export.
- [x] Camera scanner with permission handling.
- [x] Basic search across containers and items.
- [ ] Manual JSON export.

## Project Files

```text
.
├── README.md
├── qr-container-inventory-prd.md
├── docs/
├── project.yml
├── Stash.xcodeproj/
├── Stash/
└── StashTests/
```

Current app structure:

```text
Stash/
├── App/
├── Config.swift
├── Components/
├── Models/
├── Navigation/
├── Resources/
├── Services/
├── Views/
└── Utilities/
```

## Development Notes

- Keep container QR identities stable. A container's QR ID should not change during normal edits.
- Treat label sheet dimensions, printer scaling, and printable margins as calibrated implementation data, not fixed assumptions.
- Print validation PDFs at actual size / 100% scale. Browser or Preview auto-fit scaling can invalidate QR size and alignment tests.
- Do not add backend, account, or sync complexity before the local app flow works end to end.
- Commit `Package.resolved` if Swift Package Manager dependencies are added to the app project.

## GitHub Remote

This repo is intended to use the personal GitHub SSH alias:

```text
git@psh.github.com:phoydar/stash.git
```

If the repository has no commits yet, create the first commit before pushing:

```bash
git add .gitignore README.md AGENTS.md qr-container-inventory-prd.md
git commit -m "Initial project planning"
git push -u origin main
```

If `git push` reports `src refspec main does not match any`, that means the local `main` branch has no commits yet.

## Project Tracking

Planning work is tracked in monday.com under the `Kanban Team` workspace:

- Epic: `Stash iOS: Phase 0 Print/Scan Validation`
- Board: `Epics`
- Task board: `Custom App Development`

The Monday epic should remain the active project-management surface. This repository should remain the source of truth for code, implementation notes, and durable technical decisions.
