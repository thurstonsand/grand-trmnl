# AGENTS.md

A monorepo of TRMNL e-paper plugins. Every screen departs from here.

## Structure

Each plugin lives in `plugins/<name>/` as a self-contained trmnlp project: `src/` (templates + settings.yml), `.trmnlp.yml`, its own `AGENTS.md`, `CONTEXT.md`, `PRODUCT.md`, `DEV.md`, and `docs/designs/`. Read the plugin's own docs before working on it.

Shared at the root: mise owns the whole environment (`mise.toml` — Debian/macOS packages, env loading, tool pins, tasks, and git hooks via hk), plus renovate config, markdownlint, and the `trmnl-development` skill (`.agents/skills/`) — TRMNL platform knowledge, framework reference, and hard-won gotchas that apply to every plugin.

## Working here

- `mise run dev [plugin]` — local preview (defaults to `parcel`)
- `mise run lint` — markdownlint across the repo; also runs as a pre-commit gate
- `trmnlp push -d plugins/<name>` — deploy one plugin (only with explicit approval; `settings.yml` must keep its `id:`)
- Judge every layout change from device-accurate PNG renders, never the HTML preview alone; each plugin's DEV.md carries the render recipes.

## Plugins

| Plugin | Purpose |
| --- | --- |
| `parcel` | Parcel package tracking — delivery anticipation at a glance |
