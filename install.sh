#!/bin/bash

# Freedman International — Claude Code Standards Installer
# --------------------------------------------------------
# Bootstraps a machine with the Freedman CLAUDE.md standard.
# Run this once on any new or existing machine.
#
# Usage:
#   bash install.sh
#
# Or remotely (one-liner for IT Team use):
#   curl -s https://raw.githubusercontent.com/Freedman-GIT/freedman-claude-standards/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/Freedman-GIT/freedman-claude-standards/main/CLAUDE.md"
FREEDMAN_DIR="$HOME/Desktop/Freedman Development"
GLOBAL_CLAUDE_DIR="$HOME/.claude"

echo ""
echo "Freedman International — Claude Code Standards Installer"
echo "---------------------------------------------------------"

# ── 1. Fetch the latest CLAUDE.md ────────────────────────────────────────────

echo "→ Fetching latest CLAUDE.md from GitHub..."

if ! curl -s --fail "$REPO_URL" -o /tmp/claude-md-latest.md; then
  echo ""
  echo "✗ Could not reach GitHub. Check your internet connection and try again."
  exit 1
fi

LATEST_VERSION=$(grep "^\*Freedman International Development Standards" /tmp/claude-md-latest.md | head -1)
echo "  Found: $LATEST_VERSION"

# ── 2. Install to Freedman Development folder ─────────────────────────────────

echo "→ Installing to: $FREEDMAN_DIR"

if [ ! -d "$FREEDMAN_DIR" ]; then
  mkdir -p "$FREEDMAN_DIR"
  echo "  Created folder: $FREEDMAN_DIR"
else
  echo "  Folder already exists: $FREEDMAN_DIR"
fi

cp /tmp/claude-md-latest.md "$FREEDMAN_DIR/CLAUDE.md"
echo "  ✓ CLAUDE.md installed at: $FREEDMAN_DIR/CLAUDE.md"

# ── 3. Install to global ~/.claude/ if it exists ─────────────────────────────

if [ -d "$GLOBAL_CLAUDE_DIR" ]; then
  cp /tmp/claude-md-latest.md "$GLOBAL_CLAUDE_DIR/CLAUDE.md"
  echo "  ✓ CLAUDE.md updated at: $GLOBAL_CLAUDE_DIR/CLAUDE.md"
else
  echo "  ℹ ~/.claude/ not found — skipping global install (Claude Code may not be installed yet)"
fi

# ── 4. Cleanup ────────────────────────────────────────────────────────────────

rm /tmp/claude-md-latest.md

# ── 5. Done ───────────────────────────────────────────────────────────────────

echo ""
echo "✓ Installation complete."
echo "  The Freedman Claude Code standard is now active on this machine."
echo "  Future updates will be applied automatically at the start of each Claude Code session."
echo ""
