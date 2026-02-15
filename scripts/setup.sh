#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required but was not found in PATH." >&2
  exit 1
fi

(
  cd "${ROOT_DIR}"
  UV_PROJECT_ENVIRONMENT="${VENV_DIR}" uv sync
)

echo "Setup complete."
