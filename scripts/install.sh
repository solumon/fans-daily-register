#!/usr/bin/env bash
# Install fans-daily-register into ~/.agents/skills (Agent Skills 通用目录).
# 本机有 Cursor / Codex / Hermes 时再软链过去；没有就跳过。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="fans-daily-register"
AGENTS_SKILLS="${HOME}/.agents/skills"
DEST="${AGENTS_SKILLS}/${NAME}"

if [[ ! -f "${ROOT}/SKILL.md" ]]; then
  echo "error: missing ${ROOT}/SKILL.md" >&2
  exit 1
fi

mkdir -p "$AGENTS_SKILLS"

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

link_if_host() {
  local host_root="$1"
  local skills_dir="$2"
  local label="$3"
  if [[ ! -d "$host_root" ]]; then
    echo "  skip ${label}（未安装，无 ${host_root}）"
    return 0
  fi
  mkdir -p "$skills_dir"
  local link="${skills_dir}/${NAME}"
  if [[ -e "$link" && ! -L "$link" ]]; then
    rm -rf "$link"
  fi
  ln -sfn "$DEST" "$link"
  echo "  link ${link}"
}

link_if_host "${HOME}/.cursor" "${HOME}/.cursor/skills" "Cursor"
link_if_host "${HOME}/.codex" "${HOME}/.codex/skills" "Codex"
link_if_host "${HOME}/.hermes" "${HOME}/.hermes/skills" "Hermes"

echo "==> Self-check"
test -f "${DEST}/SKILL.md"
test -x "${DEST}/scripts/timesheet.sh"
test ! -e "${DEST}/scripts/install.sh"
echo "Install complete."
echo "Skill: ${DEST}/SKILL.md"
echo "任何会读 ~/.agents/skills 的 Agent 都能用；没有 Cursor/Codex/Hermes 也不影响。"
