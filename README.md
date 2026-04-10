# freedman-claude-standards

Centralised repository for Freedman International's global Claude Code (CC) standards.

This repository is the single source of truth for the `CLAUDE.md` file that governs how
Claude Code behaves across all Freedman projects — defining the technology stack, commit
conventions, security rules, documentation standards, and more.

---

## Who this is for

IT Team (Josh / Ryan) — responsible for maintaining and distributing the standard.
All CC users — should keep their local `CLAUDE.md` in sync with this repository.

---

## Repository structure

```
freedman-claude-standards/
  CLAUDE.md       # The Freedman global standard
  CHANGELOG.md    # Version history and change notes
  README.md       # This file
  projects/       # Project-specific CLAUDE.md overrides (optional, future use)
```

Project-specific `CLAUDE.md` files (such as those in individual project repos) remain
in their project repositories and are not overridden by this process. This repo governs
the global standard only.

---

## Installing on a new machine

Run this once in Terminal on any new or existing machine:

```bash
curl -s https://raw.githubusercontent.com/Freedman-GIT/freedman-claude-standards/main/install.sh | bash
```

This will:
- Create `~/Desktop/Freedman Development/` if it doesn't exist
- Download the latest `CLAUDE.md` to that folder
- Update `~/.claude/CLAUDE.md` if Claude Code is already installed
- Confirm success

After this one-time step, all future updates are automatic.

---

## How updates work

At the start of every Claude Code session, CC silently checks whether a newer version
of the standard is available. If it is, CC automatically overwrites the local copy and
notifies the user:

```
CLAUDE.md has been updated to v2.X. This session uses the new standard.
```

No user action required. Updates happen before the session checklist runs.

---

## Versioning convention

The `CLAUDE.md` file carries a version line at the bottom using semantic versioning:

| Change type | Example | Action required |
|---|---|---|
| Breaking change to standards | v2.0 | Teams must review before updating |
| New section or meaningful addition | v2.1 | Review recommended |
| Typo, clarification, minor wording | v2.1.1 | Safe to accept |

---

## Raising a change request

CLAUDE.md is maintained by the IT Team. Do not edit it directly.

If a Claude Code session reveals a gap or error in the standards, CC will generate a
`claude-md-change-request-[date]-[description].md` file in the project root. Send this
file to Josh or Ryan for review. If accepted, they will update this repository and
roll out the change.

---

## Owner

Richard Freedman, Fractional CTO.
Questions to Richard. Implementation and distribution managed by Josh / Ryan (IT Team).

---

*Freedman International | Technology & Innovation | April 2026*
