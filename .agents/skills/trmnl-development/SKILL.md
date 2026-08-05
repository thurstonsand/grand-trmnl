---
name: trmnl-development
description: "Build plugins for TRMNL e-paper displays. Use when creating, debugging, or modifying TRMNL plugins, working with the TRMNL API, or designing layouts for e-paper screens."
---

# TRMNL Plugin Development

Build and manage plugins for TRMNL e-paper display devices.

## Platform Overview

TRMNL renders HTML/CSS markup as static images for e-paper screens. Plugins define markup templates with Liquid variables; TRMNL's server renders them to images and pushes to devices. The Framework (currently v3.2) provides the CSS utilities and runtime that adapt one set of markup across the whole device family.

### Device Family

| Device      | Screen | Resolution | Bit depth                            | Size class | Notes                                          |
| ----------- | ------ | ---------- | ------------------------------------ | ---------- | ---------------------------------------------- |
| TRMNL OG    | 7.5"   | 800×480    | 1-bit (2-bit opt-in since Aug 2025)  | `md`       | Button on back = force-skip                    |
| TRMNL OG V2 | 7.5"   | 800×480    | 2-bit (4 shades)                     | `md`       |                                                |
| TRMNL X     | 10.3"  | 1872×1404  | 4-bit (16 solid grays, no dithering) | `lg`       | Portrait support, touch bar (tap = force-skip) |

One plugin serves all devices: the same four liquid views render per-device, with the Framework Runtime and responsive prefixes (`lg:`, `portrait:`, `4bit:`) handling adaptation. You never write device-specific markup files.

## Plugin Data Strategies

Private plugins support three strategies for getting data onto the screen:

### Polling (TRMNL fetches your data)

- Provide one or more URLs; TRMNL GETs (or POSTs) them on a schedule
- Response available as Liquid merge variables in markup
- Single URL: `{{ field_name }}` directly
- Multiple URLs: `{{ IDX_0.field_name }}`, `{{ IDX_1.field_name }}`
- Headers: `key=value&key2=value2` format (encode `=` in values as `%3D`)
- Form field interpolation in URL/headers/body: `##{{ form_field_keyname }}`
- Supports JSON, RSS, XML, plaintext, CSV responses

### Webhook (you push data to TRMNL)

- POST to `https://trmnl.com/api/custom_plugins/<plugin_uuid>`
- Payload: `{"merge_variables": {"key": "value"}}`
- Rate limit: 12/hr (30/hr for TRMNL+), max 2kb (5kb TRMNL+)
- GET same endpoint to fetch current merge variables
- `deep_merge` strategy: merges nested keys into existing data
- `stream` strategy: appends to arrays, use `stream_limit` to cap size

### Plugin Merge (combine native plugin data)

- Install + hide a native plugin (Weather, Calendar, Parcel, etc.)
- Create a private plugin with "Plugin Merge" strategy
- Native plugin data appears as `{{ pluginkey_settingid.field }}` in markup
- Full creative control over how native data renders

## Framework v2 Markup Structure

The hierarchy is fixed. Deviating breaks layout.

```html
<!-- You provide only layout + optional title_bar -->
<div class="layout">
  <!-- your content -->
</div>
<div class="title_bar">
  <img class="image" src="icon-url" />
  <h1 class="title">Plugin Name</h1>
  <span class="instance">Instance Label</span>
</div>
```

The platform wraps your markup in Screen → (Mashup →) View automatically.

### View Sizes

Each plugin must provide markup for all four layouts:

- `full` — full screen
- `half_horizontal` — top or bottom half
- `half_vertical` — left or right half
- `quadrant` — quarter screen

(800×480 / 800×240 / 400×480 / 400×240 on OG; scaled up on TRMNL X.) Views are device-independent — the View and Layout receive calculated dimensions from the device and orientation. On TRMNL X in portrait, the same views render in portrait dimensions; orientation is a per-device setting (Device Settings > Color Palette > Orientation), not a separate template.

### Layout Modifiers

```text
layout--row | layout--col
layout--left | layout--center-x | layout--right
layout--top | layout--center-y | layout--bottom
layout--center | layout--stretch
layout--stretch-x | layout--stretch-y
```

### Key CSS Classes

