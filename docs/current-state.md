# Current State

Last updated: 2026-05-26

## Status

Phase 1 MVP implementation has started. The app is no longer just a Phase 0 validation screen; it now launches into the real Stash tab structure backed by SwiftData.

## Implemented

- `AGENTS.md` is stable repo policy only. It must not contain generated memory blocks, recent-context timestamps, or transient session summaries.
- Durable handoff state belongs in this file, while local/session-only scratch belongs in ignored local files such as `.agents.local.md`, `.claude.local.md`, `.codex.local.md`, `.agents/local-context.md`, `.claude/local-context.md`, or `.codex/local-context.md`.
- `docs/agent-orchestration.md` records the agent source-of-truth order and Monday.com workflow for split-agent work.
- SwiftData model container initialized in `StashApp`.
- `StorageContainer` model with stable `qrID`, name, optional location/details/photo filename, lifecycle open/scan tracking, tags, timestamps, and cascade-owned items.
- `InventoryItem` model with name, quantity, optional notes/photo filename, last-used tracking, use count, review status, optional review reminder metadata, tags, timestamps, and parent container.
- `StorageLocation` model for reusable, locally stored container locations.
- Containers tab with list, add, edit, delete, and detail navigation.
- Container create/edit flow uses saved locations, supports inline location creation, and deduplicates case/whitespace variants.
- New container flow supports adding and removing initial item rows with quantity controls before saving.
- Container and item edit flows support local photo selection, replacement, and removal.
- Container detail with metadata, lifecycle dates/counts, explicit mark-opened action, QR payload, label preview, PDF label-sheet export, item list, item add/edit/delete, and quantity tracking.
- Item rows support explicit used-today tracking and quick review status actions.
- Item edit supports manual last-used date entry, review status selection, and optional local review reminders through `UserNotifications`.
- Items tab lists all inventory items across containers, shows parent container/location context, and supports combinable tag, location, usage-age, and review-status filters plus usage-aware sorting.
- Container, item, search, and label-selection surfaces use uploaded photos as thumbnails when present.
- Label sheet composer with explicit 10-slot 2" x 4" US Letter placement. Users can choose which container prints in each slot, see bin thumbnails while choosing labels, and leave used/missing positions blank.
- Search tab across container names, locations, details, tags, item names, item notes, and item tags.
- Scan tab using the existing AVFoundation scanner and routing known `stash://container/{uuid}` payloads to saved containers.
- QR scans update container last-scanned date and scan count without changing last-opened tracking.
- App-level `onOpenURL` handling for `stash://container/{uuid}` links.
- QR label rendering refactored to work with both Phase 0 validation content and real `StorageContainer` records.
- Default label stock is 10-up, 2" x 4" US Letter with Avery 5163-compatible margins and pitch. Recalibrate after printing on the selected AveneMark stock.

## Verification

Compile the app and test bundle:

```bash
xcodebuild -project Stash.xcodeproj -scheme Stash -destination generic/platform=iOS -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

This command succeeded outside the sandbox on 2026-05-26 after the usage and declutter tracking work. It compiles the app and test bundle but does not run simulator-hosted tests.

## Next Work

- Add manual JSON export for local data portability.
- Run the app on a physical iPhone and verify create/edit/delete, photo selection/removal, saved location, local notification permission, lifecycle tracking, and all-items filter flows against the on-device SwiftData store.
- Re-test the existing printed label against a newly created real container, not just the Phase 0 validation container.
- Record final Phase 0 calibration details in `docs/phase-0-label-calibration.md` and `docs/phase-0-test-plan.md`.
