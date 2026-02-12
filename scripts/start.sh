#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

UPSTREAM_URL=""
API_KEY=""
PORT="8000"

while [ $# -gt 0 ]; do
  case "$1" in
    --upstream)
      UPSTREAM_URL="$2"
      shift 2
      ;;
    --api-key)
      API_KEY="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but was not found in PATH." >&2
  exit 1
fi

if [ ! -d "${VENV_DIR}" ]; then
  "${ROOT_DIR}/scripts/setup.sh"
fi

if [ -z "${UPSTREAM_URL}" ]; then
  read -r -p "Enter upstream base URL: " UPSTREAM_URL
fi

if [ -z "${UPSTREAM_URL}" ]; then
  echo "Upstream URL is required." >&2
  exit 1
fi

UPSTREAM_URL="${UPSTREAM_URL%/}"

check_endpoint() {
  local url="$1"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${API_KEY}" "$url" || true)

  case "$code" in
    200|201|204|301|302|303|307|308|401|403|405)
      echo "OK: $url ($code)"
      return 0
      ;;
    *)
      echo "FAIL: $url ($code)" >&2
      return 1
      ;;
  esac
}

echo "Validating upstream..."
check_endpoint "${UPSTREAM_URL}" || exit 1
check_endpoint "${UPSTREAM_URL}/responses" || exit 1
check_endpoint "${UPSTREAM_URL}/v1/responses" || exit 1

export UPSTREAM_BASE_URL="${UPSTREAM_URL}"
if [ -n "${API_KEY}" ]; then
  export UPSTREAM_API_KEY="${API_KEY}"
fi

"${VENV_DIR}/bin/python" -m uvicorn src.main:app --host 0.0.0.0 --port "${PORT}"
