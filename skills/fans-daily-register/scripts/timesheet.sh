#!/usr/bin/env bash
set -euo pipefail

API="${TIMESHEET_API:-https://timesheet-manage.up366demo.cn}"
COOKIE="${TIMESHEET_COOKIE:-/tmp/fans-timesheet-cookies.txt}"
APP_NAME="timesheet-html"
DEFAULT_EMAIL="${TIMESHEET_EMAIL:-fanzongling@up366.com}"

usage() {
  echo "Usage: $0 login [email] | me | daily [YYYY-MM-DD] | submit <json> | range <json>" >&2
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

cmd="${1:-}"
case "$cmd" in
  login)
    email="${2:-$DEFAULT_EMAIL}"
    request /front/auth/login "$(printf '{"userName":"%s"}' "$email")"
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
