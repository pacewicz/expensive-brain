# expensive-brain

An agent skill that keeps an expensive session model (Opus, Fable, a top-tier
Codex preset) in the **driver/brain** role. Search, survey, bulk and mechanical
work goes to subagents pinned to cheaper models. The main context keeps
decisions, synthesis and the final answer.

The skill text is agent-agnostic: actions are phrased generically, and
harness specifics sit in a per-harness table. It covers Claude Code, Codex
CLI, Gemini CLI, Antigravity and Hermes Agent.

## Install

Clone the repo, then symlink the one canonical skill into each agent's
skills directory:

```bash
./install.sh          # symlinks (default)
./install.sh --copy   # copies, for filesystems where symlinks hurt
```

## Make it stick: add the always-loaded rule

A skill loads only when the model decides it's relevant. A model about to
"just run one grep" often doesn't stop to check. Add this rule to whatever
your agent always loads (`CLAUDE.md`, `AGENTS.md` or `GEMINI.md`, at user or
project level):

```markdown
## Delegation
- Main context = decisions, synthesis, final answer. Searches, greps, file
  surveys, web lookups and mechanical work go to subagents that return
  conclusions, not dumps. A single one-line dependent lookup may run inline;
  two or more never.
- Always set the subagent's model explicitly: mid-tier (e.g. sonnet) by
  default, cheapest for read-only bulk triage, the session model only for
  judging/design/adversarial review. Forks that inherit the parent model are
  not for grunt work.
- Plans with 2+ tasks: subagent-driven execution; announce, don't ask.
- Independent agents: dispatch them in one response.
- Details: skill `expensive-brain`.
```

## Does it work?

These are small-sample A/B runs on Claude Code (`claude -p`, Fable 5.2,
vanilla config with no user instructions or plugins). The task was a
read-only "how does feature X work across this Go codebase" question.

| Arm (runs) | Main session | Subagent | Top-tier spend (relative) | Wall-clock |
|---|---|---|---|---|
| No skill (2) | 5 inline grep/bash calls, 0 dispatches | none | 1.0× | ~30 s |
| Skill only (4) | the skill self-triggered, then 1 dispatch | sonnet | ~0.65× | 64–81 s |
| Skill + always-loaded rule (3) | 1 dispatch first | sonnet | ~0.5× | 54–80 s |

The inline lookups in the skill arms came *after* the subagent returned,
as spot-checks of its claims, which is what the skill prescribes. Small n: a signal,
not a benchmark.

## Layout

One canonical file, many links:

- `.agents/skills/expensive-brain/SKILL.md`: the only copy.
- `skills -> .agents/skills`: compatibility path for Claude Code plugins.
- `AGENTS.md`: repo instructions. `CLAUDE.md` and `GEMINI.md` point to it.

## License

MIT
