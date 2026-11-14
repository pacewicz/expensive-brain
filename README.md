# orchestrate-with-subagents

A Claude Code skill that keeps an expensive session model (Opus, Fable) in the
**driver / brain** role. Search, survey, bulk and mechanical work goes to
subagents pinned to a cheaper model. The main context keeps decisions,
synthesis and the final answer.

It was distilled from the instructions that produce this behaviour in one
long-running Claude Code setup. Nothing in that setup *enforces* delegation
(there are no hooks and no env vars). The behaviour comes from a small set of
rules that are loaded on every session.

## Install

```bash
mkdir -p ~/.claude/skills
cp -r skills/orchestrate-with-subagents ~/.claude/skills/
```

## Make it stick: also add the always-loaded rule

A skill only loads when the model decides its description matches the task,
and a model that is about to "just run one grep" often doesn't stop to check.
What makes the behaviour default is an **always-loaded** rule. Add this to
`~/.claude/CLAUDE.md` (all projects) or to a project's `CLAUDE.md`:

```markdown
## Delegation
- Main context = decisions, synthesis, final answer. Searches, greps, file
  surveys, web lookups and mechanical work go to subagents that return
  conclusions, not dumps. A single one-line dependent lookup may run inline;
  two or more never.
- Always pass `model` on Agent calls: sonnet by default, haiku for read-only
  bulk triage, the session model only for judging/design/adversarial review.
  `fork` ignores `model`, so don't fork grunt work.
- Plans with 2+ tasks: subagent-driven execution; announce, don't ask.
- Independent agents: launch them in one message.
- Details: skill `orchestrate-with-subagents`.
```

The [superpowers](https://github.com/obra/superpowers) plugin
(`subagent-driven-development`, `dispatching-parallel-agents`) pairs well
with this skill. It covers *how* to run a plan through subagents; this skill
covers *when* to delegate and *which model* to use.

## License

MIT
