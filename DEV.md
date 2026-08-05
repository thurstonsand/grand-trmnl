# Development

## Environment

All tooling is pinned in `.mise.toml` (Ruby, Python, trmnlp via the gem backend, markdownlint, renovate); `mise install` sets up everything repo-local. System-level dependencies that mise cannot manage (Firefox as trmnlp's headless render backend, ImageMagick) live in the ansiblonomicon Brewfile.

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
mise run dev
```

Starts two processes:

- **JSON server** at `http://localhost:8888` — serves `references/parcel_response.json`
- **trmnlp preview** at `http://localhost:4567` — renders all four views with live reload on `src/` changes

The dev server polls `polling_url` from `.trmnlp.yml`, which points at the local JSON server. Edit `references/parcel_response.json` to test different data states — then hit `curl http://localhost:4567/poll` to force a re-fetch (trmnlp caches polled data and `references/` is not in its watch list).

Scenario datasets live in `references/scenarios/` (gitignored, regenerable): `generate.py` writes date-relative fixtures for every state — today/upcoming mixes, all-delivered, overdue, attention, missing dates, dense (18-delivery stress), empty, error — and `render.sh <scenario> <view> <og|x|x-portrait> <out.png>` does the swap + poll + device-accurate render in one step.

## Device-Accurate PNG Renders

The trmnlp render route accepts device parameters directly — the whole device matrix is curl-able. Device classes and scale factors come from `https://trmnl.com/api/models`; render at logical resolution (physical ÷ scale factor).

| Target | screen_classes | dims (logical) | depth |
| --- | --- | --- | --- |
| OG 1-bit | `screen screen--1bit screen--og_png screen--md screen--1x` | 800×480 | 1 |
| OG 2-bit | `screen screen--2bit screen--ogv2 screen--md screen--1x` | 800×480 | 2 |
| X landscape | `screen screen--4bit screen--v2 screen--lg screen--1x` | 1040×780 | 4 |
| X portrait | X landscape + `screen--portrait` | 780×1040 | 4 |

```sh
curl -s -G 'http://localhost:4567/render/full.png' \
  --data-urlencode 'screen_classes=screen screen--4bit screen--v2 screen--lg screen--1x' \
  -d width=1040 -d height=780 -d color_depth=4 -o render.png
```

Swap `full` for any view name. Always judge layouts from PNG renders, not the HTML preview — dithering, text legibility, and clamping only show up in the rendered image.

## Deploying

```sh
trmnlp login   # one-time auth
trmnlp push    # upload to TRMNL server (--force to skip confirmation)
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

- **`trmnlp lint` does not exist in trmnlp 0.10.0** despite upstream docs; render-based verification is the real gate.
- **The framework's JS overflow/clamp engines are not used in this codebase, deliberately.** They diverge between trmnlp's Firefox pipeline and production's Chromium (dropped rows, corrupted layouts, inert clamping — see the design doc's Implementation Deviations). All list overflow is deterministic Liquid caps + the shared `manifest_counter` ("and N more") row. Do not reintroduce `data-overflow-*`/`data-clamp` without verifying on production hardware.
- **Titles wrap, never truncate.** Caps are sized for two-line rows; the cap table lives in `docs/designs/02-partition-and-framework-native-layout.md`.
- **TRMNL X renders at logical resolution** (1040×780 = 1872×1404 ÷ 1.8 scale). Device classes and scale factors come from `https://trmnl.com/api/models`.

## TRMNL-Specific Best Practices

1. Design for all four TRMNL view sizes: `full`, `half_horizontal`, `half_vertical`, and `quadrant`.
2. Respect the fixed TRMNL structure: a `.layout` container and optional `.title_bar`.
3. Prefer strong information hierarchy over density; e-paper works best when the answer is obvious.
4. Style with framework primitives (`value--*`, `title--*`, `label`, `description`, `gap--*`) so responsive prefixes (`lg:`, `portrait:`, bit-depth) can adapt one markup set across devices; custom px CSS is invisible to them.
5. Favor black/white contrast and intentional dither rather than faux-color thinking.
6. Assume refresh happens on the scale of minutes, so the interface should feel ambient rather than live.
7. Omit low-value metadata unless it materially improves the glance experience.
8. Test every layout independently; mashup-sized variants are first-class, not afterthoughts.