- **Spacing**: `gap--sm`, `gap--md`, `gap--lg`, `p--sm`, `m--md`, etc.
- **Sizing**: `w--full`, `w--half`, `h--full`
- **Flex**: `flex`, `flex--row`, `flex--col`, `flex--center-x`, `flex--center-y`
- **Text**: `title`, `title--small`, `label`, `label--small`, `description`
- **Text color**: `text--black`, `text--white`, `text--gray-10` through `text--gray-75` (14 steps of 5)
- **Background**: `bg--black`, `bg--white`, `bg--gray-N`; dithered on 1-bit, solid on 2-bit/4-bit
- **Chromatic + semantic tokens** (v3): 10 hues × 14 steps (`bg--red-40`, `text--blue-60`) plus `primary`/`success`/`error`/`warning`. On grayscale devices these fall back to mapped grays — safe to use for intent
- **Borders**: shade-step rail `border--h-10` through `border--h-75` (same 10–75 scale as backgrounds); the old numbered `border--h-1..4` levels still render but are deprecated
- Legacy `gray-1` through `gray-7` names are deprecated aliases
- All classes use `--` separator

### Responsive System (v3)

Utility prefixes adapt one markup set across devices. Pattern and order: `size:orientation:bit-depth:utility` (each part optional; `dark:` goes first if used).

| Prefix                      | Activates on                                                                        | Example devices        |
| --------------------------- | ----------------------------------------------------------------------------------- | ---------------------- |
| `sm:`                       | sm, md, lg                                                                          | Kindle 2024            |
| `md:`                       | md, lg                                                                              | TRMNL OG / OG V2       |
| `lg:`                       | lg only                                                                             | TRMNL X, Kindle Scribe |
| `portrait:`                 | portrait orientation (landscape is default; no `landscape:` class needed on screen) | TRMNL X rotated        |
| `1bit:` / `2bit:` / `4bit:` | that exact bit depth only (not progressive)                                         | OG / OG V2 / X         |

```html
<span class="value value--large lg:value--xxlarge">42</span>
<div class="h--36 w--36 1bit:bg--black 2bit:bg--gray-45 4bit:bg--gray-75"></div>
<div class="grid grid--cols-2 portrait:grid--cols-1">
  <div class="col--span-2 portrait:col--span-1">...</div>
</div>
```

- Size classes come from the device model, not measured width — pick breakpoints by target device.
- Bit-depth prefixes apply only to color/typography utilities (backgrounds, text, value, label, title, description, content, visibility). Layout utilities (flex, gap, grid, spacing, size, rounded) take size and orientation only.
- `--base` modifier resets to default size at a breakpoint: `gap--small lg:gap--base`, `title--small lg:title--base`.
- Container query units size relative to the layout (works inside mashup slots, unlike viewport units): `w--[50cqw]`, `h--[80cqh]`, with min/max and responsive variants.
- New larger typography tiers exist for TRMNL X across value/title/label/description/content (`label--xlarge`, `content--xxxlarge`, etc.).

### The `.item` Structure (Critical)

The framework's `.item` class applies its own flex-row layout. **You cannot put arbitrary divs inside `.item` and expect them to stack vertically.** The expected structure is:

```html
<div class="item">
  <div class="meta"><!-- left column: icon, badge, indicator --></div>
  <div class="content">
    <span class="title title--small">Title text</span>
    <span class="description">Description text</span>
  </div>
</div>
```

- `.meta` renders as a narrow left column
- `.content` renders as the main area; children stack vertically
- Putting custom `<div>` elements directly inside `.item` without `.meta`/`.content` will cause them to render inline/horizontally, not stacked
- If you only need stacked text, you can omit `.meta` and use only `.content`

### Grid System for Asymmetric Layouts

Use `col--span-N` inside a grid to create unequal column widths (e.g., hero panel + manifest):

```html
<div class="layout layout--row layout--top layout--stretch">
  <div
    class="col col--span-6"
    style="padding-right: 16px; border-right: 3px solid black;"
  >
    <!-- Hero: ~55% width -->
  </div>
  <div class="col col--span-5" style="padding-left: 12px;">
    <!-- Manifest: ~45% width -->
  </div>
</div>
```

### Content Engines

#### Overflow

The modern overflow engine uses `.columns > .column` structure with `data-overflow-*` attributes on the `.columns` element:

```html
<div class="columns" data-overflow-max-cols="2" data-overflow-counter="true">
  <div class="column">
    <div class="item">...</div>
    <div class="item">...</div>
  </div>
</div>
```

