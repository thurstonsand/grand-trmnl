# 03 — Bin Reminder

## Status

Accepted — implemented

## Decision Summary

Add a curbside pickup reminder to every view: an inverted "Bins out tonight" / "Bins out today" row with one bin icon per collected stream (garbage always, recycling on recycling weeks). It shows only from noon the day before pickup until noon the day of, and is otherwise absent, so the delivery screen is untouched on every other day. The schedule comes from ReCollect, the same feed Home Assistant's `recollect_waste` integration reads, polled as a second URL alongside Parcel.

## Problem Statement / Background

The display sits where packages are checked, which is also where the bins get remembered (or not). Pickup is weekly with biweekly recycling and occasional holiday shifts, so a fixed weekday rule is wrong a few times a year and recurrence math would duplicate what the hauler already publishes.

## Goals

- The reminder is unmissable inside its window and invisible outside it.
- Garbage vs. recycling is readable from icons alone.
- Holiday shifts are handled by the data, not by template logic.

## Non-Goals

- No collection-hour awareness; ReCollect publishes days only.
- No dismissal or "bins are out" state.

## Exposed Shape

### Data

Polling uses two URLs, so responses arrive namespaced: `IDX_0` is Parcel, `IDX_1` is ReCollect. `shared.liquid` re-assigns `success`, `error_message`, and `deliveries` from `IDX_0` so the partition and views read as before.

ReCollect request: `GET https://api.recollect.net/api/places/{recollect_place_id}/services/1185/events?hide=reminder_only&after=…&before=…`. No auth. `1185` is the hauler's service ID for area `WC-6501`, returned alongside the place ID by ReCollect's address lookup; only the place ID varies per address. `after` is inclusive and `before` exclusive; the window runs from yesterday (UTC) to 15 days out so any timezone offset or holiday shift still contains the next pickup. Each `events[]` entry has a `day` (`YYYY-MM-DD`) and `flags[]`; a flag with `event_type == "pickup"` names a stream (`Garbage`, `Recycling`). Holiday markers are separate events whose flags have no `event_type`.

### Contract (`shared.liquid` → views)

| Variable | Shape | Meaning |
| --- | --- | --- |
| `bin_when` | `""`, `"tonight"`, `"today"` | Whether and how to show the reminder |
| `bin_recycling` | bool | The next pickup includes Recycling |

Views render the `bin_row` template when `bin_when != ""`.

## Design Decisions

- **Window: noon to noon.** "Tonight" from 12:00 the day before pickup, "today" until 12:00 on pickup day. Local time is `trmnl.system.timestamp_utc + trmnl.user.utc_offset` (TRMNL's documented approach; the offset tracks DST). Date and hour come from that single clock so they can't disagree near midnight. The hour is plain arithmetic and the date is formatted from that day's noon, because Liquid's `date` filter formats integers in the server's timezone; this keeps the window correct wherever the template renders, including local trmnlp off UTC.
- **Placement follows the Partition.** "Tonight" is upcoming: it tops the Upcoming list (`full`, `half_horizontal`; the right column appears for it alone if needed). "Today" belongs to Today: it sits under the Hero in the left column. The single-column views (`half_vertical`, `quadrant`) put it directly under the Hero in both cases. The empty and error states carry it too, so a parcel-free day or a Parcel outage still gets the reminder.
- **Icons over words.** Solid bin with a hexagon window for garbage, outline bin with a triangle for recycling, echoing the Home Assistant House Atlas glyphs. No stream names in the row.
- **ReCollect directly, not via Home Assistant.** The plugin reads the hauler's own feed rather than depending on Home Assistant. `recollect_place_id` is a custom field so the address-derived ID stays out of the repo, matching how Home Assistant keeps it in its config entry.

## Edge Cases & Failure Modes

- ReCollect unreachable → `IDX_1` has no `events`, no reminder; parcels render normally.
- `recollect_place_id` is required: TRMNL skips polling entirely while a required field interpolated into the URL is blank.
- Pickup day after noon → the loop stops at today's pickup without falling through to next week's.
- Polling headers apply to every URL, so ReCollect also receives the Parcel `api-key` header. ReCollect ignores it; accepted as low-sensitivity.
- ReCollect's web API is unofficial; Home Assistant's integration shares that exposure.

## Alternatives

Title-bar stamp, a dedicated card in the Hero column, and a 7-day rail mixing parcels and pickups were mocked. The title bar was too quiet, the card had no home in `half_*`/`quadrant`, and the rail only fit `full`.
