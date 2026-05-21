# Stash

Stash is a planned native iOS app for managing physical storage containers with QR labels. The app will let a user create containers, add inventory items, print QR labels through the NIIMBOT app, and scan a physical label to open the matching container on-device.

The project is currently in planning and Phase 0 validation. The full product direction lives in [qr-container-inventory-prd.md](qr-container-inventory-prd.md).

## Product Goal

The core job is simple: quickly answer "where did I put this?" without relying on memory, spreadsheets, or cloud services.

Stash should:

- Store inventory locally on the phone.
- Generate stable QR labels for storage containers.
- Print labels through the NIIMBOT app using the iOS share sheet.
- Scan a printed label and open the matching container.
- Work offline.
- Provide manual export so local-only data is not trapped on one device.

## Current Status

Status: Phase 0 validation.

Before building the full app, the first development milestone is to prove the physical label loop:

1. Generate a QR payload like `stash://container/{uuid}`.
2. Render it into a black-on-white PNG label.
3. Share the PNG into the NIIMBOT app.
4. Print it on the intended label stock.
5. Scan the printed QR from normal phone distances.
6. Confirm the payload parses and routes to the expected local container.
7. Record the calibrated label size, QR size, margins, and NIIMBOT import notes.

This de-risks the part of the project most likely to cause rework: physical print scale and QR scan reliability.

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
| Label rendering | `UIGraphicsImageRenderer` to PNG |
| Printing | iOS share sheet to NIIMBOT |
| Distribution | Personal install through Xcode |

## QR Payload

The recommended QR payload format is:

```text
stash://container/{uuid}
```

The app should also support parsing a bare UUID during development and for backward compatibility, but new labels should use the app URL format. The URL format keeps the app local-only while leaving room for iOS deep linking and future app flows.

## Phase 0 Acceptance Criteria

Phase 0 is complete when:

- NIIMBOT can import the generated PNG from the iOS share sheet.
- The printed QR scans reliably.
- The printed QR decodes to `stash://container/{uuid}`.
- The parser extracts the expected UUID.
- The validation app can route the scanned UUID to a known local test container or validation result.
- Final label dimensions, QR size, quiet zone, margins, and NIIMBOT-specific notes are documented.

## Phase 1 MVP Scope

After Phase 0 passes, the MVP should include:

- SwiftData models for containers and items.
- Container create, read, update, and delete flows.
- Item create, read, update, delete, and basic quantity tracking.
- QR payload generation and parsing.
- Label preview and share-sheet handoff.
- Camera scanner with permission handling.
- Basic search across containers and items.
- Manual JSON export.

## Project Files

```text
.
├── README.md
├── qr-container-inventory-prd.md
└── AGENTS.md
```

Expected app structure after project creation:

```text
ContainerInventory/
├── ContainerInventoryApp.swift
├── Config.swift
├── Models/
├── Navigation/
├── Services/
├── Views/
└── Components/
```

## Development Notes

- Keep container QR identities stable. A container's QR ID should not change during normal edits.
- Treat NIIMBOT label dimensions as calibrated implementation data, not a fixed assumption.
- Prefer file-backed PNG sharing over raw `UIImage` sharing for better behavior in external apps.
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
