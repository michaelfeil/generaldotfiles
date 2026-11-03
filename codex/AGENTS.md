# Global Codex guidance

## GitHub access

Use the GitHub CLI (`gh`) instead of the GitHub connector for GitHub operations.

## Delegation contract

Every OpenCode delegation must include:

- An explicit task, not just a topic.
- The absolute project path on the OpenCode host.
- Relevant context and constraints, including the desired scope and what not to change.
- The expected result and how to validate it (tests, commands, or review criteria).

Do not assume OpenCode inherits this chat or Codex's instructions; it starts
from its own context. Restate the minimum needed. Before relying on absolute
paths or uncommitted changes, verify both agents see the same shared workspace.
A session ID is not filesystem isolation.

## OpenCode MCP

Use the `opencode` MCP tools for delegated work. Project-level `AGENTS.md`
overrides this section.

### Models

Use **Baseten**. The MCP config pins `OPENCODE_DEFAULT_PROVIDER=baseten`, but
opencode-mcp only applies defaults when both provider and model are supplied, so
always pass both `providerID: "baseten"` and a `modelID` from
`opencode_provider_models`.

- Prefer `deepseek-ai/DeepSeek-V4.1-Flash-1017-Fast` when available.
- Otherwise choose any available Baseten model, such as
  `deepseek-ai/DeepSeek-V4.1-Flash-Fast` or `zai-org/GLM-5.3-Fast`.
- Do not fall back to non-Baseten models unless no Baseten model is available.

### Start

- Call `opencode_setup`, then `opencode_context` with an absolute `directory`.
- Use `opencode_project_init` when the directory does not exist.
- Discover models with `opencode_provider_list` and `opencode_provider_models`.

### Permissions

Keep the shipped `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json` permissive
(`permission: "allow"`) for unattended delegation. It covers OpenCode tool
approval only; it does not grant OS/root access, bypass hosting limits, or
change Codex policy. Config is merged, project config can override global
defaults, and agent permissions take precedence. Explicit denies remain. If
OpenCode pauses on a question or permission, inspect it and resolve it within
the user's authorization. Ask only when required information or authorization
is missing; do not widen scope or edit config to bypass a deny.

### Conversation and redirects

- `opencode_reply` sends a synchronous follow-up and waits for the response. Use
  it normally when the session is idle.
- `opencode_message_send_async` queues a follow-up while the session is busy and
  returns `messageId`; observe it with `opencode_wait`.
- Neither guarantees live steering of an active turn. To redirect work, call
  `opencode_session_abort`, then send the corrected follow-up in the same
  session; do not start an unrelated duplicate session.
- `noReply` context injection is available on lower-level message sends but is
  not guaranteed to steer a running turn.

### Tools

- `opencode_ask` — one-shot question or instruction; creates a session.
- `opencode_run` — dispatch and observe for a bounded time; returns a resumable
  `jobId`.
- `opencode_fire` — background dispatch; save `jobId`, `sessionId`, and
  `messageId`.
- `opencode_check` — cheap status, todos, and pending input; prefer this over
  full history.
- `opencode_wait` — wait for a session, job, or message; timeouts are resumable.
- `opencode_job_get` / `opencode_job_list` / `opencode_job_cancel` — inspect or
  stop durable jobs.
- `opencode_events_poll` — bounded polling only; not a push subscription or
  completion signal.
- `opencode_review_changes` — formatted diff after completion.
- `opencode_conversation` — full history; use bounded reads only when needed.
- Session/input: `opencode_session_*`, `opencode_question_*`,
  `opencode_permission_*`.
- Read-only inspection: `opencode_file_*`, `opencode_find_*`, `opencode_vcs_info`.

### Rules

- Keep returned `jobId`, `sessionId`, and `messageId`.
- A timeout is not failure. Resume with `opencode_check`, `opencode_wait`, or
  `opencode_job_get`; never re-dispatch duplicate work.
- Pass absolute directories on the OpenCode host for each call.
- `OPENCODE_AUTO_SERVE=true` is configured; do not start a second server.
- Review changes with `opencode_review_changes` and the actual workspace diff
  (including untracked files); an empty tool diff is not proof of no changes.
  Validate the claimed result yourself; the parent owns final acceptance.

### Typical flow

1. `opencode_setup` + `opencode_context`
2. `opencode_run` or `opencode_fire` with a Baseten provider/model
3. `opencode_check` / `opencode_wait`
4. `opencode_review_changes`, then parent validation
5. Use `opencode_reply` normally when idle; use async + `opencode_wait` when
   appropriate, or abort then reply in the same session to redirect.
