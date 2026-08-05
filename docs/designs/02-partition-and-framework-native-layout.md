# 02 — Canonical Partition and Framework-Native Layout

## Status

Accepted — implemented with one recorded deviation (see Implementation Deviations)

## Decision Summary

Replace per-view bucket filtering with a single canonical partition computed in `shared.liquid`, enforcing an exactly-once rendering invariant that makes the duplicate-entry bug class unrepresentable. Simultaneously migrate hand-rolled px typography to framework-native classes so the v3 responsive system (`lg:`, `portrait:`, bit-depth variants) can adapt the same markup to TRMNL X. The tradeoff: the rendered look shifts slightly from the pixel-tuned v1, in exchange for one styling system instead of two and trivial multi-device support.

## Problem Statement / Background

Two forces converged on the v1 markup (docs/designs/01-liquid-markup.md):

1. **A duplication bug.** Each view re-derives its own buckets with different exclusion rules. `full` and `half_horizontal` exclude today + delivered from the right column but not the hero, so when nothing arrives today the hero (drawn from the upcoming pool) renders on both sides. A second path: when everything is delivered, hero falls back to `deliveries[0]`, which also appears in the delivered list. The root cause is structural — bucket logic is scattered, so any new view or rule change can reintroduce the bug.
2. **TRMNL X arrived.** The plugin must now serve a 10.3" 1872×1404 4-bit display (size class `lg`, portrait-capable) alongside the OG. Framework v3's responsive system adapts markup per device, but only through framework classes. The v1 templates hand-roll typography with 37 inline `style="font-size: Npx"` blocks and px-based custom CSS (`.hero-name`, `.day-count`, …) that the responsive system cannot touch — on the X they would render at fixed px, far too small for the panel.

Rather than patch the filter, this design fixes the partition architecture and the styling architecture together, since both are prefactors for the same goal: layout logic that is easy to get right and hard to get wrong.

## Goals

- Every delivery renders exactly once on every view, by construction.
- Bucket membership and hero selection are decided in one place and consumed everywhere.
- The same four views render well on TRMNL OG (1-bit, `md`) and TRMNL X (4-bit, `lg`, landscape and portrait) with only responsive-prefix differences.
- Overdue packages are represented honestly (Late), not folded into "arriving today".

## Non-Goals

- No changes to data acquisition (polling strategy, Parcel API fields, settings.yml form fields).
- No theme adoption or chromatic color usage; this pass stays grayscale. (The migration makes the plugin theme-ready as a side effect.)
- No pixel-perfect preservation of the v1 look; screenshots in `references/screenshots/` are a sanity baseline, not a contract.

## Exposed Shape

### Partition contract (`shared.liquid` → views)

Computed once, before any view markup. All values are strings/ints because Liquid cannot build object arrays; index lists are comma-joined strings split into arrays.

| Variable | Shape | Meaning |
| --- | --- | --- |
| `today_indices_arr` | array of index strings | Deliveries in the Today bucket (status 4, status 3, or expected today while active) |
| `upcoming_indices_arr` | array of index strings | Active, non-today deliveries, sorted by `date_expected` ascending; date-less last in API order |
| `delivered_indices_arr` | array of index strings | Status 0 deliveries |
| `hero_idx` | int, −1 if none | The promoted delivery, already **removed** from its source bucket's array |
| `all_arrived` | bool | Every delivery is Delivered (no hero promoted) |
| `now_epoch`, per-row day math | ints | Unchanged from v1 |

Invariants the contract guarantees:

- The three bucket arrays are disjoint and, together with `hero_idx`, cover every delivery exactly once.
- Views iterate bucket arrays only. A view never inspects `status_code` or dates to decide membership — only to decide styling (Late marker, Attention emphasis, dimming).

### Row markers (orthogonal to buckets)

- **Late** — `date_expected` in the past, not delivered. Replaces the days-away number with "Late". Persists across promotion (a late package that goes out for delivery keeps the marker in the Today panel or hero).
- **Attention** — status 7 or 6. Row renders bold with its status label.
- **Today** — rows in the Today panel render bold; status labels ("Today"/"Pickup" vs "Attention"/"Missed") differentiate bold-today from bold-attention.

### Device rendering matrix

Same four liquid views everywhere; differences are responsive prefixes only.

| Device | Prefixes active | Full-view differences |
| --- | --- | --- |
| TRMNL OG | `md:`, `1bit:` | Baseline: two-panel (hero/today + delivered left, upcoming right), dithered dimming |
| TRMNL X landscape | `lg:`, `4bit:` | Larger type tiers, latest-event line on manifest rows, 2-column upcoming (`data-overflow-max-cols-lg="2"`), solid-gray dimming |
| TRMNL X portrait | `lg:`, `portrait:`, `4bit:` | Hero stacked above manifest (`portrait:` layout variants), single manifest column |

