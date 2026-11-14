# Repo instructions (all agents)

This repo ships one agent skill: `.agents/skills/expensive-brain/SKILL.md`.
The top-level `skills/` is a compatibility symlink for the Claude Code plugin
format — edit only under `.agents/`.

- The SKILL.md is the product. Keep it agent-agnostic: generic actions
  ("dispatch a subagent"), harness specifics only in the per-harness table,
  capabilities phrased conditionally.
- One file, many links: never add per-agent copies of the skill.