- `data-overflow-max-cols="N"` — best-fit up to N columns
- `data-overflow-cols="N"` — force exactly N columns
- `data-overflow-counter="true"` — show "and X more" when items are hidden
- Responsive variants — suffixes `-sm`, `-md`, `-lg`, `-portrait`, `-sm-portrait`, `-md-portrait`, `-lg-portrait` on both attributes; most specific wins. E.g. `data-overflow-max-cols="2" data-overflow-max-cols-lg="3"` gives 3 columns on TRMNL X
- **The `.columns > .column` wrapper is required.** Using `flex flex--col` with `data-overflow="true"` may not engage the overflow counter reliably.
- Place `.divider` elements between `.item` elements for auto-managed separators

**Legacy attributes** (`data-list-limit`, `data-list-max-columns`) still work on `.column` elements and are promoted to the parent `.columns` at runtime.

**Reliability warning (verified 2026-08, framework 3.1.1):** Overflow and Clamp are JS runtime engines that execute at screenshot time, and they are browser-sensitive. TRMNL's production cloud renders with headless Chromium (Ferrum), but trmnlp renders with Firefox — the official dev tool and production can disagree. Observed in trmnlp's Firefox pipeline under load: silently dropped list items with no counter, corrupted layout on best-fit `data-overflow-max-cols-lg`, and grid/clamp interaction truncating titles to a fraction of the column; `clamp--N`/`data-clamp` were inert entirely (titles wrap instead of truncating). If overflow honesty matters, prefer deterministic Liquid caps (`limit:` + an authored "and N more" row) — pure arithmetic renders identically in every browser and is verifiable locally. If you do rely on the engines, verify on production hardware, not just trmnlp.

#### Clamp

Truncate text to N lines: use `clamp--N` class or `data-clamp="N"` attribute.

```html
<span class="title title--small clamp--1">Long text here</span>
<span class="description" data-clamp="2">Multi-line description</span>
```

Responsive: `data-clamp-sm/-md/-lg/-portrait` and size-portrait combos (e.g. `data-clamp="2" data-clamp-lg="4"`).

Clamp is part of the JS runtime — see the reliability warning under Overflow. In trmnlp's Firefox pipeline it does nothing; design row heights assuming wrapped (not truncated) text unless verified on production.

#### Pixel Perfect

Specialized pixel fonts for crisp 1-bit rendering at small sizes.

### Dividers

**The `.divider` class renders as thick dithered bands on 1-bit displays.** For clean thin separators, use CSS borders instead:

```html
<!-- DON'T: thick dithered band -->
<div class="divider"></div>

<!-- DO: crisp line -->
<div class="item" style="border-top: 2px solid black;">...</div>
```

The `.divider` class is fine between `.item` elements inside an overflow container (the engine manages their visibility), but be aware of how they render on 1-bit screens.

## Local Development with trmnlp

`trmnlp` is the official local dev tool. Install via `gem install trmnl_preview` (Ruby >= 3.4) or Docker (`trmnl/trmnlp`).

```bash
trmnlp init my_plugin     # scaffold project into my_plugin/ subdir (+ git repo + GH Actions workflow)
trmnlp serve              # local preview with hot-reload
trmnlp build              # static HTML to _build/; add --png for images
trmnlp lint               # check against TRMNL best practices; non-zero exit on issues (CI-gateable)
trmnlp login              # auth with User API Key (or set $TRMNL_API_KEY)
trmnlp list               # list private plugins on trmnl.com
trmnlp clone name id      # pull existing plugin
trmnlp pull               # re-download latest settings from server
trmnlp push               # upload to trmnl.com (--force to skip confirmation)
```

**Gotchas:**

- `init` creates a subdirectory; if your repo IS the plugin, move the contents up after init
- `trmnlp push` prompts for confirmation — use `trmnlp push --force` for non-interactive use
- **`src/settings.yml` must have an `id`** — `push` updates the plugin with that id; without one it creates a NEW plugin every run. `clone`/`pull` set it automatically
- `trmnlp build --png` renders PNGs through the same pipeline as serve (needs Firefox + ImageMagick); flags: `--width`, `--height`, `--color-depth 1-8`
- `trmnlp lint` is documented upstream but **absent from the 0.10.0 CLI** (the checks exist in the gem, unexposed) — do not let "lint passes" substitute for render verification
- trmnlp renders with **Firefox deliberately** (its prefs can disable text antialiasing, which honest 1-bit dithering needs; Chrome has no equivalent) — but production renders with Chromium, so JS-engine behavior can diverge (see Content Engines warning)
- trmnlp **caches polled data**; editing a fixture file outside the watch list won't refresh it. `GET /poll` on the serve port forces a re-fetch
- The serve render route accepts the full device matrix as URL params: `/render/<view>.png?screen_classes=...&width=W&height=H&color_depth=N`. Get each device's exact classes and scale factor from `https://trmnl.com/api/models`, and render at **logical** resolution (physical ÷ scale_factor — e.g. TRMNL X is 1040×780 logical for a 1872×1404 panel); rendering at physical size produces a miniature layout in the corner

