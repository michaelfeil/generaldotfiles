#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXXXX")"
trap 'rm -rf -- "$test_dir"' EXIT
export HOME="$test_dir/home with spaces"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME"

fail() { echo "FAIL: $*" >&2; exit 1; }
run_bootstrap() { bash "$repo_dir/bootstrap.sh" --skip-install --skip-tpm; }
backup_count() { find "$HOME" -maxdepth 1 -name '.dotfiles-backup.*' | wc -l | tr -d ' '; }

# Fresh install and loading the generated file in noninteractive scripts.
run_bootstrap
[[ -L "$HOME/.me" && -L "$HOME/.vimrc" ]] || fail 'missing links'
[[ "$(git config --includes --global alias.co)" == checkout ]] || fail 'Git include not loaded'
bash -c 'source "$HOME/.my_bashrc"; [[ -z ${PROMPT_COMMAND+x} ]]'
cp "$HOME/.bashrc" "$test_dir/bashrc"
cp "$HOME/.my_bashrc" "$test_dir/loader"
run_bootstrap
cmp "$HOME/.bashrc" "$test_dir/bashrc"
cmp "$HOME/.my_bashrc" "$test_dir/loader"
[[ "$(backup_count)" == 0 ]] || fail 'rerun made unnecessary backups'
[[ "$(git config --includes --global --get-all include.path | wc -l | tr -d ' ')" == 1 ]] || fail 'duplicate include'

# Existing user config, including files with no final newline and broken links.
export HOME="$test_dir/existing home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME/.vimrc"
printf 'keep me' > "$HOME/.vimrc/settings"
printf '# keep this' > "$HOME/.bashrc"
printf 'custom loader' > "$HOME/.my_bashrc"
ln -s "$HOME/missing" "$HOME/.tmux.conf"
git config --includes --global user.name 'Existing User'
git config --includes --global user.email 'existing@example.com'
run_bootstrap
[[ "$(git config --includes --global user.name)" == 'Existing User' ]] || fail 'lost Git identity'
[[ "$(git config --includes --global user.email)" == 'existing@example.com' ]] || fail 'lost email'
grep -qxF '# keep this' "$HOME/.bashrc"
for backup in "$HOME"/.dotfiles-backup.*; do
  [[ "$(cat "$backup/.vimrc/settings")" == 'keep me' ]] || fail 'lost Vim directory'
  [[ "$(cat "$backup/.my_bashrc")" == 'custom loader' ]] || fail 'lost loader'
  [[ -L "$backup/.tmux.conf" ]] || fail 'lost broken link'
done
run_bootstrap
[[ "$(backup_count)" == 1 ]] || fail 'rerun changed existing installation'

# Old copied layout with a Git config symlink: retain edits and detach safely.
export HOME="$test_dir/legacy"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME/.me"
printf 'local edit' > "$HOME/.me/local-file"
git config --file "$HOME/.me/gitconfig" user.name 'Legacy User'
ln -s "$HOME/.me/gitconfig" "$HOME/.gitconfig"
run_bootstrap
[[ ! -L "$HOME/.gitconfig" ]] || fail 'Git config still points into checkout'
[[ "$(git config --includes --global user.name)" == 'Legacy User' ]] || fail 'lost legacy identity'
for backup in "$HOME"/.dotfiles-backup.*; do
  [[ "$(cat "$backup/.me/local-file")" == 'local edit' ]] || fail 'lost old .me edits'
done
run_bootstrap
[[ "$(backup_count)" == 1 ]] || fail 'legacy rerun made backups'

# A checkout already at ~/.me must not be moved into its own backup.
export HOME="$test_dir/in-place"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
mkdir -p "$HOME/.me"
cp -R "$repo_dir/into_bashrc" "$HOME/.me/"
cp "$repo_dir/bootstrap.sh" "$repo_dir/gitconfig" "$repo_dir/vimrc" \
  "$repo_dir/tmux.conf" "$repo_dir/tmux-completion.bash" "$HOME/.me/"
bash "$HOME/.me/bootstrap.sh" --skip-install --skip-tpm
[[ -d "$HOME/.me" && ! -L "$HOME/.me" ]] || fail 'moved in-place checkout'

# Existing TPM should never be recloned, even without --skip-tpm.
mkdir -p "$HOME/.tmux/plugins/tpm"
bash "$HOME/.me/bootstrap.sh" --skip-install

# The default path must invoke the installer, including from another directory.
cat > "$HOME/.me/install.sh" <<'INSTALL'
#!/usr/bin/env bash
printf 'called\n' >> "$HOME/installer-calls"
exit "${INSTALL_EXIT_CODE:-0}"
INSTALL
(cd "$test_dir" && bash "$HOME/.me/bootstrap.sh" --skip-tpm)
[[ "$(cat "$HOME/installer-calls")" == called ]] || fail 'default bootstrap skipped installer'
if INSTALL_EXIT_CODE=17 bash "$HOME/.me/bootstrap.sh" --skip-tpm; then
  fail 'bootstrap ignored installer failure'
else
  [[ $? -eq 17 ]] || fail 'bootstrap lost installer exit code'
fi

# Invalid arguments fail before any mutation.
if bash "$repo_dir/bootstrap.sh" --unknown > /dev/null 2>&1; then
  fail 'accepted invalid option'
fi

echo 'All bootstrap checks passed.'
