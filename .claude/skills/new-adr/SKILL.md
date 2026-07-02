---
name: new-adr
description: Scaffold a new MADR architecture decision record in adrs/decisions/. Use when the owner wants to record a new architectural decision. Picks the next free number, starts as Proposed, keeps it decision-level.
disable-model-invocation: true
---

# Scaffold a new ADR

Create a new MADR (adr.github.io/madr) decision record. Title/topic comes from `$ARGUMENTS`.

## Steps

1. Ensure `adrs/decisions/` exists. If `adrs/decisions/0000-template.md` is missing, the tree hasn't been rebuilt yet — tell the owner and ask before creating a template from scratch.
2. Find the next free 4-digit number: list `adrs/decisions/NNNN-*.md`, take `max + 1` (zero-padded, e.g. `0004`). Gaps are fine — never reuse or renumber existing ADRs.
3. Copy `0000-template.md` to `adrs/decisions/NNNN-<short-kebab-title>.md`. Fill in: title, **Status: Proposed**, today's date, and the Context/problem statement from `$ARGUMENTS`. Leave decision drivers, considered options, outcome, and consequences as prompts for the owner to complete.
4. Keep it **decision-level, not detailed** — concrete values (subnets, IDs, ports) go in the tracking issue/config, not the ADR. Reference the related issue / Project #14 item if known.
5. Do **not** commit. Remind the owner: one ADR per PR, branch first, `docs(adr):` commit scope.

Report the new file path and the number chosen.
