# Global Codex guidance

## OpenCode MCP

Use the `opencode` MCP tools for delegated work. Project-level `AGENTS.md` overrides this section.

### Models

Use **Baseten**. The MCP config pins `OPENCODE_DEFAULT_PROVIDER=baseten`, but
opencode-mcp only applies defaults when both provider and model are supplied, so
always pass both `providerID: "baseten"` and a `modelID` from
`opencode_provider_models`.

- Prefer `deepseek-ai/DeepSeek-V4.1-Flash-1017-Fast` when it is available; it is
  a good default.
- Otherwise choose any available Baseten model, such as
  `deepseek-ai/DeepSeek-V4.1-Flash-Fast` or `zai-org/GLM-5.3-Fast`.
- Do not fall back to non-Baseten models unless no Baseten model is available.

### Start

- `opencode_setup` first, then `opencode_context` with an absolute `directory`.
- Use `opencode_project_init` when the directory does not exist.
- Discover models with `opencode_provider_list` and `opencode_provider_models`.

### Tools

- `opencode_ask` — one-shot question or instruction; creates a session.
- `opencode_reply` — synchronous follow-up in an existing session.
- `opencode_message_send_async` — queued async follow-up; returns `messageId`. Observe with `opencode_wait({sessionId, messageId})`. It does not establish live steering of a running turn; use `opencode_session_abort` to stop work.
- `opencode_run` — dispatch and observe for a bounded time; returns a durable `jobId`; timeouts are resumable.
- `opencode_fire` — background dispatch; save `jobId`, `sessionId`, and `messageId`.
- `opencode_check` — cheap status, todos, and pending input; prefer this over full history.
- `opencode_wait` — wait for a session, job, or specific message; timeouts are resumable.
- `opencode_job_get` / `opencode_job_list` / `opencode_job_cancel` — inspect or stop durable jobs.
- `opencode_events_poll` — bounded polling only (`durationMs` default 3000, max 30000; `maxEvents` max 1000). It is not a push subscription; connection failures return partial events, and stopping does not abort remote work. Not a completion signal.
- `opencode_review_changes` — formatted diff of changes after completion.
- `opencode_conversation` — full history; use bounded reads only when needed.
- Session/input: `opencode_session_*`, `opencode_question_*`, `opencode_permission_*`.
- Read-only inspection: `opencode_file_*`, `opencode_find_*`, `opencode_vcs_info`.

### Rules

- Keep returned `jobId`, `sessionId`, and `messageId`.
- A timeout is not failure. Resume with `opencode_check`, `opencode_wait`, or `opencode_job_get`; never re-dispatch duplicate work.
- Pass absolute directories on the OpenCode host.
- Use `opencode_review_changes` after completion.
- `OPENCODE_AUTO_SERVE=true` is configured; do not start a second OpenCode server.

### Typical flow

1. `opencode_setup` + `opencode_context`
2. `opencode_run` or `opencode_fire` with a Baseten model
3. `opencode_check` / `opencode_wait`
4. `opencode_review_changes`
5. `opencode_message_send_async` + `opencode_wait` for follow-ups
