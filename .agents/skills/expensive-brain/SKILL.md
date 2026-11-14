---
name: expensive-brain
description: Use when a coding-agent session running an expensive model is about to search, grep, read many files, run web lookups, survey a codebase, execute a multi-task plan or do bulk mechanical work, or when it is about to dispatch a subagent without choosing that subagent's model.
---

# Expensive brain

## Core principle

The main session is the **driver and the brain**. It owns decisions,
synthesis and the final answer. Everything else is dispatched to
subagents: context gathering, mechanical edits, bulk scans and independent
tasks. Subagents return conclusions, not raw dumps.

There are two reasons:

- **Context.** Every raw `grep`, `ls`, `cat` or search result in the main
  context is space the final judgement can't use, and it adds up. Three
  "quick scouts" turn into a page of file dumps.
- **Cost.** A subagent usually inherits the session model unless you pin a
  different one. On an expensive session, inheriting multiplies top-tier
  cost for work that needs no top-tier reasoning.

The trade-off: dispatching costs some wall-clock time (expect roughly 2x
on a small lookup). In return you save top-tier tokens and keep the main
context clean. Pay that price on any lookup that would put more than a
screenful of tool output into the main context.

## Default behaviour

| Situation | Do |
|---|---|
| Any search, grep, file survey, inventory or web lookup | Dispatch a subagent on a mid-tier model and use its summary |
| One dependent lookup with a one-line answer that you need in order to write the next brief | Run it inline. Two or more lookups are never inline. |
| 2+ independent tasks | Dispatch all of them **in one response** so they run in parallel |
| A plan with 2+ tasks | Execute it subagent-driven. Announce that and proceed; don't ask "which approach?" |
| Trivial, single-task or one-shot work | Do it inline |
| Final merge, dedupe, verdict, design or adversarial review | Keep it in the main session |
| The harness has no subagent tool | Work inline. Don't invent tool calls. |

## Model tiering: always set the subagent's model explicitly

| Tier | Use for |
|---|---|
| Cheapest (e.g. haiku) | Read-only bulk triage: logs, notes, transcripts, file and grep lookups. Chunk input to about 150k tokens per call, and check every quoted line against the source before acting on it. |
| Mid (e.g. sonnet) | The default worker: research, search, mechanical edits, and anything that acts on a live system |
| Top / session model | Hard reasoning only: adversarial verification, judging, design |

Before a large fan-out (roughly 5+ agents), dispatch **one** agent first as
a cost canary. Read what it actually cost, then size the batch to the
budget you have left.

### Per-harness mechanics

Check this table against your actual tool list. Where they disagree, your
tool list wins.

| Harness | Dispatch | Pin the model | Traps |
|---|---|---|---|
| Claude Code | `Agent` tool | `model: "sonnet"` / `"haiku"` / `"opus"` | `subagent_type: "fork"` always inherits the parent model and ignores `model`. For a cheaper tier, use a fresh `general-purpose` agent. |
| Codex CLI | `spawn_agent` (needs `[features] multi_agent = true`) | Set `model` **and** `reasoning_effort` together; a model alone resets effort to that model's default | Use `fork_turns: "none"` for a clean context. Only use model names from your spawn allowlist. Backstop setting: `[agents] default_subagent_model` in `~/.codex/config.toml`. |
| Gemini CLI | `invoke_agent` (`agent_name: "generalist"`, or `@generalist`) | Per agent definition | Parallelism comes from multiple calls in one response |
| Antigravity (`agy`) | `invoke_subagent` (`research` for read-only work, `self` for full capability) | Per harness | |
| Hermes Agent | `delegate_task(goal=…, context=…, role="leaf")` | Per harness | |

## The brief: the subagent's only context

Write every brief with these parts, in this order:

1. **Goal**: what the result is for, in one or two sentences.
2. **Known or ruled out**: facts you already have, so it doesn't rediscover
   them.
3. **Where to look**: paths, docs and commands. Point to them; don't paste
   their contents.
4. **Scope**: read-only or allowed to edit, and what is out of bounds.
5. **Return shape**: conclusions plus the exact quoted lines that support
   them. Any "not found" must include the command it ran and that
   command's output.

If the brief hands over a credential, it must also ban header-echoing debug
flags (`curl -v`, `curl -i`, `set -x`). "Never print the secret" does not
stop a tool from echoing its own input.

## After it returns

- The subagent's report is a **claim**. Before you repeat a load-bearing
  fact or act on it, spot-check it: open the quoted line, or re-run the one
  command.
- The user may not see the subagent's report. Relay what matters.
- Don't redo work you've delegated, and don't predict its result. Wait for
  it to complete.

## Rationalizations

| Thought | Reality |
|---|---|
| "It's just one quick grep" | That's how it starts; three scouts turn into a page of dumps. Delegate it. |
| "Faster to do it myself" | It is faster, by about 2x on wall-clock. It also costs top-tier tokens and fills the context the final answer needs. |
| "I need the raw output to judge" | You need the right excerpt, so ask for quoted lines. |
| "Dispatching costs more than the command" | A dispatch is cheap. Top-tier tokens spent reading search results are not. |
| "I'll just inherit the model, simpler" | Inheriting is the most expensive choice. Pick the tier. |
| "A full-context fork is easier" | A fork may ignore the model override and run on the top tier. Write a brief. |
| "Should I ask how to execute this plan?" | If it has 2+ tasks, go subagent-driven and say so. |

## Red flags: stop and delegate

- The main context is collecting tool output you won't quote in the
  answer.
- You're about to run a second lookup inline.
- A dispatch has no explicit model, and the session runs a top-tier model.
- You're forking for mechanical work.
- You're dispatching independent agents one response at a time.