**Also supported (see trmnlp README when needed):**

- GitHub Actions CI — scaffolded workflow lints PRs and pushes on `main` with a `TRMNL_API_KEY` repo secret
- OAuth2 flow for third-party APIs — `oauth_*` keys in settings.yml, local connect banner, `{{ oauth_access_token }}` in polling config
- Serverless transforms — `src/transform.{py,rb,js,php}` with a `run(input)` function reshapes polled data before Liquid sees it; runs automatically when present (matches hosted behavior)

### Project Structure

```sh
.
├── .trmnlp.yml            # local dev config (env vars, custom field values)
├── bin/dev
└── src/
    ├── settings.yml       # plugin config (strategy, polling, form fields)
    ├── full.liquid
    ├── half_horizontal.liquid
    ├── half_vertical.liquid
    ├── quadrant.liquid
    └── shared.liquid      # reusable partials + templates
```

### settings.yml

```yaml
id: 12345 # REQUIRED for push to update (not create) — clone/pull set it
name: My Plugin
framework_version: latest # or pin a version (e.g. "3.1") for reproducibility
description: One-line summary # optional, max 35 chars (lint enforces)
strategy: polling # polling | webhook | static
refresh_interval: 60 # minutes: 15 | 60 | 360 | 720 | 1440
polling_url: https://example.com
polling_headers: "api-key=##{{ api_key }}"
polling_verb: GET # GET | POST
no_screen_padding: "no"
dark_mode: "no"
custom_fields:
  - keyname: api_key
    name: API Key
    field_type: text
```

### .trmnlp.yml (local only, not pushed)

```yaml
watch:
  - src
  - .trmnlp.yml
custom_fields:
  api_key: "{{ env.MY_API_KEY }}"
time_zone: America/New_York
variables:
  trmnl:
    user:
      name: Your Name
```

#### Overriding polling_url for Local Dev

**The `polling_url` override must be nested under `variables.trmnl.plugin_settings`**, not at the top level of `.trmnlp.yml`. A top-level `polling_url` key is silently ignored.

```yaml
# WRONG — silently ignored:
polling_url: http://localhost:8888/data.json

# CORRECT — actually overrides the settings.yml polling_url:
variables:
  trmnl:
    plugin_settings:
      polling_url: http://localhost:8888/data.json
```

Without this override, trmnlp will try to use the `settings.yml` polling_url which typically contains `##{{ }}` form field interpolation — this creates an invalid URI and the fetch fails silently, resulting in empty/missing template variables.

### Preview Modes

The trmnlp preview at `http://localhost:4567` has two render modes selectable via dropdown:

- **HTML** — renders the Liquid template as live HTML in the browser. Useful for inspecting DOM but does NOT represent what the device sees.
- **PNG** — renders through the same pipeline the server uses, producing a 1-bit or 2-bit image. **Always test in PNG mode** to catch issues with dithering, text legibility, and layout that only appear in the rendered image.

The preview also has **device type** and **bit depth** dropdowns, plus a **Poll** button to re-fetch data from the polling URL without restarting the server.

### Reusable Partials in shared.liquid

`shared.liquid` supports `{% template %}` / `{% render %}` for reusable markup:

```liquid
<!-- In shared.liquid -->
{% template my_partial %}
  <div>{{ some_var }}</div>
{% endtemplate %}

<!-- In any view -->
{% render "my_partial", some_var: "hello" %}
```

Put shared `<style>` blocks and preprocessing logic (variable computation, sorting) in `shared.liquid` — it's included before every view.

## API Endpoints

### Device Display API

```http
GET https://trmnl.com/api/display
Header: access-token: <device_api_key>
→ Returns image_url, refresh_rate, firmware info
```

