# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
