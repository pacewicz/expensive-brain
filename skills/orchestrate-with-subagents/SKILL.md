---
name: orchestrate-with-subagents
description: Use when a Claude Code session on an expensive model (Opus, Fable) is about to search, grep, read many files, run web lookups, survey a codebase, execute a multi-task plan, or do bulk mechanical work, and when about to spawn a subagent without choosing its model.
---

# Orchestrate with subagents

## Core principle

The main session is the **driver and the brain**. It owns the decisions,
the synthesis and the final answer. Everything else (gathering context,
mechanical edits, bulk scans, independent tasks) goes to subagents, which
hand back conclusions instead of raw dumps.

There are two reasons for this:

- **Context.** Each raw `grep`, `ls`, `cat` or search result left in the
  main context is space the final judgement can't use, and it builds up
  fast: three "quick scouts" turn into a page of file dumps.
- **Cost.** Subagents inherit the session model unless you pin another
  one. On an expensive session, inherited fan-out multiplies top-tier cost
  for work that needs no top-tier reasoning.

Spawning one agent costs less than the context and tokens it saves.

## Default behaviour

| Situation | Do |
|---|---|
| Any search, grep, file survey, inventory or web lookup | Spawn a subagent (`model: sonnet`) and consume its summary |
| One dependent lookup with a one-line answer that you need to write the next brief | Run it inline. Two or more lookups are never inline. |
| 2+ independent tasks | Launch the subagents **in one message** so they run in parallel |
| Plan with 2+ tasks | Use subagent-driven execution. Announce it and proceed; don't ask "which approach?" |
| Trivial, single-task or one-shot work | Do it inline |
| Final merge, dedupe, verdict, design, adversarial review | Keep it in the main session |

## Model tiering: always pass `model` explicitly

| Tier | Use for |
|---|---|
| `haiku` | Read-only bulk triage: logs, notes, transcripts, Grep/Glob lookups. Chunk inputs to about 150k tokens per call, and verify any quoted line against the source before acting on it. |
| `sonnet` | Default worker: research, search, mechanical edits, and anything that acts on a live system |
| `opus` / session model | Hard reasoning only: adversarial verification, judging, design |

- If you omit `model`, the subagent **inherits the session model**. On an
  expensive session that is the costly default, so make it a deliberate
  choice.
- `subagent_type: "fork"` **always inherits the parent model and ignores
  `model`**. When you want a cheaper model, use a fresh `general-purpose`
  agent (or another type).
- Before a large fan-out (roughly 5+ agents), run **one** first as a cost
  canary. Read what it actually cost, then size the batch to the remaining
  budget.

## The brief: the only context the subagent gets

Write each brief with these parts, in this order:

1. **Goal**: what the result is for, in one or two sentences.
2. **Known / ruled out**: facts you already have, so it doesn't
   rediscover them.
3. **Where to look**: paths, docs, commands. Point at them; don't paste
   their contents.
4. **Scope**: read-only or allowed to edit, and what is out of bounds.
5. **Return shape**: conclusions plus the exact quoted lines that support
   them. Any "not found" must include the command it ran and that
   command's output.

If a brief hands over a credential, it must also ban header-echoing debug
flags (`curl -v`, `curl -i`, `set -x`). "Never print the secret" does not
stop a tool that echoes its own input.

## After it returns

- A subagent's report is a **claim**. Before you repeat a load-bearing
  fact to the user or act on it, spot-check it (open the quoted line, re-run
  the one command).
- Its final report is not shown to the user. Relay what matters.
- Don't redo work you delegated. Wait for the notification instead of
  polling, and don't predict the result.

## Rationalizations

| Thought | Reality |
|---|---|
| "It's just one quick grep" | That is how it starts: three scouts become a page of dumps. Delegate it. |
| "Faster to do it myself" | Wall-clock is similar. The context and cost are not. |
| "I need the raw output to judge" | You need the right excerpt, so ask for quoted lines. |
| "Spawning costs more than the command" | A spawn is cheap. Top-tier tokens spent on search results are not. |
| "I'll just inherit the model, simpler" | Inheriting is the most expensive choice. Pick the tier. |
| "Fork is easier, it has my context" | A fork ignores `model` and runs on the expensive tier. |
| "Should I ask the user how to execute the plan?" | If it has 2+ tasks, go subagent-driven and say so. |

## Red flags (stop and delegate)

- The main context has started collecting tool output you won't quote in
  the answer.
- You're about to run a second lookup inline.
- An `Agent` call has no `model`, and the session model is Opus or Fable.
- An `Agent` call uses `fork` for mechanical work.
- Several independent agents are going out one message at a time.
