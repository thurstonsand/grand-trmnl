# Development

## Environment

This plugin lives at `plugins/parcel/` in the grand-trmnl monorepo; paths below are relative to this directory.

```sh
mise trust
mise bootstrap --yes
```

## TRMNL MCP and trmnlp

The `trmnl-development` agent skill connects to TRMNL's remote MCP server when `TRMNL_MCP_API_KEY` is present. MCP complements rather than replaces trmnlp:

- **MCP** inspects hosted merge variables, plugin health and logs, remote markup, recipes, and TRMNL design references. It can also update hosted markup and settings.
- **trmnlp** owns source-controlled local development: serving, polling fixtures, device-accurate PNG rendering, and explicit push/pull operations.

## Project Structure

```text
src/
  full.liquid            # 800×480 — summary header + detailed delivery list
  half_horizontal.liquid # 800×240 — single-line delivery rows
  half_vertical.liquid   # 400×480 — compact delivery list, no header
  quadrant.liquid        # 400×240 — count + next arriving package
  shared.liquid          # Partition preprocessing + reusable partials
  settings.yml           # Plugin config (polling strategy, form fields)
references/
  parcel_response.json   # Dummy Parcel API response for local preview
docs/designs/            # Design docs (numbered, historical artifacts)
.trmnlp.yml              # Local dev overrides (polling URL, custom fields, variables)
```

## Local Preview

```sh
mise run dev parcel   # from repo root; parcel is the default
```

Starts two processes:

- **JSON server** at `http://localhost:8888` — serves `references/parcel_response.json`
- **trmnlp preview** at `http://localhost:4567` — renders all four views with live reload on `src/` changes

The dev server polls `polling_url` from `.trmnlp.yml`, which points at the local JSON server. Edit `references/parcel_response.json` to test different data states — then hit `curl http://localhost:4567/poll` to force a re-fetch (trmnlp caches polled data and `references/` is not in its watch list).

Scenario datasets live in `references/scenarios/` (gitignored, regenerable): `generate.py` writes date-relative fixtures for every state — today/upcoming mixes, all-delivered, overdue, attention, missing dates, dense (18-delivery stress), empty, error — and `render.sh <scenario> <view> <og|x|x-portrait> <out.png>` does the swap + poll + device-accurate render in one step.

## Device-Accurate PNG Renders

The trmnlp render route accepts device parameters directly — the whole device matrix is curl-able. Device classes, dimensions, and scale factors come from `https://trmnl.com/api/models`; trmnlp 0.11 renders at the model's physical pixel dimensions and applies the Framework's logical sizing internally.

| Target | screen_classes | dims (physical) | depth |
| --- | --- | --- | --- |
| OG 1-bit | `screen screen--1bit screen--og_png screen--md screen--density-1x` | 800×480 | 1 |
| OG 2-bit | `screen screen--2bit screen--ogv2 screen--md screen--density-1x` | 800×480 | 2 |
| X landscape | `screen screen--4bit screen--v2 screen--lg screen--density-2x` | 1872×1404 | 4 |
| X portrait | X landscape + `screen--portrait` | 1404×1872 | 4 |

```sh
curl -s -G 'http://localhost:4567/render/full.png' \
  --data-urlencode 'screen_classes=screen screen--4bit screen--v2 screen--lg screen--density-2x' \
  -d width=1872 -d height=1404 -d color_depth=4 -o render.png
```

Swap `full` for any view name. Always judge layouts from PNG renders, not the HTML preview — dithering, text legibility, and clamping only show up in the rendered image.

## Deploying

```sh
trmnlp login                    # one-time auth
trmnlp push -d plugins/parcel   # from repo root (--force to skip confirmation)
```

`src/settings.yml` must keep its `id:` — without it, push creates a new plugin instead of updating.

## Linting

```sh
mise run lint   # markdownlint on all Markdown files
```

## Merge Variables

Templates receive the Parcel API response directly. Key fields:

- `success` (bool) — `false` means show `error_message`
- `deliveries` (array) — each entry has `description`, `status_code`, `carrier_code`, `tracking_number`, `date_expected`, `extra_information`, and `events[]`
- `events[].event`, `events[].date`, `events[].location`

### Status Codes

| Code | Label |
| --- | --- |
| 0 | Delivered |
| 1 | Frozen |
| 2 | In Transit |
| 3 | Pickup |
| 4 | Out for Delivery |
| 5 | Not Found |
| 6 | Failed Attempt |
| 7 | Exception |
| 8 | Info Received |

### Edge Cases to Handle

- `success` false → display `error_message`
- `deliveries` empty → "No deliveries" message
- `date_expected` missing → hide ETA
- `events` empty → hide latest event
- `events[0].location` missing → hide location

## Gotchas

- **`trmnlp lint` is a useful static check, but render-based verification remains the real gate.**
- **Lists use Framework 3.2's official `.columns > .column` overflow contract.** Fixed responsive column counts avoid the browser-sensitive best-fit optimizer; the runtime chooses visible rows from the available height and adds an honest "and N more" counter. Because trmnlp renders with Firefox while production uses Chromium, validate overflow behavior on real devices after publishing.
- **Titles wrap, never truncate.** Overflow accounts for their rendered height; the plugin does not use the clamp runtime.
- **trmnlp 0.11's render route takes TRMNL X's physical resolution** (1872×1404 landscape) while Framework classes retain its 1040×780 logical geometry and 1.8 pixel ratio.

## TRMNL-Specific Best Practices

1. Design for all four TRMNL view sizes: `full`, `half_horizontal`, `half_vertical`, and `quadrant`.
2. Respect the fixed TRMNL structure: a `.layout` container and optional `.title_bar`.
3. Prefer strong information hierarchy over density; e-paper works best when the answer is obvious.
4. Style with framework primitives (`value--*`, `title--*`, `label`, `description`, `gap--*`) so responsive prefixes (`lg:`, `portrait:`, bit-depth) can adapt one markup set across devices; custom px CSS is invisible to them.
5. Favor black/white contrast and intentional dither rather than faux-color thinking.
6. Assume refresh happens on the scale of minutes, so the interface should feel ambient rather than live.
7. Omit low-value metadata unless it materially improves the glance experience.
8. Test every layout independently; mashup-sized variants are first-class, not afterthoughts.
