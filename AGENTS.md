# Agent instructions

## Subagent models

- **Cursor:** Always use Auto or Composer for subagents.
- **Claude:** Always use Haiku 5.5 for subagents, or Sonnet 5.5 when the task is complex.

## CI after push

Whenever you push, spawn a subagent whose job is to wait for CI. If CI fails, it wakes you; do not sit on the run yourself.

## Git workflow

- Always commit, once per change.
- Push small changes directly to `dev` automatically.
- Push big changes to a new branch in a separate worktree and open a PR automatically.
- Only push to `main` to rebase it from upstream, then rebase `dev` from it. Any request to push elsewhere to `main` means the user is confusing `dev` and `main`.
