# Agent instructions

## Subagent models

- **Cursor:** Always use Auto or Composer for subagents.
- **Claude:** Always use Haiku 5.5 for subagents, or Sonnet 5.5 when the task is complex.

## CI after push

Whenever you push, spawn a subagent whose job is to wait for CI. If CI fails, it wakes you; do not sit on the run yourself.
