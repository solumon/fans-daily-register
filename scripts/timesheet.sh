#!/usr/bin/env bash
set -euo pipefail

API="${TIMESHEET_API:-https://timesheet-manage.up366demo.cn}"
COOKIE="${TIMESHEET_COOKIE:-/tmp/fans-timesheet-cookies.txt}"
EMAIL_FILE="${TIMESHEET_EMAIL_FILE:-$HOME/.config/fans-daily-register/email}"
APP_NAME="timesheet-html"

usage() {
  echo "Usage: $0 email | login [email] | me | daily [YYYY-MM-DD] | submit <json> | range <json>" >&2
  exit 2
}

request() {
  local path="$1"
  local data="${2:-{}}"
  curl -sS "$API$path" \
    -H "Content-Type: application/json" \
    -H "X-App-Name: $APP_NAME" \
    -b "$COOKIE" -c "$COOKIE" \
    --data "$data"
}

json_ok() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("code")==0 else 1)'
}

read_saved_email() {
  if [[ -n "${TIMESHEET_EMAIL:-}" ]]; then
    printf '%s' "$TIMESHEET_EMAIL"
    return
  fi
  if [[ -f "$EMAIL_FILE" ]]; then
    tr -d '[:space:]' < "$EMAIL_FILE"
  fi
}

save_email() {
  local email="$1"
  mkdir -p "$(dirname "$EMAIL_FILE")"
  printf '%s\n' "$email" > "$EMAIL_FILE"
  chmod 600 "$EMAIL_FILE"
}

cmd="${1:-}"
case "$cmd" in
  email)
    saved="$(read_saved_email)"
    if [[ -z "$saved" ]]; then
      echo "NO_EMAIL" >&2
      exit 3
    fi
    printf '%s\n' "$saved"
    ;;
  login)
    email="${2:-$(read_saved_email)}"
    if [[ -z "$email" ]]; then
      echo "NO_EMAIL" >&2
      exit 3
    fi
    resp="$(request /front/auth/login "$(printf '{"userName":"%s"}' "$email")")"
    printf '%s\n' "$resp"
    if printf '%s' "$resp" | json_ok; then
      save_email "$email"
    else
      exit 1
    fi
    ;;
  me)
    request /front/auth/me '{}'
    ;;
  daily)
    day="${2:-$(date +%F)}"
    request /front/timesheet/daily "$(printf '{"workDate":"%s"}' "$day")"
    ;;
  submit|range)
    json="${2:-}"
    [[ -n "$json" ]] || usage
    path="/front/timesheet/submit"
    [[ "$cmd" == range ]] && path="/front/timesheet/range"
    request "$path" "$json"
    ;;
  *)
    usage
    ;;
esac