### Current Screen

```http
GET https://trmnl.com/api/current_screen
Header: access-token: <device_api_key>
→ Returns image_url, refresh_rate, filename
```

### Webhook Endpoint

```http
POST https://trmnl.com/api/custom_plugins/<plugin_uuid>
Body: {"merge_variables": {...}}
```

### API Keys

- **Device API Key**: Devices > Edit > Developer Perks. Used for display/screen endpoints and webhooks.
- **User API Key**: Account page. Used for plugin data fetch, dev tools (trmnlp), plugin export.

## Liquid Templating

TRMNL uses Shopify Liquid. Key patterns:

```liquid
{{ variable }}
{{ text | truncate: 15 }}
{% for item in collection %}...{% endfor %}
{% if condition %}...{% elsif %}...{% else %}...{% endif %}

{# Global variables available in all plugins #}
{{ trmnl.user.first_name }}
{{ trmnl.user.time_zone }}
```

### Date Math in Liquid

Liquid has no built-in date subtraction. Use epoch seconds:

```liquid
{% assign now_epoch = "now" | date: "%s" | plus: 0 %}
{% assign target_epoch = some_date | date: "%s" | plus: 0 %}
{% assign diff_secs = target_epoch | minus: now_epoch %}
{% assign days_away = diff_secs | divided_by: 86400 %}
{% if days_away < 0 %}{% assign days_away = 0 %}{% endif %}
```

The `| plus: 0` coerces the string to an integer.

### Special TRMNL Variables

- `TRMNL_SKIP_SCREEN_GENERATION` — set truthy to skip rendering this cycle
- `TRMNL_SKIP_DISPLAY` — set truthy to prevent showing on device

## Plugin Configuration (Form Fields)

Define user-facing settings in settings.yml `custom_fields`:

```yaml
custom_fields:
  - keyname: api_key
    name: API Key
    field_type: text
  - keyname: filter_mode
    name: Filter
    field_type: select
    options:
      - Recent
      - Active
```

Form values are interpolated in polling URLs/headers/body via `##{{ keyname }}`.

## Development Workflow

1. `trmnlp init` or `trmnlp clone` to get started
2. Configure `settings.yml` (strategy, polling URL, form fields)
3. Set up `.trmnlp.yml` with local env var references for secrets
4. **Override `polling_url` under `variables.trmnl.plugin_settings`** for local dev
5. Write Liquid templates for all four view sizes + shared partials
6. `trmnlp serve` to preview locally with hot-reload
7. **Test in PNG mode** in the preview to see actual e-paper rendering
8. `echo "y" | trmnlp push` to upload to trmnl.com
9. Force Refresh on trmnl.com to re-render with live data
10. Device picks up new screen on next refresh cycle

### Debugging

- Browser DevTools on the trmnlp local preview
- **Switch to PNG mode** in the preview to see the actual 1-bit/2-bit rendered output
- Use the **Poll** button to re-fetch data without restarting the server
- Check "Your Variables" on trmnl.com for data shape
- Enable "Debug Logs" on plugin settings for increased rate limits
- Test polling URLs independently with curl
- `https://trmnl.com/plugins/demo` for rendered output with sample data

## Multiple Devices

How one account drives several TRMNLs (e.g. an OG and an X):

- **Plugins are account-level; playlists are per-device.** A single private plugin instance (one config, one poll) can sit in every device's playlist. Switch devices with the device picker (top-right on trmnl.com); each device has its own playlist, schedule, and refresh rate.
- **No per-device markup.** The same plugin renders per-device through size/bit-depth/orientation classes on `.screen`. Design once, use `lg:`/`4bit:`/`portrait:` prefixes for X-specific enhancements.
- **Mirroring** — Device Settings > "Mirror another Device" replicates a parent device's playlist to child devices. After changing the parent playlist, re-sync each child via its "Sync Screens" button. Children can then drop individual playlist items.
- **Per-device settings** — orientation and grayscale palette live under Device Settings > Color Palette (TRMNL X); refresh rate, sleep mode, etc. under Devices > Edit.
- **Per-device API keys** — each device has its own Device API Key for the display/current_screen endpoints.
- **Orientation desync quirk (TRMNL X)** — if portrait/landscape renders wrong after a config change: Force Refresh the plugin, then flip Orientation to the opposite value, Save, flip back, Save.

## TRMNL X Specifics

