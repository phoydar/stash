# Current State

Last updated: 2026-05-23

## Status

Phase 1 MVP implementation has started. The app is no longer just a Phase 0 validation screen; it now launches into the real Stash tab structure backed by SwiftData.

## Implemented

- `AGENTS.md` is stable repo policy only. Durable handoff state belongs here, and local/session-only context belongs in ignored local files.
- SwiftData model container initialized in `StashApp`.
- `StorageContainer` model with stable `qrID`, name, optional location/details, tags, timestamps, and cascade-owned items.
- `InventoryItem` model with name, quantity, optional notes, tags, timestamps, and parent container.
- `StorageLocation` model for reusable, locally stored container locations.
- Containers tab with list, add, edit, delete, and detail navigation.
- Container create/edit flow uses saved locations, supports inline location creation, and deduplicates case/whitespace variants.
- New container flow supports adding and removing initial item rows with quantity controls before saving.
- Container detail with metadata, QR payload, label preview, PDF label-sheet export, item list, item add/edit/delete, and quantity tracking.
- Items tab lists all inventory items across containers, shows parent container/location context, and supports combinable tag and location filters.
- Label sheet composer with explicit 10-slot 2" x 4" US Letter placement. Users can choose which container prints in each slot and leave used/missing positions blank.
- Search tab across container names, locations, details, tags, item names, item notes, and item tags.
- Scan tab using the existing AVFoundation scanner and routing known `stash://container/{uuid}` payloads to saved containers.
- App-level `onOpenURL` handling for `stash://container/{uuid}` links.
- QR label rendering refactored to work with both Phase 0 validation content and real `StorageContainer` records.
- Default label stock is 10-up, 2" x 4" US Letter with Avery 5163-compatible margins and pitch. Recalibrate after printing on the selected AveneMark stock.

## Verification

Compile the app and test bundle:

```bash
xcodebuild -project Stash.xcodeproj -scheme Stash -destination generic/platform=iOS -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

This command succeeded outside the sandbox on 2026-05-23 after the managed-location and all-items work. It compiles the app and test bundle but does not run simulator-hosted tests.

## Next Work

- Implement TPSH-020: item and bin photos with thumbnail behavior.
- Add manual JSON export for local data portability.
- Run the app on a physical iPhone and verify create/edit/delete, saved location, and all-items filter flows against the on-device SwiftData store.
- Re-test the existing printed label against a newly created real container, not just the Phase 0 validation container.
- Record final Phase 0 calibration details in `docs/phase-0-label-calibration.md` and `docs/phase-0-test-plan.md`.
