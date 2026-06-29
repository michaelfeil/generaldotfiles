#!/usr/bin/env bash
set -euo pipefail

tmux_session="${TMUX_SESSION:-vscode}"
script_name="$(basename "$0")"

read_cmdline() {
  tr '\0' ' ' <"/proc/$1/cmdline" 2>/dev/null || true
}

read_comm() {
  tr -d '\n' <"/proc/$1/comm" 2>/dev/null || true
}

read_exe() {
  readlink "/proc/$1/exe" 2>/dev/null || true
}

is_zombie() {
  local key value

  while read -r key value _; do
    if [[ "$key" == "State:" ]]; then
      [[ "$value" == "Z" ]]
      return
    fi
  done <"/proc/$1/status" 2>/dev/null

  return 1
}

is_vscode_process() {
  local pid="$1"
  local comm="$2"
  local cmd="$3"
  local exe="$4"
  local exe_base="${exe##*/}"

  [[ "$pid" == "$$" ]] && return 1
  [[ "$cmd" == *"$script_name"* ]] && return 1

  case "$cmd" in
    *"tunnel_code.sh"*) return 0 ;;
    *"/.vscode/"* | *"/.vscode-server/"* | *"/.vscode-server-insiders/"* | *"/.vscode-server-oss/"* | *"/.vscode-remote/"*) return 0 ;;
    *" code tunnel"* | *"/code tunnel"* | *" Code Tunnel"* | *"/Visual Studio Code.app/"*) return 0 ;;
  esac

  case "$comm" in
    code | Code | code-insiders | code-oss | codium | Codium | vscodium | VSCodium | vscode | vscode-insiders)
      return 0
      ;;
  esac

  case "$exe_base" in
    code | Code | code-insiders | code-oss | codium | Codium | vscodium | VSCodium | vscode | vscode-insiders)
      return 0
      ;;
  esac

  return 1
}

list_matches() {
  local proc pid comm cmd exe

  for proc in /proc/[0-9]*; do
    pid="${proc##*/}"
    [[ -r "$proc/status" ]] || continue
    is_zombie "$pid" && continue

    comm="$(read_comm "$pid")"
    cmd="$(read_cmdline "$pid")"
    exe="$(read_exe "$pid")"

    if is_vscode_process "$pid" "$comm" "$cmd" "$exe"; then
      printf '%s\t%s\n' "$pid" "${cmd:-[$comm]}"
    fi
  done
}

print_matches() {
  local matches="$1"

  while IFS=$'\t' read -r pid cmd; do
    [[ -n "${pid:-}" ]] || continue
    printf '%s %s\n' "$pid" "$cmd"
  done <<<"$matches"
}

signal_matches() {
  local signal="$1"
  local matches="$2"
  local pid cmd

  while IFS=$'\t' read -r pid cmd; do
    [[ -n "${pid:-}" ]] || continue
    kill "-$signal" "$pid" 2>/dev/null || true
  done <<<"$matches"
}

if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$tmux_session" 2>/dev/null; then
  echo "[vscode] Killing tmux session: $tmux_session"
  tmux kill-session -t "$tmux_session" || true
fi

matches="$(list_matches)"

echo "[vscode] Matching processes:"
if [[ -z "$matches" ]]; then
  echo "[vscode] No matching processes found."
  exit 0
fi
print_matches "$matches"

echo "[vscode] Sending TERM..."
signal_matches TERM "$matches"
sleep 2

matches="$(list_matches)"
if [[ -n "$matches" ]]; then
  echo "[vscode] Remaining processes:"
  print_matches "$matches"

  echo "[vscode] Sending KILL..."
  signal_matches KILL "$matches"
  sleep 1
fi

matches="$(list_matches)"
if [[ -n "$matches" ]]; then
  echo "[vscode] Some matching processes are still present:"
  print_matches "$matches"
  exit 1
fi

echo "[vscode] All matching processes stopped."
