# 01 — Liquid Markup for Parcel Plugin

## Status

Superseded by docs/designs/02-partition-and-framework-native-layout.md (bucket/hero logic and styling approach; merge-variable reference and edge-case list remain accurate)

## Problem Statement

The scaffolded trmnlp project has placeholder markup in all four view templates. We need to design and implement Liquid templates that render Parcel delivery data on a 1-bit e-paper display across all TRMNL view sizes.

## Merge Variables (Raw Parcel API Response)

The polling strategy delivers the Parcel API response directly as merge variables:

```json
{
  "success": true,
  "error_message": "only on failure",
  "deliveries": [
    {
      "carrier_code": "amzlus",
      "description": "Simplehuman Brass Stainless Steel Pump",
      "status_code": 2,
      "tracking_number": "112-1641651-6290612",
      "extra_information": "P48GRJgDG",
      "date_expected": "2026-03-05 00:00:00",
      "events": [
        {
          "event": "Package arrived at an Amazon facility.",
          "date": "Tuesday, March 3 4:39 PM",
          "location": "Erlanger, KY US"
        }
      ]
    }
  ]
}
```

### Status Code Map

Rendered in Liquid via `{% case %}`:

| Code | Label | Notes |
| ------ | ------- | ------- |
| 0 | Delivered | |
| 1 | Frozen | Stale, unlikely to update |
| 2 | In Transit | |
| 3 | Pickup | Awaiting recipient pickup |
| 4 | Out for Delivery | |
| 5 | Not Found | |
| 6 | Failed Attempt | |
| 7 | Exception | Needs attention |
| 8 | Info Received | Not yet physically with carrier |

## Design Decisions

### Shared partials in `shared.liquid`

Reusable components defined once, included by all views:

- **Status badge macro** — `{% case %}` block mapping `status_code` to human label
- **Delivery row** — renders one delivery item (description, status, latest event, ETA)
- **Error/empty states** — consistent messaging across views

### View-specific layouts

| View | Dimensions | Approach |
| ------ | ----------- | ---------- |
| `full` | 800×480 | Summary header (counts by status) + detailed delivery list with latest event, location, and ETA |
| `half_vertical` | 400×480 | Delivery list, compact rows, no summary header |
| `half_horizontal` | 800×240 | Single-line delivery rows, status + description + ETA |
| `quadrant` | 400×240 | Delivery count + next arriving package only |

### Information hierarchy per delivery

1. **Description** (package name) — always shown
2. **Status badge** — always shown, inverted label
3. **Latest event** — shown in full/half_vertical only
4. **Event location** — shown in full only
5. **Expected delivery** — shown when `date_expected` is present
6. **Carrier** — omitted (low value on e-paper; carrier_code is an internal code, not human-friendly)
7. **Tracking number** — omitted (too long for e-paper, not actionable on a passive display)

### Overflow handling

- Use `data-list-limit="true"` on delivery list containers so items beyond the visible area are hidden cleanly
- Use `clamp--1` or `clamp--2` on description text to prevent long names from breaking layout

### Error and edge cases

- `success` is false → show `error_message`
- `deliveries` is empty → "No deliveries" centered message
- Missing `date_expected` → hide ETA line
- Empty `events` array → hide latest event line
- Missing `events[0].location` → hide location

## Rejected Alternatives

None yet — first design pass.

## Integration Points

- **`src/settings.yml`** — already configured with polling strategy and form fields
- **`.trmnlp.yml`** — local dev override pointing at cached JSON
- **`references/parcel_response.json`** — test data for local preview
- **Framework v2 CSS** — all layout uses TRMNL's built-in classes (`layout`, `title_bar`, `columns`, `flex`, `label`, etc.)

## Implementation Plan

- [ ] `src/shared.liquid` — status badge case block, delivery row partial, error/empty states
- [ ] `src/full.liquid` — summary header with status counts, detailed delivery list with event + location + ETA, title bar
- [ ] `src/half_vertical.liquid` — compact delivery list, no summary header
- [ ] `src/half_horizontal.liquid` — single-line delivery rows
- [ ] `src/quadrant.liquid` — delivery count + next arriving package
- [ ] Local preview — `mise run dev`, verify all four views render correctly against cached data
- [ ] Push — `trmnlp login` + `trmnlp push`, verify on device
