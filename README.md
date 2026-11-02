# General dotfiles

Personal Bash, Vim, tmux, Git, Codex, and OpenCode configuration.

## What bootstrap.sh installs

`bootstrap.sh` is the user-level dotfiles installer. It:

- replaces `~/.me` with a copy of this repository;
- writes `~/.my_bashrc` from `into_bashrc/*` and sources it from `~/.bashrc`;
- symlinks `vimrc`, `gitconfig`, `tmux.conf`, and `tmux-completion.bash`;
- symlinks `codex/config.toml` and `codex/AGENTS.md` into `~/.codex`;
- symlinks `opencode/opencode.json` to
  `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json`;
- clones tmux plugin manager into `~/.tmux/plugins/tpm`.

It does not install packages, create API keys, or log in to services. Existing
files at the symlink destinations are replaced; back up your own configs first.

## bootstrap.sh vs install.sh

- `bootstrap.sh` is the normal, user-level setup. It needs no root access and
  only clones tpm from the network.
- `install.sh` is opinionated Linux provisioning: it uses apt/root, installs a
  full toolchain, configures Git, installs the VS Code CLI, logs in to a tunnel,
  and starts a tmux session. Run it only on a host you control and expect
  changes to the live environment.

## Prerequisites

- Node.js 22+ for `opencode-mcp` 3.x; `npm`/`npx` must be available.
- `opencode` and `codex` executables on `PATH`.
- A Baseten API key, supplied through `BASETEN_API_KEY`.
- Network access to GitHub, npm, and Baseten for installation and model calls.

## Quick setup

```bash
git clone https://github.com/michaelfeil/generaldotfiles.git
cd generaldotfiles
./bootstrap.sh

export BASETEN_API_KEY="<your-baseten-api-key>"
codex
```

For an existing host with Node.js 22+, install missing CLIs with
`npm install -g @openai/codex` and the [OpenCode installer](https://opencode.ai/docs/).
`install.sh` is optional full Linux provisioning, not a prerequisite for bootstrap.
After changing environment variables, restart the Codex process or app so its MCP
child processes inherit them. For a desktop app, configure the key in its launch
environment or secret integration; exporting it in an unrelated terminal is not
enough.

Set `BASETEN_API_KEY` to a real value only in your shell or secret manager. The
placeholder above contains no secret. Codex inherits the exported variable from
its parent environment, and the MCP/OpenCode child processes can use it. Do not
commit keys to this repository.

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
