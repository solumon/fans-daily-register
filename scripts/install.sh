#!/usr/bin/env bash
# Install fans-daily-register into $HOME for Cursor and Codex.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="fans-daily-register"
SRC="${ROOT}/skills/${NAME}"
AGENTS_SKILLS="${HOME}/.agents/skills"
CURSOR_SKILLS="${HOME}/.cursor/skills"
CODEX_SKILLS="${HOME}/.codex/skills"
DEST="${AGENTS_SKILLS}/${NAME}"

if [[ ! -d "$SRC" ]]; then
  echo "error: missing ${SRC}" >&2
  exit 1
fi

mkdir -p "$AGENTS_SKILLS" "$CURSOR_SKILLS" "$CODEX_SKILLS"

echo "==> Installing skill into ${DEST}"
mkdir -p "$DEST"
rsync -a --delete --exclude '.DS_Store' "${SRC}/" "${DEST}/"
chmod +x "${DEST}/scripts/timesheet.sh"

link_skill() {
  local link="$1"
  if [[ -e "$link" && ! -L "$link" ]]; then
    rm -rf "$link"
  fi
  ln -sfn "$DEST" "$link"
  echo "  link ${link}"
}

link_skill "${CURSOR_SKILLS}/${NAME}"
link_skill "${CODEX_SKILLS}/${NAME}"

echo "==> Self-check"
test -f "${DEST}/SKILL.md"
test -x "${DEST}/scripts/timesheet.sh"
test -L "${CURSOR_SKILLS}/${NAME}"
test -L "${CODEX_SKILLS}/${NAME}"
echo "Install complete."
echo "Skill: ${DEST}/SKILL.md"
