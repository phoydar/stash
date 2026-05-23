# Phase 0 Test Plan

Purpose: prove the physical QR label loop before building the full Stash app.

Phase 0 passes when a generated `stash://container/{uuid}` payload can be rendered to a printable PDF label sheet, printed from a desktop printer at actual size, scanned, parsed, and routed to a known local test container.

## Test Setup

Tester:
Date:
iPhone model:
iOS version:
App build or branch:
Desktop OS:
PDF viewer or print app:
Printer model:
Label sheet brand:
Label sheet product number:
Label sheet listed size:
Print scale setting:
Lighting conditions:

Known test container:

- Name:
- UUID:
- Expected payload: `stash://container/`

## Data To Record For Every Run

- PDF page size:
- Label sheet product number:
- Label count per sheet:
- Label physical size:
- QR printed size:
- Quiet zone:
- Label margins:
- Print scale setting:
- Printer driver options:
- Print alignment behavior:
- Scan distance range:
- Number of scan attempts:
- Scan time:
- Parsed payload:
- Parsed UUID:
- Routed container:
- Pass/fail:
- Notes:

## Test Cases

### 1. QR Payload Generation

Steps:

1. Create or select a known local test container.
2. Generate a stable UUID for the container.
3. Generate a payload in the form `stash://container/{uuid}`.
4. Regenerate the payload after editing display fields such as name or location.

Expected result:

- Payload uses the `stash://container/{uuid}` format.
- UUID is stable across normal container edits.
- New labels do not use bare UUIDs.

Result:

- Pass/fail:
- Actual payload:
- Notes:

### 2. PDF Label Sheet Rendering

Steps:

1. Render a black-on-white PDF label sheet using the candidate sheet constants.
2. Inspect the PDF before printing.
3. Confirm each QR code has a clear quiet zone and does not touch edges, text, or other artwork.
4. Save or share the exact PDF used for printing.

Expected result:

- PDF page size matches the target stock, initially US Letter.
- Label positions match the selected sheet geometry, currently 10-up 2" x 4" US Letter stock.
- QR codes are sharp, square, and not clipped.
- Quiet zone is visually preserved.
- Image dimensions match the candidate calibration record.

Result:

- Pass/fail:
- PDF page size:
- Label sheet product:
- QR target size:
- Quiet zone:
- Notes:

### 3. Desktop Print Path

Steps:

1. Open the generated PDF on the desktop.
2. Select the target printer and label sheet stock.
3. Set scaling to actual size / 100%.
4. Disable fit-to-page, shrink-to-fit, borderless auto scaling, or other automatic resizing.
5. Print one test sheet.
6. Record whether the printer shifts, scales, clips, or skews the label content.

Expected result:

- PDF prints at actual size / 100%.
- QR codes remain black on white.
- QR codes remain square and readable.
- Label content lands inside each adhesive label area.
- Any printer scaling or alignment behavior is recorded.

Result:

- Pass/fail:
- Print app:
- Printer:
- Scale setting:
- Observed print behavior:
- Notes:

### 4. Print Output

Steps:

1. Inspect the physical label sheet.
2. Measure printed QR size and margins.
3. Confirm the QR code is not clipped, blurred, smeared, or too close to the edge.
4. Peel and attach at least one label to a representative container surface.

Expected result:

- Printed label preserves the QR code and quiet zone.
- Printed QR has enough contrast for normal phone scanning.
- Physical dimensions match or improve on the calibration target.

Result:

- Pass/fail:
- Printed QR size:
- Left/right margins:
- Top/bottom margins:
- Label alignment:
- Notes:

### 5. Scan Reliability

Steps:

1. Scan the printed label with the in-app scanner.
2. Repeat scans from normal storage-use distances.
3. Repeat under at least two realistic lighting conditions.
4. Repeat with the label attached to a representative container surface.

Expected result:

- Scanner decodes the printed QR quickly and consistently.
- Payload matches the generated `stash://container/{uuid}` value.
- Scan succeeds without requiring extreme angle, distance, or lighting.

Result:

- Pass/fail:
- Attempts:
- Successful scans:
- Distance range:
- Lighting:
- Container surface:
- Notes:

### 6. Parser And Routing

Steps:

1. Feed the scanned value to the deep-link parser.
2. Confirm the parser extracts the expected UUID.
3. Confirm the app routes to the known local test container or validation result.
4. Scan an unknown but valid `stash://container/{uuid}` payload.
5. Scan an invalid or unrelated QR code.

Expected result:

- Valid known payload routes to the expected test container.
- Valid unknown payload shows an unknown-container result.
- Invalid payload is rejected without navigating to the wrong container.
- Bare UUID parsing may work for development, but is not used for new labels.

Result:

- Pass/fail:
- Parsed UUID:
- Routed container:
- Unknown payload behavior:
- Invalid payload behavior:
- Notes:

## Final Phase 0 Decision

Overall result:

- Pass/fail:
- Approved label sheet:
- Approved printer settings:
- Approved label constants:
- Blocking issues:
- Follow-up changes before Phase 1:
- Tester sign-off:
