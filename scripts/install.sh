#!/usr/bin/env bash
# Install fans-daily-register into $HOME for Cursor, Codex, and Hermes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="fans-daily-register"
AGENTS_SKILLS="${HOME}/.agents/skills"
CURSOR_SKILLS="${HOME}/.cursor/skills"
CODEX_SKILLS="${HOME}/.codex/skills"
HERMES_SKILLS="${HOME}/.hermes/skills"
DEST="${AGENTS_SKILLS}/${NAME}"

if [[ ! -f "${ROOT}/SKILL.md" ]]; then
  echo "error: missing ${ROOT}/SKILL.md" >&2
  exit 1
fi

mkdir -p "$AGENTS_SKILLS" "$CURSOR_SKILLS" "$CODEX_SKILLS"

echo "==> Installing skill into ${DEST}"
mkdir -p "$DEST"
rsync -a --delete \
  --exclude '.git/' \
  --exclude '.cursor/' \
  --exclude 'README.md' \
  --exclude 'scripts/install.sh' \
  --exclude '.DS_Store' \
  "${ROOT}/" "${DEST}/"
chmod +x "${DEST}/scripts/timesheet.sh"

link_skill() {
  local link="$1"
  mkdir -p "$(dirname "$link")"
  if [[ -e "$link" && ! -L "$link" ]]; then
    rm -rf "$link"
  fi
  ln -sfn "$DEST" "$link"
  echo "  link ${link}"
}

link_skill "${CURSOR_SKILLS}/${NAME}"
link_skill "${CODEX_SKILLS}/${NAME}"
# Hermes 从 ~/.hermes/skills/ 扫 SKILL.md；有 ~/.hermes 才装这条软链
if [[ -d "${HOME}/.hermes" ]]; then
  mkdir -p "$HERMES_SKILLS"
  link_skill "${HERMES_SKILLS}/${NAME}"
else
  echo "  skip Hermes (${HOME}/.hermes 不存在)"
fi

echo "==> Self-check"
test -f "${DEST}/SKILL.md"
test -x "${DEST}/scripts/timesheet.sh"
test ! -e "${DEST}/scripts/install.sh"
test -L "${CURSOR_SKILLS}/${NAME}"
test -L "${CODEX_SKILLS}/${NAME}"
if [[ -d "${HOME}/.hermes" ]]; then
  test -L "${HERMES_SKILLS}/${NAME}"
fi
echo "Install complete."
echo "Skill: ${DEST}/SKILL.md"
