# Changelog

All notable changes to the Freedman International Claude Code standard are documented here.

Format: `[version] — [date] — [description]`
Versioning: semantic (major.minor.patch) — see README for what each level means.

---

## [v2.1] — April 2026 — Silent auto-update on session start

- Added automatic version check to `Start of Every Session`
- On launch, CC silently fetches the latest CLAUDE.md from this repo
- If a newer version is found, CC overwrites both the project-level and global local copies automatically
- No user action required — update happens before the session checklist runs
- User is notified of the update version but not interrupted

## [v2.0] — April 2026 — Initial release

- First version committed to the centralised `freedman-claude-standards` repository
- Establishes this repo as the single source of truth for the Freedman global CLAUDE.md standard
- Prepared by Richard Freedman, Fractional CTO | Implemented by IT Team (Josh / Ryan)
