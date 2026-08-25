#!/usr/bin/env bash
# link-shared.sh — point both Claude configs at one shared skill or command.
#
# Source of truth lives in ~/ClaudeOS/shared/ (skills/<name>/ or commands/<name>.md).
# This replaces the copy in BOTH ~/.claude-work and ~/.claude-personal with a
# symlink to that one source, so they can never drift. Build the skill/command
# once in the shared folder, then run this once to wire it into both configs.
#
# Usage:
#   ./link-shared.sh skill   <name>      # links shared/skills/<name>/
#   ./link-shared.sh command <name>      # links shared/commands/<name>.md
#
# Only use this for GENERIC tools that behave the same in work and personal.
# Tools that depend on work-only or personal-only systems (e.g. morning-brief:
# Outlook vs Gmail) must stay as separate per-config copies — do NOT link them.

set -euo pipefail

kind="${1:-}"; name="${2:-}"
if [ -z "$kind" ] || [ -z "$name" ]; then
  echo "usage: link-shared.sh <skill|command> <name>" >&2
  exit 2
fi

case "$kind" in
  skill)   sub="skills/$name" ;;
  command) sub="commands/$name.md" ;;
  *) echo "first arg must be 'skill' or 'command'" >&2; exit 2 ;;
esac

src="$HOME/ClaudeOS/shared/$sub"
if [ ! -e "$src" ]; then
  echo "Nothing at $src — create the $kind in the shared folder first." >&2
  exit 1
fi

for cfg in .claude-work .claude-personal; do
  dest="$HOME/$cfg/$sub"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  ln -s "$src" "$dest"
  echo "linked  $dest  ->  $src"
done