## Design Decisions

### 1. Exactly-once partition, computed centrally

Bucket membership and hero selection move entirely into `shared.liquid`. The hero is promoted *out* of its bucket at partition time, so no view can double-render it. This is the root-cause fix: the bug existed because exclusion was a per-view responsibility. Consequence: adding a view or changing a bucket rule touches one file.

### 2. Hero precedence: today > attention > soonest

Full precedence: sole Today item > Attention (status 7, then 6, API order within) > soonest expected arrival among active > date-less actives (API order) > no hero (All-Arrived State). More than one Today item replaces the hero with the Today Panel list. Delivery anticipation is the display's primary job, so Today outranks Attention; attention items instead get bold emphasis in the manifest. Rejected: attention-first (would let a rare stuck package hide today's arrivals).

### 3. Overdue is Late, not Today

v1 folded past-due packages into "Arriving today" — a promise the carrier already broke. Late becomes a marker in Upcoming. Known tradeoff: Parcel ETAs sometimes lag reality, so "Late" may occasionally cry wolf; accepted as more honest than the alternative.

### 4. All-Arrived celebration state

When every delivery is status 0, no hero is promoted; the full view shows a celebration hero ("All arrived" + count) above the dimmed delivered list. Kills duplication path 2 and fits the delightful-calm brand target — a delivered package should not occupy the anticipation slot.

### 5. Upcoming sorted by expected date

Anticipation order, stable across polls (API order is not). `date_expected` strings (`YYYY-MM-DD HH:MM:SS`) sort lexicographically, so the sort is a cheap string sort in Liquid. Date-less deliveries append in API order.

### 6. Framework-native styling migration

All inline px typography and px-based custom classes are replaced with framework primitives (`value--*`, `title--*`, `label`, `description`, `gap--*`, spacing/border utilities), keeping custom CSS only where the framework has no primitive. This is what lets `lg:`/`portrait:`/`4bit:` variants reach the markup, and it makes the plugin theme-ready (themes only remap framework tokens). Rejected alternative: keeping px styles and forking X support into hand-written container queries — two styling systems fighting the framework. Consequence: the OG rendering shifts slightly from v1's pixel-tuned look; each view is re-verified in PNG mode against the screenshot baseline.

### 7. Richer manifest on TRMNL X

`lg:` adds the latest-event line to manifest rows and a second upcoming column via responsive overflow attributes. The X has ~5.5× the pixels of the OG; rendering the OG's information density there wastes the panel. Portrait uses stacked composition with `portrait:` variants.

## Edge Cases & Failure Modes

- **`success == false`:** unchanged — error state with `error_message`.
- **Zero deliveries:** unchanged — empty state.
- **Single delivery:** hero-only layout, no manifest (existing behavior, now guaranteed duplicate-free by construction).
- **All delivered:** All-Arrived State (celebration hero + dimmed list), no promoted hero.
- **Late package goes out for delivery:** joins Today bucket (promotable to hero), keeps Late marker.
- **All upcoming lack `date_expected`:** sort degrades to API order; days indicator falls back to `!` as in v1.
- **More items than fit:** deterministic Liquid caps per view/device with a shared authored `and N more` counter row (see Implementation Deviations — the framework overflow engine was abandoned).

## Implementation Deviations

Recorded after the three-round implementation/review cycle:

- **Framework overflow/clamp engines abandoned.** The plan called for the framework's JS overflow engine (`data-overflow-max-cols-*`) and `clamp--N`. Under load (18 deliveries) the engine corrupted half_vertical on OG, silently dropped rows on X half_horizontal, and diverged between Chrome and the Firefox-based device pipeline; `clamp--N`/`data-clamp` proved inert in the device pipeline entirely. All four views now use deterministic Liquid caps + responsive framework grids + one shared authored `manifest_counter` ("and N more") row. Overflow honesty is pure Liquid arithmetic — identical in every renderer. Titles wrap instead of truncating; caps are sized for two-line rows.
- **Cap table:** Full 8 (all devices); half_horizontal upcoming 3 OG/portrait, 6 X landscape; half_vertical manifest 6 OG/portrait, 8 X landscape; quadrant manifest 1 OG, 2 portrait, 3 X landscape; delivered list 4 (full), 2 (half_horizontal); Today Panel 4 (full, half_vertical), 3 (half_horizontal, quadrant). Every hidden item is accounted for by a visible counter.
- **`trmnlp lint` does not exist as a CLI command in trmnlp 0.10.0** (lint checks live in the gem but are not exposed); render-based verification is the actual gate.

## Alternatives

### Duplication as intentional spotlight (hero also listed in manifest)

- **Status:** Rejected
- **Decision:** Reads as a rendering error on a glanceable display; makes "N upcoming" counts dishonest.

