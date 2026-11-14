#!/bin/bash
# install.sh — link the expensive-brain skill into agent skill directories.
# Symlinks by default; pass --copy for filesystems/OSes where symlinks hurt.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/.agents/skills/expensive-brain"
MODE="${1:-link}"

place() {
  local dest_dir="$1" dest="$1/expensive-brain"
  mkdir -p "$dest_dir"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "skip  $dest (exists)"
    return
  fi
  if [[ "$MODE" == "--copy" ]]; then cp -r "$SRC" "$dest"; else ln -s "$SRC" "$dest"; fi
  echo "ok    $dest"
}

place "$HOME/.claude/skills"                     # Claude Code (user)
place "${CODEX_HOME:-$HOME/.codex}/skills"       # Codex CLI (user)
[[ -d "$HOME/.hermes" ]] && place "$HOME/.hermes/skills" || echo "skip  ~/.hermes (not present)"
[[ -d "$HOME/.gemini" ]] && place "$HOME/.gemini/skills" || echo "skip  ~/.gemini (not present)"

echo
echo "Project-scoped agents (OpenCode, Gemini workspace) read .agents/skills/ in the repo."
echo "Restart running agent sessions to pick up the skill."
