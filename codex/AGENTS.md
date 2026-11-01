# Global Codex guidance

## OpenCode MCP

The `opencode` MCP server exposes tools named `opencode_*`. Use them when work
should be delegated to OpenCode, or when an existing OpenCode session is
relevant. Project-level `AGENTS.md` files take precedence over this section.

### Start with orientation

- Call `opencode_setup` first. It reports OpenCode server health, configured
  providers, and the current project state.
- Use `opencode_context` to inspect a project's files and instructions.
- Pass an absolute `directory` path on the OpenCode host for project-scoped
  tools. Use `opencode_project_init` when the directory does not exist yet.
- Discover models with `opencode_provider_list` and
  `opencode_provider_models`; pass `providerID` and `modelID`, or rely on the
  configured defaults.

### Choose the right tool

- `opencode_ask` — one-shot question or instruction. Creates a session, sends
  the prompt, and returns the response. Best for short work.
- `opencode_reply` — synchronous follow-up to an existing session. Waits for
  the response.
- `opencode_message_send_async` — non-blocking follow-up to an existing
  session. Returns a `messageId`; observe that exact turn with
  `opencode_wait({sessionId, messageId})` or `opencode_check`. This queues a
  new turn; live steering of an already-running turn is not established. Use
  `opencode_session_abort` to stop work.
- `opencode_run` — dispatch a task and observe it for a bounded period. Returns
  a durable `jobId`; an observation timeout leaves the remote job running and
  can be resumed with `opencode_wait`.
- `opencode_fire` — dispatch a durable background task and return immediately
  with `jobId`, `sessionId`, and `messageId`. Use `opencode_check` or
  `opencode_wait` to observe it.
- `opencode_check` — cheap status: current state, pending input, todos, and file
  counts. Pass `jobId` for exact durable-turn correlation. Use
  `detailed: true` only when response text is needed.
- `opencode_wait` — wait for a session, job, or specific submitted message.
  Timeouts are resumable.
- `opencode_job_get` / `opencode_job_list` — inspect durable jobs.
  `opencode_job_cancel` stops the job's session.
- `opencode_events_poll` — collect project or global events for a bounded
  polling window (`durationMs`, default 3000, max 30000; `maxEvents`, max
  1000). This is polling, not a push subscription; connection failures return
  partial events, and stopping observation does not abort remote work. Do not
  use it as the only completion signal.
- `opencode_review_changes` — formatted diff of all changes in a session.
- `opencode_conversation` — full conversation history. Prefer `opencode_check`
  for status and use bounded reads when history is needed.
- `opencode_session_list`, `opencode_session_get`,
  `opencode_session_status`, `opencode_session_todo`,
  `opencode_session_diff`, `opencode_session_abort`,
  `opencode_session_fork`, and `opencode_session_revert` manage sessions.
- `opencode_question_list`, `opencode_question_reply`, and
  `opencode_question_reject` handle questions from OpenCode.
  `opencode_permission_list` and the permission tools handle approvals.
- `opencode_file_*`, `opencode_find_*`, `opencode_vcs_info`, and
  `opencode_tool_*` provide read-only inspection utilities.

### Operating rules

- Always keep the returned `jobId`, `sessionId`, and `messageId`. They are the
  handles for observation, follow-ups, and review.
- A timeout is not a failure. Do not dispatch the same task again; resume with
  `opencode_wait`, `opencode_check`, or `opencode_job_get`.
- Use `opencode_run` for bounded long work and `opencode_fire` for background
  work. Use `opencode_ask` / `opencode_reply` for short interactions.
- Use `opencode_message_send_async` when you need a queued follow-up without
  blocking. Do not assume it interrupts or steers the current generation.
- Use `opencode_review_changes` after completion, then inspect specific history
  only if needed.
- Project-scoped tools require an absolute directory that exists on the
  OpenCode server. The MCP server is configured with
  `OPENCODE_AUTO_SERVE=true`, so it can start OpenCode automatically; do not
  start a second server manually unless the setup tool reports a conflict.
