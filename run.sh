#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# kestrel-product — Local Runner
# =============================================================================
# Run from this module dir:  ./run.sh
#
# Steps:
#   1. Verify .env (lives in repo root: kestrel_backend/.env).
#   2. Load env vars: repo-root/.env first, then optional module-level .env override.
#   3. Start local PostgreSQL via Compose.
#   4. Launch Quarkus dev mode on port 8083.
#
# -----------------------------------------------------------------------------
# Compose location
# -----------------------------------------------------------------------------
# docker-compose.yml lives at the repo root: kestrel_backend/docker-compose.yml.
# This script auto-runs `podman compose` from there. No need to cd manually.
#
# -----------------------------------------------------------------------------
# Manual Compose commands (run from repo root)
# -----------------------------------------------------------------------------
#   cd <repo_root>                         # kestrel_backend/
#
#   podman compose up -d postgres          # start Postgres in background
#   podman compose logs -f postgres        # stream logs
#   podman compose ps                      # show container status
#   podman compose down                    # stop, KEEP volume (data persists)
#   podman compose down -v                 # stop AND wipe volume (FULL RESET)
#
# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------
#   kestrel-postgres                       Real Postgres container (port 5432).
#   kestrel_backend (compose)              Compose project label in Podman Desktop —
#                                          NOT an extra container.
#
# -----------------------------------------------------------------------------
# Prerequisite: .env at repo root with KESTREL_DB_PASSWORD set
# -----------------------------------------------------------------------------
#   cp .env.example .env                   # then edit and set a strong password
# Compose hard-fails with "Set KESTREL_DB_PASSWORD in .env" if missing.
# =============================================================================

MODULE_NAME="kestrel-product"
HTTP_PORT="8083"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "$REPO_ROOT/.env" ]]; then
  echo "Missing .env at $REPO_ROOT/.env"
  echo "  cp $REPO_ROOT/.env.example $REPO_ROOT/.env"
  exit 1
fi

if [[ ! -x "./mvnw" ]]; then
  echo "Missing or non-executable ./mvnw wrapper in $ROOT_DIR"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$REPO_ROOT/.env"
# Optional module-specific override
if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
fi
set +a

echo "Starting PostgreSQL via Compose..."
(cd "$REPO_ROOT" && podman compose up -d postgres)

echo
echo "Starting $MODULE_NAME in Quarkus dev mode..."
echo "  App:           http://localhost:$HTTP_PORT"
echo "  Quarkus Dev UI: http://localhost:$HTTP_PORT/q/dev/"
echo

./mvnw quarkus:dev -Dquarkus.http.port="$HTTP_PORT"
