---
name: trmnl-development
description: "Build plugins for TRMNL e-paper displays. Use when creating, debugging, or modifying TRMNL plugins, working with the TRMNL API, or designing layouts for e-paper screens."
---

# TRMNL Plugin Development

Build and manage plugins for TRMNL e-paper display devices.

## Platform Overview

TRMNL renders HTML/CSS markup as 1-bit (black/white) or 2-bit (4-shade grayscale) images for e-paper screens. Standard display: 800×480. Plugins define markup templates with Liquid variables; TRMNL's server renders them to images and pushes to devices.

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
  <img class="image" src="icon-url"/>
  <h1 class="title">Plugin Name</h1>
  <span class="instance">Instance Label</span>
</div>
```

The platform wraps your markup in Screen → (Mashup →) View automatically.

### View Sizes

Each plugin must provide markup for all four layouts:

- `full` — 800×480 (full screen)
- `half_horizontal` — 800×240 (top or bottom half)
- `half_vertical` — 400×480 (left or right half)
- `quadrant` — 400×240 (quarter screen)

### Layout Modifiers

```text
layout--row | layout--col
layout--left | layout--center-x | layout--right
layout--top | layout--center-y | layout--bottom
layout--center | layout--stretch
```

### Key CSS Classes

- **Spacing**: `gap--sm`, `gap--md`, `gap--lg`, `p--sm`, `m--md`, etc.
- **Sizing**: `w--full`, `w--half`, `h--full`
- **Flex**: `flex`, `flex--row`, `flex--col`, `flex--center-x`, `flex--center-y`
- **Text**: `title`, `title--small`, `label`, `label--small`, `description`
- **Background**: `bg--black`, `bg--white`, dither patterns for grayscale illusion
- **Borders**: `border--h-1` through `border--h-4` (dithered horizontal rules)
- All classes use `--` separator

### Content Engines

- **Overflow**: `data-list-limit="true"` on a container; auto-hides items that exceed height
- **Clamp**: `clamp--2`, `clamp--3` etc. truncates text to N lines
- **Pixel Perfect**: specialized pixel fonts for crisp 1-bit rendering

## Local Development with trmnlp

`trmnlp` is the official local dev tool. Install via `gem install trmnl_preview` (Ruby 3.x) or Docker.

```bash
trmnlp init my_plugin     # scaffold project into my_plugin/ subdir
trmnlp serve              # local preview with hot-reload
trmnlp login              # auth with User API Key
trmnlp push               # upload to trmnl.com
trmnlp clone name id      # pull existing plugin
```

**Gotchas:**

- `trmnlp init` does NOT support `--help` or any flags — every argument is treated as a directory name
- `init` creates a subdirectory; if your repo IS the plugin, move the contents up after init

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
    └── shared.liquid      # reusable partials
```

### settings.yml

```yaml
name: My Plugin
strategy: polling              # polling | webhook | static
refresh_interval: 60           # minutes: 15 | 60 | 360 | 720 | 1440
polling_url: https://example.com
polling_headers: 'api-key=##{{ api_key }}'
polling_verb: GET              # GET | POST
no_screen_padding: 'no'
dark_mode: 'no'
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
4. Write Liquid templates for all four view sizes + shared partials
5. `trmnlp serve` to preview locally with hot-reload
6. `trmnlp push` to upload to trmnl.com
7. Force Refresh on trmnl.com to re-render with live data
8. Device picks up new screen on next refresh cycle

### Debugging

- Browser DevTools on the trmnlp local preview
- Check "Your Variables" on trmnl.com for data shape
- Enable "Debug Logs" on plugin settings for increased rate limits
- Test polling URLs independently with curl
- `https://trmnl.com/plugins/demo` for rendered output with sample data

## Essential Resources

- [Framework v2 docs (start here)](https://trmnl.com/framework)
- [llms.txt (all docs index)](https://trmnl.com/llms.txt)
- [Structure](https://trmnl.com/framework/docs/structure.md)
- [Layout](https://trmnl.com/framework/docs/layout.md)
- [Columns](https://trmnl.com/framework/docs/columns.md)
- [Title Bar](https://trmnl.com/framework/docs/title_bar.md)
- [Text styling](https://trmnl.com/framework/docs/text.md)
- [Background/dither](https://trmnl.com/framework/docs/background.md)
- [Overflow engine](https://trmnl.com/framework/docs/overflow.md)
- [Clamp engine](https://trmnl.com/framework/docs/clamp.md)
- [Pixel Perfect](https://trmnl.com/framework/docs/pixel_perfect.md)
- [Enhancement guide](https://trmnl.com/framework/docs/enhancement_guide.md)
- [Troubleshooting guide](https://trmnl.com/framework/docs/troubleshooting_guide.md)
- [TRMNL X guide](https://trmnl.com/framework/docs/trmnl_x_guide.md)
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

## E-Paper Design Constraints

- **1-bit means no grayscale** — use dither patterns (`bg--gray-50`, etc.) for the illusion
- **No animation** — screens are static images
- **No color** — design in black and white only
- **Refresh rate is minutes, not seconds** — data shown is always slightly stale
- **Pixel fonts render sharpest** — use the Pixel Perfect system for small text
- **Content overflow is hidden, not scrollable** — use Overflow and Clamp engines
- **Test all four view sizes** — mashups use smaller views; your plugin must work in all of them
