#!/usr/bin/env bash
# discover_accounts.sh — find real Claude Code config directories on this machine.
#
# Works for a single default account (~/.claude) all the way up to a Mac running
# several CLAUDE_CONFIG_DIR-based profiles. Prints one config dir path per line.
# Portable to bash 3.2 (macOS's default /bin/bash) — no associative arrays.
#
# A candidate only counts as a real account if it (a) has a settings.json or
# .claude.json, and (b) shows actual usage — at least one session .jsonl file
# under its projects/ dir. That second check is what quietly drops an unused
# default ~/.claude on a machine where every real profile uses a custom
# CLAUDE_CONFIG_DIR, without needing to guess at shell-alias intent.
#
# If two candidates' projects/ dirs resolve to the same real path (one mirrors
# the other via symlink — a common way to share one login's history across two
# CLI aliases), only the non-symlinked "real" one is kept, so usage isn't
# double-counted.

set -uo pipefail

candidates=()

[ -n "${CLAUDE_CONFIG_DIR:-}" ] && candidates+=("$CLAUDE_CONFIG_DIR")

for rc in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$rc" ] || continue
  while IFS= read -r dir; do
    # alias paths are commonly quoted: CLAUDE_CONFIG_DIR="$HOME/.claude-x"
    dir="${dir//\"/}"
    dir="${dir//\'/}"
    dir="${dir//\$HOME/$HOME}"
    dir="${dir/#\~/$HOME}"
    [ -n "$dir" ] && candidates+=("$dir")
  done < <(grep -ohE 'CLAUDE_CONFIG_DIR=[^[:space:]]+' "$rc" 2>/dev/null | sed -E 's/CLAUDE_CONFIG_DIR=//')
done

candidates+=("$HOME/.claude")

seen_dirs=$'\n'
real=()
for c in "${candidates[@]}"; do
  c="${c%/}"
  [ -d "$c" ] || continue
  rp=$(cd "$c" 2>/dev/null && pwd -P) || continue
  case "$seen_dirs" in *$'\n'"$rp"$'\n'*) continue ;; esac
  seen_dirs="$seen_dirs$rp"$'\n'
  if [ -f "$c/settings.json" ] || [ -f "$c/.claude.json" ]; then
    if find "$c/projects" -name "*.jsonl" -print -quit 2>/dev/null | grep -q .; then
      real+=("$c")
    fi
  fi
done

seen_proj=$'\n'
final=()
# Prefer non-symlinked projects dirs first, so a mirror never displaces the original.
for c in "${real[@]}"; do
  [ -L "$c/projects" ] && continue
  pp=$(cd "$c/projects" 2>/dev/null && pwd -P) || continue
  seen_proj="$seen_proj$pp"$'\n'
  final+=("$c")
done
for c in "${real[@]}"; do
  [ -L "$c/projects" ] || continue
  pp=$(cd "$c/projects" 2>/dev/null && pwd -P) || continue
  case "$seen_proj" in *$'\n'"$pp"$'\n'*) continue ;; esac
  seen_proj="$seen_proj$pp"$'\n'
  final+=("$c")
done

printf '%s\n' "${final[@]}"
