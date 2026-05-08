# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1.0] - 2026-05-08

### Added

- `.agile/` directory structure: all skill-generated files now live under `.agile/{iter-id}/` — the project root and `docs/` are never touched
- `scripts/current-state.sh` — returns the absolute path to the active state file; all other scripts use this as their foundation
- `scripts/list-iterations.sh` — prints a table of all iterations in `.agile/` with phase and completion status
- `scripts/check-constraints.sh`: Constraint 8 — validates that `.agile/CURRENT` pointer matches the `iteration_version` in the active state file
- `tests/test-agile-dir.sh` — integration tests for `.agile/` lifecycle: init, CURRENT update, counter increment, list

### Changed

- `scripts/init-state.sh` — creates `.agile/iter-YYYYMMDD-NN/state.md`; auto-increments counter on same-day collisions; updates `.agile/CURRENT` atomically; no longer overwrites any existing file
- `scripts/validate-state.sh` — no argument needed; resolves active state via `current-state.sh`; direct path still accepted
- `scripts/validate-prd.sh` — no argument needed; resolves active PRD via `current-state.sh`; direct path still accepted
- `scripts/check-constraints.sh` — no argument needed; resolves active state via `current-state.sh`
- `references/iteration-state-template.md` — `prd_path` default updated to `.agile/iter-YYYYMMDD-01/prd.md`
- `SKILL.md` — "Required Files" section replaced with "Iteration Directory Structure" section; all path references updated
- `BOOTSTRAP.md` — updated state file location to `.agile/`; scenario 2 updated for new resume command
- `README.md` — bootstrap prompt updated with new state management commands
- `.github/workflows/validate.yml` — added `test-agile-dir.sh` step

## [2.0.1] - 2026-05-08

### Added

- `BOOTSTRAP.md` — tool-agnostic activation prompt for cold-starting the skill in any new AI window (Claude, Cursor, Windsurf, etc.), covering fresh start, resume, and per-tool integration (CLAUDE.md, .cursor/rules, .windsurfrules)
- `README.md`: "新窗口启动 / Starting in a New Window" section at top with copy-pasteable Orchestrator prompt
- `README.md`: link to BOOTSTRAP.md for resume and tool-specific integration details

## [2.0.0] - 2026-05-08

### Architecture

- Redesigned from single-orchestrator model to **Pipeline Orchestration Model**
- Main agent (now `Orchestrator`) is a pure coordinator: never writes code, never reads large source files
- Added phase-gated state machine: `INIT → REQUIREMENTS_DRAFTING → REQUIREMENTS_REVIEW → REQUIREMENTS_CONFIRMED → PM_DECOMPOSITION → BUILDING → INTEGRATION_CHECK → TESTING → COMPLETE`
- Added `ProductOwner` and `Challenger` roles that run in parallel and independently during requirements phase
- Added `ProjectManager` role that decomposes confirmed PRD into bounded slices with strictly disjoint file ownership
- Added integration check gate between BUILDING and TESTING phases
- `Tester` agents spawned after integration check passes, formula: `max(1, ceil(builder_count / 2))`
- `Integrator` agent is optional, only created when integration check fails

### Added

- `schema/prd.json` — JSON Schema for PRD document frontmatter
- `scripts/validate-prd.sh` — PRD frontmatter validation script
- `references/prd-template.md` — PRD document template with YAML frontmatter
- `references/pm-decomposition-guide.md` — ProjectManager decomposition granularity rules and step-by-step process
- `tests/fixtures/valid-prd.md` — valid PRD test fixture
- `tests/fixtures/invalid-prd-missing-fields.md` — invalid PRD test fixture
- `tests/test-validate-prd.sh` — PRD validation smoke tests
- State file frontmatter fields: `phase`, `prd_path`, `builder_count`, `tester_count`
- `schema/state-file.json`: `phase` added to required fields
- `schema/state-file.json`: `slice_board[].owner` enum extended with all 7 pipeline roles
- `schema/task-contract.json`: optional fields `phase`, `agent_role`, `parallel_group`
- `scripts/check-constraints.sh`: Constraint 7 — file ownership conflict detection in BUILDING phase
- `references/error-recovery.md`: 3 new failure scenarios (Challenger stall, PM ownership conflict, Builder scope violation)
- `.github/workflows/validate.yml`: PRD validation step added

### Changed

- `SKILL.md` — full rewrite for v2.0 pipeline architecture, 16 workflow sections
- `README.md` — slimmed to navigation document (pipeline diagram, role table, tool table); full protocol in SKILL.md
- `references/team-operating-model.md` — restructured around phase-aware role activation table
- `references/iteration-state-template.md` — updated frontmatter for new fields, added Phase Log section
- `scripts/validate-state.sh` — PyYAML error message now includes install instruction; consistency check tolerance reduced from 30% to 10% and changed from WARN to FAIL (exit 1)
- `scripts/check-constraints.sh` — all in-progress and acceptance-criteria counts now parsed from YAML frontmatter (not grep); eliminates false positives from Markdown body text
- `scripts/init-state.sh` — skill version parsing rewritten in Python (eliminates fragile awk/sed chain)

### Fixed

- `scripts/validate-state.sh`: missing PyYAML install guidance on dependency error
- `scripts/validate-state.sh`: `overall_completion` inconsistency was WARN/non-failing; now FAIL/exit 1
- `scripts/check-constraints.sh`: `grep -c 'status:.*in_progress'` matched Markdown body text; replaced with YAML-aware Python parsing
- `scripts/init-state.sh`: version extraction from SKILL.md frontmatter could silently return empty string

## [1.0.0] - 2026-05-06

### Added

- Agent-agnostic skill definition (works with Claude Code, Cursor, Codex, etc.)
- JSON Schema for state file (`schema/state-file.json`) and task contracts (`schema/task-contract.json`)
- State file validation script (`scripts/validate-state.sh`)
- State file initialization script (`scripts/init-state.sh`)
- Harness invariant checking script (`scripts/check-constraints.sh`)
- Error recovery procedures (`references/error-recovery.md`)
- Hook configuration example for `.claude/settings.json` (`hooks/settings.json.example`)
- YAML frontmatter requirement on `current-iteration.md` for machine validation
- Semantic versioning for the skill itself
- CI workflow for state file validation on PRs
