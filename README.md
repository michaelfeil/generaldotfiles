# General dotfiles

Bash, Vim, Git, tmux, Codex, and OpenCode settings for development machines.

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
settings. Bootstrap also links `codex/config.toml` and `codex/AGENTS.md` into
`~/.codex`, and `opencode/opencode.json` into
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json`.
Included settings take precedence over earlier settings with the same
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
The installer checks that Node.js is 22+ for `opencode-mcp` 3.x.
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

## Baseten credentials

```bash
export BASETEN_API_KEY="<your-baseten-api-key>"
codex
```

After changing environment variables, restart the Codex process or app so its MCP
child processes inherit them. For a desktop app, configure the key in its launch
environment or secret integration; exporting it in an unrelated terminal is not
enough.

Set `BASETEN_API_KEY` to a real value only in your shell or secret manager. The
placeholder above contains no secret. Codex inherits the exported variable from
its parent environment, and the MCP/OpenCode child processes can use it. Do not
commit keys to this repository.

## Verify changes

```bash
bash tests/bootstrap.sh
bash tests/install.sh
```

The checks use temporary home directories, disable TPM downloads, and stub
external installation commands. They verify that default bootstrap invokes the
installer, installs the requested agent packages, and propagates failures. They
do not install packages or modify your real shell settings.

## OpenCode permissions

This repository recommends permissive defaults for unattended OpenCode work.
The shipped `opencode/opencode.json` contains only the schema and:

```json
{ "permission": "allow" }
```

This makes OpenCode run its tools without approval prompts. The grant applies to
OpenCode tool approval only: it does not grant OS/root access, bypass container
or hosting limits, or change Codex's parent policy. OpenCode merges config, and
project or agent permissions can override or restrict global defaults; explicit
denies still apply. Use `opencode --auto` only when you similarly accept
auto-approval while keeping explicit denies.

## Existing OpenCode config

Before running `bootstrap.sh`, inspect and back up existing
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json` and `opencode.jsonc`
files. OpenCode supports both JSON and JSONC and merges config sources, but
bootstrap replaces the `opencode.json` path with a symlink to this repository.
Consolidate existing JSON/JSONC settings rather than relying on competing files
in the same directory. Preserve the settings you need, then run
`opencode debug config` from the target project to check the effective config.
Do not assume the global permissive setting bypasses project or agent
restrictions.

## Codex and the OpenCode MCP

`codex/config.toml` starts `opencode-mcp@3.1.0` with `OPENCODE_AUTO_SERVE=true`
and Baseten as the default provider. `codex/AGENTS.md` is symlinked to
`~/.codex/AGENTS.md`; it records the delegation contract, preferred Baseten
models, session/redirect behavior, and the rules for reviewing and validating
delegated work. The MCP auto-serves OpenCode; do not start another server.

## Verify delegation

Ask Codex to call `opencode_setup`, then `opencode_context` with the absolute
project directory. Discover Baseten models with `opencode_provider_list` and
`opencode_provider_models`, then pass both `providerID: "baseten"` and the
selected `modelID` explicitly. Prefer `deepseek-ai/DeepSeek-V4.1-Flash-1017-Fast`
when available; discover an alternative rather than assuming the name exists.
Start with a read-only task such as explaining the project structure.

If work pauses, inspect permission requests and questions; project or agent
rules may restrict the global default. Reuse returned session/job/message IDs
after observation timeouts. For ordinary follow-ups use `opencode_reply` when
idle; to redirect active work, abort and then reply in the same session.
Review the actual diff and validate the result before accepting changes.

## References

- [OpenCode permissions](https://opencode.ai/docs/permissions/)
- [OpenCode config](https://opencode.ai/docs/config/)
- [opencode-mcp source](https://github.com/AlaeddineMessadi/opencode-mcp)
