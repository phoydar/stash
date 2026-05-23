# Agent Instructions

## Project

Stash is a native iOS SwiftUI app for QR-labeled physical storage containers.

## Source Of Truth

- Use `README.md` for current setup and run commands.
- Use `qr-container-inventory-prd.md` for product scope.
- Use `docs/current-state.md` for durable handoff state and near-term status.
- Use `docs/phase-0-test-plan.md` and `docs/phase-0-label-calibration.md` for Phase 0 validation.

## Git

- Default branch prefix for agent branches is `agent/`.
- Keep commits scoped to the requested work.
- Do not commit generated local context or timestamp churn.

## Project Tracking

- Use Monday.com as the project-management surface.
- Main work board: `Custom App Development`.
- Epic board: `Epics`.
- Active Stash epic: `Stash iOS: Phase 0 Print/Scan Validation`.
- When creating or updating work items, verify the Monday item after mutation.

## Parallel Work

- Use separate branches or worktrees for parallel implementation when changes can be isolated.
- Keep worker ownership explicit by feature, file set, or module.
- Avoid overlapping edits unless the lead agent is intentionally integrating the work.

## Agent Context Policy

- Do not put generated session memory, timestamps, or transient status in this file.
- Keep durable project state in tracked docs such as `README.md` or `docs/current-state.md`.
- Keep local/session-only notes in ignored local files.
- Do not use `git update-index --skip-worktree AGENTS.md` as the normal fix for generated context churn.