### Attention-first hero

- **Status:** Rejected
- **Decision:** Today wins; see Decision 2. Attention still surfaces via bold + label in the manifest.

### Minimal styling fix (keep px CSS, patch partition only)

- **Status:** Rejected
- **Decision:** Leaves TRMNL X support blocked behind a second, hand-maintained styling system. The migration is the prefactor that makes X support and future framework upgrades cheap.

## Implementation Plan

Executed as a coordinated agent workflow with the orchestrator (this session) as the sole message hub — no subagent-to-subagent communication. Implementation by `gpt-5.6-sol` subagents (medium thinking); review by a `claude-fable-5` subagent (high thinking) running the thermo-nuclear code-quality review. Each agent writes its full report to a file under `.agents/scratch/` (gitignored) — implementation notes, review findings, rebuttal — and the orchestrator relays file references between implementer and reviewer each round (cap: 3 rounds, then the orchestrator arbitrates). The reviewer is read-only outside its own report file. No agent stages, stashes, or otherwise disturbs git state — the staged/unstaged split belongs to the project owner.

Render verification protocol (used throughout): `mise run dev`, trmnlp preview in **PNG mode**, device picker set to TRMNL OG (1-bit, 800×480) and TRMNL X (4-bit, 1872×1404, landscape and portrait), screenshots via browser automation. Scenario datasets are swapped into `references/parcel_response.json` and re-polled:

| Scenario | Purpose |
| --- | --- |
| `full-dataset` (current 8-delivery mix) | General layout, all buckets populated |
| `no-today` | Bug 1 repro: hero drawn from Upcoming must not duplicate |
| `all-delivered` | Bug 2 repro: All-Arrived State |
| `overdue-mix` (late + late-gone-out-for-delivery) | Late marker, marker persistence across promotion |
| `missing-dates` | Sort fallback, `!` indicator, date-less hero fallback |
| `single` / `empty` / `error` | Degenerate states unchanged |

- [ ] Phase 0: Tooling and baselines (orchestrator)
  - Goal: Working PNG render pipeline and captured v1 baselines for every scenario.
  - Files: `references/parcel_response_scenarios/` (new scenario JSONs), `references/screenshots/` (baseline captures).
  - Work: Install Firefox (`brew install --cask firefox`); confirm PNG mode renders and the device picker exposes TRMNL X with correct `screen--lg`/`screen--4bit`/portrait classes; author scenario datasets; capture v1 baselines (including the two bug repros) on OG.
  - Validation: One PNG per view per key scenario exists; bug 1 and bug 2 visible in baselines.

- [ ] Phase 1: Logic workstream — partition + semantics (sol implements, fable reviews)
  - Goal: Canonical partition with exactly-once invariant, plus the new semantics (hero precedence, Late marker, All-Arrived State, upcoming sort, bold today/attention rows).
  - Files: `src/shared.liquid`, all four view templates (iteration rewiring only — no styling changes).
  - Work: Implement the partition contract (bucket index arrays, hero promotion/removal, `all_arrived`); rewire views to iterate bucket arrays exclusively; implement markers and sort per Design Decisions 2–5.
  - Validation: Implementer self-verifies with PNG renders of every scenario on OG (recipes in DEV.md) and writes renders + notes to `.agents/scratch/`; fable review loop via orchestrator relay to satisfaction; orchestrator gate confirms both bug repros are fixed and every delivery appears exactly once in each scenario.

- [ ] Phase 2: Presentation workstream — framework migration + TRMNL X (sol implements, fable reviews)
  - Goal: Framework-native styling everywhere a primitive exists; `lg:`/`portrait:`/bit-depth variants delivering the X rendering matrix (larger tiers, event lines, 2-col upcoming, portrait stack).
  - Files: `src/shared.liquid` (style block reduction, templates), all four view templates.
  - Work: Replace inline px typography and custom classes with `value--*`/`title--*`/`label`/`description`/`gap--*`/spacing/border utilities; add responsive prefixes and `data-overflow-max-cols-lg`/`portrait` attributes; keep custom CSS only for documented gaps.
  - Validation: Implementer self-verifies on OG and X (both orientations) across scenarios; fable review loop to satisfaction; orchestrator gate compares OG renders against Phase 0 baselines for legibility regressions.

- [ ] Phase 3: Final verification and deliverable (orchestrator)
  - Goal: Independent confirmation of behavior and the review deliverable.
  - Files: none (verification only); sideshow surface.
  - Work: Full render matrix — all four views × OG 1-bit × X 4-bit landscape/portrait × key scenarios; verify partition invariants by inspection of rendered output; publish sideshow surface with the finalized layout grid plus a log of surprises encountered by orchestrator or subagents; deploy via `trmnlp push` only on explicit approval.
  - Validation: Sideshow surface delivered; project owner sign-off.
