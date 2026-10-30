#!/usr/bin/env bash
set -euo pipefail
export NONINTERACTIVE=1

[[ $# -eq 0 ]] || { echo 'Usage: bash install.sh' >&2; exit 2; }
if ! command -v apt-get >/dev/null 2>&1; then
  echo 'install.sh requires Ubuntu/Debian. Use bootstrap.sh --skip-install for dotfiles only.' >&2
  exit 1
fi
sudo_cmd=()
if [[ "$EUID" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install -y nano apache2-utils build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm \
              libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libpq-dev \
              protobuf-compiler libprotobuf-dev python3-dev python3-venv curl file git procps musl-tools bash-completion tmux

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
# Install a current Node LTS into HOME for both root and regular users. Distro
# Node/npm packages can be too old for Paseo; no system-wide npm writes needed.
export N_PREFIX="$HOME/.local"
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s -- install lts
hash -r

# Agent tools. OpenCode is the provider CLI used by Paseo.
curl -fsSL https://opencode.ai/install | bash
npm install -g --prefix "$HOME/.local" @getpaseo/cli
npm install -g --prefix "$HOME/.local" @openai/codex
npm install -g --prefix "$HOME/.local" @anthropic-ai/claude-code

# uv and cli tools
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSL https://install.python-poetry.org | python3 -
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add x86_64-unknown-linux-musl 
# Use the upstream Debian package instead of requiring Homebrew as root.
arch="$(dpkg --print-architecture)"
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_linux_${arch}.deb" \
  -o "$work_dir/k9s.deb"
"${sudo_cmd[@]}" apt-get install -y "$work_dir/k9s.deb"

if ! git config --global user.name >/dev/null; then
  git config --global user.name michaelfeil
fi
if ! git config --global user.email >/dev/null; then
  git config --global user.email 63565275+michaelfeil@users.noreply.github.com
fi
uv tool install ruff

echo 'Development tools installed. Run opencode to authenticate; run paseo to set up pairing.'
