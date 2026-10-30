# General dotfiles

Bash, Vim, Git, and tmux settings for development machines.

## Install dotfiles

The default bootstrap provisions an Ubuntu/Debian development machine, including
OpenCode and Paseo. Run as root or as a user with sudo access. Requires Bash and
Git to start. Keep the checkout: installed files link back to it, and
aliases such as `editbash` edit the tracked files directly.

```bash
git clone https://github.com/michaelfeil/generaldotfiles.git
cd generaldotfiles
bash bootstrap.sh
source ~/.bashrc
```

`bootstrap.sh` links the checkout at `~/.me`, generates `~/.my_bashrc`, and adds
one source line to `~/.bashrc`. It then runs `install.sh` automatically and installs
TPM if absent. It installs links for Vim and tmux, and adds a Git
include to your existing `~/.gitconfig`, preserving your Git identity and other
settings. Included settings take precedence over earlier settings with the same
key; put any overrides after the include. The installer supplies Michael's Git
identity only if one is not already configured.

Existing files or directories that need replacement are moved to a printed
`~/.dotfiles-backup.*` directory. Repeating setup from the same checkout does not
duplicate source lines or Git includes. Old installations with a copied `~/.me`
directory are backed up too; reconcile any local edits with the checkout.

For dotfiles only (including on macOS), skip provisioning. To also avoid the TPM
download for offline setup, use:

```bash
bash bootstrap.sh --skip-install --skip-tpm
```

The shell settings are for interactive Bash. Configure `.bashrc` loading in your
login profile if your terminal starts a login shell. Optional aliases require the
corresponding tools (for example kubectl, Docker, fzf, or Poetry).

## Provision a development server

`bootstrap.sh` runs `install.sh` by default. You can also run `bash install.sh`
directly. It installs system dependencies, Node LTS under `~/.local`, OpenCode,
Paseo (`@getpaseo/cli`), Codex, Claude Code, uv, Ruff, Poetry, Rust, and k9s.
`~/.local/bin` and `~/.opencode/bin` are added to Bash's
PATH. Bootstrap stops if provisioning fails.

Install methods: [OpenCode](https://opencode.ai/docs/),
[Paseo](https://paseo.sh/docs), [Node via n](https://github.com/tj/n), and
[k9s Debian package](https://github.com/derailed/k9s#installation).

After setup, run `opencode` to authenticate your provider, then `paseo` to start
its daemon and set up pairing. These interactive steps are separate from install.

VS Code CLI installation, tunnel login, and tunnel startup are handled manually.
Neither bootstrap nor install performs tunnel setup. The standalone
`tunnel_code.sh` and `kill_vscode.sh` helpers remain available for manual use.

## Verify changes

```bash
bash tests/bootstrap.sh
bash tests/install.sh
```

The checks use temporary home directories, disable TPM downloads, and stub
external installation commands. They verify that default bootstrap invokes the
installer, installs the requested agent packages, and propagates failures. They
do not install packages or modify your real shell settings.
