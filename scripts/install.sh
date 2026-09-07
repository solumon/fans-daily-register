#!/usr/bin/env bash
# Install fans-daily-register into ~/.agents/skills (Agent Skills 通用目录).
# 本机有 Cursor / Codex / Hermes 时再软链过去；没有就跳过。
#
# 远程（不克隆）：curl -fsSL https://raw.githubusercontent.com/solumon/fans-daily-register/master/scripts/install.sh | bash
# 本地（开发者）：./scripts/install.sh
set -euo pipefail

NAME="fans-daily-register"
REPO_SLUG="solumon/fans-daily-register"
REF="${FANS_DAILY_REGISTER_REF:-master}"
AGENTS_SKILLS="${HOME}/.agents/skills"
DEST="${AGENTS_SKILLS}/${NAME}"
FETCH_TMP=""

cleanup() {
  if [[ -n "${FETCH_TMP}" && -d "${FETCH_TMP}" ]]; then
    rm -rf "${FETCH_TMP}"
  fi
}
trap cleanup EXIT

pick_root() {
  local d
  for d in "$FETCH_TMP"/*/; do
    if [[ -f "${d}SKILL.md" ]]; then
      ROOT="${d%/}"
      return 0
    fi
  done
  if [[ -f "${FETCH_TMP}/SKILL.md" ]]; then
    ROOT="$FETCH_TMP"
    return 0
  fi
  return 1
}

new_tmp() {
  if [[ -n "${FETCH_TMP}" && -d "${FETCH_TMP}" ]]; then
    rm -rf "${FETCH_TMP}"
  fi
  FETCH_TMP="$(mktemp -d "${TMPDIR:-/tmp}/${NAME}.XXXXXX")"
}

fetch_remote() {
  if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    echo "==> Fetching ${REPO_SLUG}@${REF} via curl (no git clone)"
    new_tmp
    if curl -fsSL "https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REF}" | tar -xz -C "$FETCH_TMP" && pick_root; then
      return 0
    fi
    echo "  curl tarball failed, trying next" >&2
  fi

  if command -v gh >/dev/null 2>&1; then
    echo "==> Fetching ${REPO_SLUG}@${REF} via gh"
    new_tmp
    if gh api "repos/${REPO_SLUG}/tarball/${REF}" | tar -xz -C "$FETCH_TMP" && pick_root; then
      return 0
    fi
    echo "  gh tarball failed, trying next" >&2
  fi

  if command -v git >/dev/null 2>&1; then
    echo "==> Fetching ${REPO_SLUG}@${REF} via temporary shallow clone"
    new_tmp
    if git clone --depth 1 --branch "$REF" "https://github.com/${REPO_SLUG}.git" "${FETCH_TMP}/src" && pick_root; then
      return 0
    fi
  fi

  echo "error: cannot fetch ${REPO_SLUG}@${REF}" >&2
  exit 1
}

ROOT=""
SRC="${BASH_SOURCE[0]:-}"
if [[ -n "$SRC" && -f "$SRC" ]]; then
  ROOT="$(cd "$(dirname "$SRC")/.." && pwd)"
  if [[ ! -f "${ROOT}/SKILL.md" ]]; then
    ROOT=""
  fi
fi

if [[ -z "$ROOT" ]]; then
  fetch_remote
fi

mkdir -p "$AGENTS_SKILLS"

echo "==> Installing skill into ${DEST}"
mkdir -p "$DEST"
rsync -a --delete \
  --exclude '.git/' \
  --exclude '.cursor/' \
  --exclude 'README.md' \
  --exclude 'scripts/install.sh' \
  --exclude 'scripts/install.ps1' \
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
