#!/usr/bin/env bash
set -euo pipefail

while true; do
  echo "[vscode] Killing previous tunnel (if any)..."
  code tunnel kill || true

  echo "[vscode] Starting new VS Code tunnel..."
  code tunnel --accept-server-license-terms

  echo "[vscode] Tunnel exited. Restarting in 3s..."
  sleep 3
done