- 10.3", 1872×1404, 4-bit — 16 solid grays with **no dithering**. Every `gray-N` token renders as a true flat shade, so subtle gray text/backgrounds that die on 1-bit work fine here.
- Size class `lg`, so `lg:` prefixed utilities target it; combine as `lg:4bit:`.
- Portrait is a first-class orientation — use `portrait:` variants for layout changes (e.g. `data-overflow-max-cols-portrait`, `portrait:grid--cols-1`, `data-clamp-portrait`).
- Larger typography tiers exist specifically for it: bump hero text with `lg:value--xxlarge`, `lg:title--large`, etc.
- Fluid Mashups (`mashup--3x3` with `mashup-cell--col/row/span` modifiers) allow custom 3×3 tilings beyond the fixed layouts — arranged on the platform side; your four views are placed into cells and always fill their cell.
- Touch bar tap = force-skip to next playlist item.

## E-Paper Design Constraints

### 1-Bit Rendering Rules

These are hard constraints **on 1-bit devices** (TRMNL OG default). On 2-bit, black/white/gray-30/gray-55 are solid; on 4-bit (TRMNL X) all 16 shades are solid and most of these constraints relax. Use `1bit:`/`4bit:` variants to serve both.

- **1-bit means no grayscale** — use dither patterns for the illusion of gray. Note: Framework v3 rebuilt the 1-bit dither scale to be linear (each `gray-N` now a distinct pattern; in v2 they rendered in identical-looking pairs). If matching a design built on v2, consult the shade migration table in the [v3 upgrade guide](https://trmnl.com/framework/docs/3.1/v3_upgrade_guide)
- **No animation, no color** — screens are static black-and-white images
- **Refresh rate is minutes, not seconds** — data shown is always slightly stale
- **Content overflow is hidden, not scrollable** — use Overflow and Clamp engines
- **Test all four view sizes** — mashups use smaller views; your plugin must work in all of them

### What Survives 1-Bit Rendering

- **Solid black shapes** — large, geometric, high-contrast
- **Bold text at 16px+** — renders crisply
- **CSS borders** (`border: 2px solid black`) — clean lines at any thickness
- **`text--gray-25` to `text--gray-35`** — readable dithered gray for de-emphasized text. Good for "delivered" or "completed" items that should recede visually.

### What Dies at 1-Bit

- **`text--gray-50` and higher** — too aggressive; text becomes illegible on the actual e-paper screen. Use `text--gray-30` maximum for "dimmed but still readable."
- **The `.divider` class** — renders as thick dithered bands, not thin lines. Use `border-top: Npx solid black` instead for crisp separators.
- **Thin borders or outlines** — `1px` borders may dither away. Use `2px` minimum.
- **Subtle background patterns** — anything that relies on fine dithering at small scale.

### Status Pills (White-on-Black Badges)

White text on black backgrounds works at 1-bit — but only if the pill properly wraps its content. The critical detail is `display: inline-block` with explicit padding. If the black background doesn't fully surround the text (e.g., because the container is sized wrong), the render looks broken.

```css
.pill {
  display: inline-block; /* NOT inline-flex, NOT flex — inline-block sizes to content */
  background: black;
  color: white;
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  line-height: 1; /* Keep the pill tight around the text */
  padding: 4px 10px; /* Generous horizontal padding relative to font size */
  font-size: 12px;
  border-radius: 999px; /* Full pill shape — survives 1-bit rendering cleanly */
}
```

Tested sizes that render cleanly at 1-bit:

- **Large**: 14px, padding 5px 12px, letter-spacing 2px
- **Default**: 12px, padding 4px 10px, letter-spacing 1.5px
- **Small**: 10px, padding 3px 8px, letter-spacing 1px

All three are legible in PNG mode at 1-bit. Works well as inline status indicators next to item titles in manifest rows.

### Design Approach

- **Start with pure black-and-white.** Add dithered gray only for intentional de-emphasis (e.g., delivered items).
- **Use typographic scale for hierarchy** — size and weight contrast are your primary tools. Big bold titles vs. small regular descriptions.
- **Use solid CSS borders for dividers** — not framework `.divider` elements.
- **Test in PNG mode early and often** — the HTML preview lies about how things will actually look on the device.
- **Budget vertical space carefully** — 480px (full) or 240px (half) fills up fast. Each 3-line item is ~60-65px. Plan item density before building.
- **Favor asymmetric layouts** — a hero panel + dense manifest reads better than uniform rows. Use `col--span-N` for unequal column splits.

## Essential Resources

Unversioned `trmnl.com/framework/docs/*.md` URLs serve the latest docs version; append `.md` for markdown.

- [Framework docs (start here)](https://trmnl.com/framework)
- [llms.txt (all docs index)](https://trmnl.com/llms.txt)
- [V3.2 Overview](https://trmnl.com/framework/docs/v3_overview.md)
- [V3 Upgrade Guide (dither migration table)](https://trmnl.com/framework/docs/3.1/v3_upgrade_guide)
- [Colors (full palette + tokens)](https://trmnl.com/framework/docs/colors.md)
- [Responsive (size/orientation/bit-depth)](https://trmnl.com/framework/docs/responsive.md)
- [Framework Runtime](https://trmnl.com/framework/docs/framework_runtime.md)
- [Mashup (incl. Fluid Mashups)](https://trmnl.com/framework/docs/mashup.md)
- [Structure](https://trmnl.com/framework/docs/structure.md)
- [Layout](https://trmnl.com/framework/docs/layout.md)
- [Grid](https://trmnl.com/framework/docs/grid.md)
- [Flex](https://trmnl.com/framework/docs/flex.md)
- [Columns](https://trmnl.com/framework/docs/columns.md)
- [Title Bar](https://trmnl.com/framework/docs/title_bar.md)
- [Text styling](https://trmnl.com/framework/docs/text.md)
- [Background/dither](https://trmnl.com/framework/docs/background.md)
- [Overflow engine](https://trmnl.com/framework/docs/overflow.md)
- [Clamp engine](https://trmnl.com/framework/docs/clamp.md)
- [Pixel Perfect](https://trmnl.com/framework/docs/pixel_perfect.md)
- [V3.2 Enhancement guide (themes, adaptive charts/icons)](https://trmnl.com/framework/docs/v3_enhancement_guide.md)
- [Troubleshooting guide](https://trmnl.com/framework/docs/troubleshooting_guide.md)
- [TRMNL X guide](https://trmnl.com/framework/docs/trmnl_x_guide.md)
- [Grayscale bit depths explained](https://help.trmnl.com/en/articles/12386214-grayscale-1-bit-2-bit-4-bit-in-framework)
- [Mirroring devices](https://help.trmnl.com/en/articles/10530871-mirroring-a-device)
- [Playlist scheduler](https://help.trmnl.com/en/articles/11663305-playlist-scheduler)
- [How refresh rates work](https://help.trmnl.com/en/articles/10113695-how-refresh-rates-work)
- [Private plugins guide](https://help.trmnl.com/en/articles/9510536-private-plugins)
- [Webhook docs](https://docs.trmnl.com/go/private-plugins/webhooks)
- [Plugin Data API](https://docs.trmnl.com/go/private-api/plugin-data)
- [Display/Screen API](https://docs.trmnl.com/go/private-api/screens)
- [Liquid 101](https://help.trmnl.com/en/articles/10671186-liquid-101)
- [Advanced Liquid](https://help.trmnl.com/en/articles/10693981-advanced-liquid)
- [Custom filters](https://help.trmnl.com/en/articles/10347358-custom-plugin-filters)
- [Form builder](https://help.trmnl.com/en/articles/10513740-custom-plugin-form-builder)
- [Plugin recipes](https://help.trmnl.com/en/articles/10122094-plugin-recipes)
- [Debugging native plugins](https://help.trmnl.com/en/articles/11135276-debugging-native-plugins)
- [Debugging private plugins](https://help.trmnl.com/en/articles/11586187-debugging-private-plugins)
- [Reusable markup (Shared tab)](https://help.trmnl.com/en/articles/13216853-reusing-markup-with-shared)
- [Skip screen generation](https://help.trmnl.com/en/articles/13615138-skipping-screens-within-plugin-markup)
- [GitHub sync](https://help.trmnl.com/en/articles/13465101-syncing-plugins-with-github)
- [Import/export plugins](https://help.trmnl.com/en/articles/10542599-importing-and-exporting-private-plugins)
- [OSS plugin examples](https://github.com/usetrmnl/plugins)
- [trmnlp dev tool](https://github.com/usetrmnl/trmnlp)
- [Server IPs (for whitelisting)](https://trmnl.com/api/ips)
