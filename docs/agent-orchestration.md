# Agent Orchestration

Use this guide when splitting Stash work across lead and worker agents.

## Source Of Truth Order

1. Current user instruction.
2. Stable repo policy in `AGENTS.md`.
3. Durable handoff state in `docs/current-state.md`.
4. This orchestration guide.
5. Optional ignored local context such as `.agents.local.md`, `.claude.local.md`, `.codex.local.md`, `.agents/local-context.md`, `.claude/local-context.md`, or `.codex/local-context.md`.

Ignored local context is scratch only. It can help a local session resume, but it is not authoritative and must not be required for a fresh clone to understand the repo.

## Monday Workflow

- Track project work in Monday.com.
- Use the `Custom App Development` task board and the `Epics` board.
- Link Stash work to the `Stash iOS: Phase 0 Print/Scan Validation` epic unless the user names a different epic.
- Verify created or updated Monday items with a read-back query before reporting success.

## Lead Agent Responsibilities

- Read `AGENTS.md`, `docs/current-state.md`, and the relevant product docs before delegating.
- Decide whether work can be split safely before spawning workers.
- Assign each worker a clear file or feature ownership boundary.
- Integrate worker output, resolve conflicts, and run final verification.
- Update `docs/current-state.md` when implementation changes durable project status.

## Worker Agent Responsibilities

- Stay within the assigned ownership boundary.
- Do not revert or overwrite unrelated edits.
- Report changed files, behavior, and verification results.
- Do not commit unless the lead agent or user explicitly asks.

## Verification

Prefer the repo build command from `README.md`:

```bash
xcodebuild -project Stash.xcodeproj -scheme Stash -destination generic/platform=iOS -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

If sandboxed Xcode execution fails because of CoreSimulator, asset catalog, or Swift macro environment limits, rerun outside the sandbox when approval is available and report the distinction clearly.
