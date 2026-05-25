# Elpris Widget

Displays the actual Danish electricity price hour by hour for Brænderigården 7, 7500 Holstebro
on the Gasel "El til børspris + 6 øre" agreement with grid operator L-net (DK1).

Designed for the Corsair Xeneon Edge display as an iCUE widget.

## Contents
- `CLAUDE.md` — project context and coding principles (auto-loaded by Claude Code)
- `docs/elpris-spec.md` — full price calculation, constants and sources (the source of truth)
- `docs/plan.md` — implementation plan with Warm Amber design tokens
- `docs/` — iCUE Widget Builder concept documentation
- `references/` — iCUE Widget Builder technical references
- `skill.md` — iCUE widget builder skill (installed as `.claude/commands/icue-widget-builder.md`)

## Data Source
Spot price from elprisenligenu.dk (DK1). All other tariffs are fixed constants, see `docs/elpris-spec.md`.

## Getting Started
Open the folder in Claude Code and run `/icue-widget-builder` to start the widget build workflow.
