#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install-test.XXXXXXXX")"
trap 'rm -rf -- "$test_dir"' EXIT
export HOME="$test_dir/home"
export INSTALL_LOG="$test_dir/commands"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME/.cargo" "$test_dir/bin"
touch "$HOME/.cargo/env"

# Exercise the real installer with external downloads/package changes stubbed.
cat > "$test_dir/bin/mock" <<'MOCK'
#!/usr/bin/env bash
set -eu
name="${0##*/}"
printf '%s %s\n' "$name" "$*" >> "$INSTALL_LOG"
case "$name" in
  sudo) exec "$@" ;;
  dpkg) echo amd64 ;;
  npm) exit "${NPM_EXIT_CODE:-0}" ;;
esac
MOCK
chmod +x "$test_dir/bin/mock"
for cmd in apt-get curl npm rustup uv python3 dpkg sudo code tmux; do
  ln -s mock "$test_dir/bin/$cmd"
done
export PATH="$test_dir/bin:$PATH"
git config --global user.name 'Keep User'
git config --global user.email 'keep@example.com'
bash "$repo_dir/install.sh"
grep -qF 'curl -fsSL https://opencode.ai/install' "$INSTALL_LOG"
grep -qF "npm install -g --prefix $HOME/.local @getpaseo/cli" "$INSTALL_LOG"
grep -qF "npm install -g --prefix $HOME/.local @openai/codex" "$INSTALL_LOG"
if grep -Ei '^(code |tmux )|code\.visualstudio\.com|tunnel_code\.sh' "$INSTALL_LOG"; then
  echo 'FAIL: installer set up a VS Code tunnel' >&2; exit 1
fi
[[ "$(git config --global user.name)" == 'Keep User' ]]
[[ "$(git config --global user.email)" == 'keep@example.com' ]]
if NPM_EXIT_CODE=23 bash "$repo_dir/install.sh"; then
  echo 'FAIL: installer ignored npm failure' >&2; exit 1
else
  [[ $? -eq 23 ]]
fi
echo 'All installer checks passed (external commands mocked).'
