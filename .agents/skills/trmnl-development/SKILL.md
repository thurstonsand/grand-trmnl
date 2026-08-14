---
name: trmnl-development
description: "Build plugins for TRMNL e-paper displays. Use when creating, debugging, deploying, or modifying TRMNL plugins, working with the TRMNL API, or designing layouts for e-paper screens."
---

# TRMNL Plugin Development

Develop locally with `trmnlp`; use TRMNL's MCP as the current design reference and hosted control plane.

## Choose the Right Interface

The interfaces overlap only at the hosted markup boundary:

- **MCP**: inspect and update the configured hosted integration, settings, markup, merge variables, logs, recipes, API documentation, and framework guidance.
- **trmnlp**: own source-controlled development, fixture polling, hot reload, local linting, device-accurate PNG rendering, clone/pull, and whole-plugin push.

Use MCP reads freely while investigating. Treat markup/settings writes and `trmnlp push` as production changes: inspect the current hosted state first, preserve the plugin `id`, make the requested source change locally, render it, then mutate production only when the user has requested deployment. Read logs and hosted state after deployment to verify it.

Never print API keys, secret custom fields, polling headers, or secret-bearing merge variables.

## MCP-First Reference

Do not rely on memorized framework syntax. The skill's MCP connection is version-aware and reports the framework version pinned by the hosted integration.

- `DesignSystemTemplateGuideTool` — authoritative framework concepts and syntax. Call it without a section to get the index, then request only relevant sections. It covers structure, data flow, layout, typography, items, runtime engines, responsive design, Liquid, transforms, form fields, e-ink design, and the framework supplement.
- `DesignSystemReferenceTool` — canonical markup examples. Call `example_type: index` to discover examples, then request the relevant example and markup size. Current examples include values, stats, text, tables, and lists.
- `APIEndpointsSearchTool` — current API endpoint documentation instead of copied endpoint tables.
- `RecipesSearchTool` and `RecipesPullMarkupTool` — production examples when canonical snippets are insufficient.
- `IntegrationsShowTool`, `MergeVariablesShowTool`, `MarkupsListSizesTool`, and `MarkupsReadTool` — inspect the actual hosted contract before changing it.
- `IntegrationsLogsTool` — hosted health and post-deployment diagnosis.

The hosted integration exposes full, half-horizontal, half-vertical, quadrant, and shared markup. `MarkupsWriteTool` and `IntegrationsWriteSettingsTool` can update production directly and broadcast markup changes to the browser editor.

MCP documentation describes intended production behavior. Local observations below remain relevant where trmnlp's Firefox renderer differs from TRMNL's Chromium renderer.

## Repository Workflow

Read the target plugin's `AGENTS.md`, `CONTEXT.md`, `PRODUCT.md`, and `DEV.md` before editing it.

Typical loop:

1. Inspect hosted state and live merge variables with MCP when production behavior matters.
2. Modify source-controlled templates and settings locally.
3. Run the plugin's local preview and force a fresh poll after fixture changes.
4. Render representative states for every affected view and target device.
5. Inspect the PNGs; HTML preview is not verification.
6. Run repository lint/check tasks.
7. On an explicit deployment request, push the source-controlled plugin or write the reviewed markup/settings through MCP.
8. Inspect hosted logs, settings, and markup after deployment.

## Local Development with trmnlp

Useful commands:

```bash
trmnlp init my_plugin
trmnlp serve -d plugins/my_plugin
trmnlp build -d plugins/my_plugin --png
trmnlp lint -d plugins/my_plugin
trmnlp login
trmnlp list
trmnlp clone name id
trmnlp pull -d plugins/my_plugin
trmnlp push -d plugins/my_plugin
```

Important behavior:

- `init` creates a subdirectory and its own repository scaffolding.
- `src/settings.yml` must retain its `id`; without it, push creates a plugin instead of updating one.
- `push` prompts by default; `--force` makes an approved deployment non-interactive.
- PNG rendering requires Firefox and ImageMagick.
- trmnlp caches polled data. After changing an unwatched fixture, `GET /poll` on the preview server forces a re-fetch.
- The render route is `/render/<view>.png` and accepts `screen_classes`, `width`, `height`, and `color_depth`. Use the exact parameters documented by the plugin; they vary across trmnlp releases.
- Use `https://trmnl.com/api/models` when current device classes, dimensions, or scale factors are needed.

### Local Polling Override

`.trmnlp.yml` is local-only. Override `polling_url` under `variables.trmnl.plugin_settings`:

```yaml
watch:
  - src
  - .trmnlp.yml
variables:
  trmnl:
    plugin_settings:
      polling_url: http://localhost:8888/data.json
```

Without this override, a production URL containing form interpolation can become an invalid local URI and fail without useful template data.

## Render Verification

Always judge layout changes from generated PNGs at the target bit depth. The HTML preview cannot prove dithering, text legibility, overflow, clamp behavior, or final geometry.

Cover:

- all affected view sizes, including mashup views;
- OG 1-bit and larger 4-bit devices when the plugin supports both;
- portrait when responsive markup changes;
- empty, error, sparse, dense, missing-field, and long-text states relevant to the change.

Firefox may clamp viewport widths below roughly 500 px. A direct 400 px screenshot failure does not prove the Rack fixture server or template failed; use trmnlp's supported device render route and the plugin's documented recipe.

## Verified Renderer Caveats

trmnlp deliberately renders with Firefox, while TRMNL production uses headless Chromium. Framework runtime engines can diverge between them.

- Overflow requires the documented `.columns > .column` structure. Fixed column counts are safer than the best-fit optimizer.
- Under load, Firefox has silently dropped items, omitted overflow counters, and corrupted best-fit layouts.
- `clamp--N` and `data-clamp` have been inert in local Firefox renders even when production supports them. Design for wrapped text unless production has been verified.
- If omission must be honest, deterministic Liquid limits plus an authored “and N more” row are browser-independent.
- `.divider` can render as a thick dithered band on 1-bit screens. Use a 2 px solid border for a crisp separator unless the overflow engine must manage divider visibility.

These are empirical constraints, not replacements for MCP framework documentation.

## E-Paper Design Rules

- One source template set serves devices through framework size, orientation, and bit-depth variants.
- Start with black and white. Add framework gray tokens only for intentional de-emphasis.
- Use framework primitives so responsive variants can adapt the design; custom pixel CSS cannot.
- Prefer strong hierarchy and glanceable answers over density.
- Refresh happens in minutes, so design ambient snapshots rather than live interfaces.
- Use solid shapes, bold text, and borders at least 2 px on 1-bit screens.
- Validate gray text on the actual 1-bit render; shades that look restrained in HTML can become illegible.
- Budget vertical space before implementation and treat every mashup view as a first-class design.

## Fallback Sources

If MCP is unavailable, use the authoritative upstream sources:

- [Framework documentation](https://trmnl.com/framework)
- [TRMNL documentation index](https://trmnl.com/llms.txt)
- [trmnlp](https://github.com/usetrmnl/trmnlp)
- [Open-source plugin examples](https://github.com/usetrmnl/plugins)
