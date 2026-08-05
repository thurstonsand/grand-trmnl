# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

A single user: the project owner. They glance at a TRMNL e-paper display to track package deliveries. The primary job is delivery anticipation: quickly seeing what is arriving and when without having to inspect a phone app or dashboard.

## Product Purpose

Render Parcel package-tracking data as glanceable dashboards on TRMNL e-paper displays. The screen should support instant scanning first, with pleasant details as a secondary layer. Success: the core answer (what's arriving, when) is readable in a second or less.

## Operating Context

- Runs on TRMNL OG (7.5", 800×480, 1-bit) and TRMNL X (10.3", 1872×1404 physical / 1040×780 logical, 4-bit, landscape and portrait), ambient on a wall or desk.
- Refresh happens on the scale of minutes; the interface is ambient, never live.
- Data arrives from the Parcel API via TRMNL's polling strategy; the display is passive — no interaction beyond looking.

## Capabilities and Constraints

- Four fixed view sizes (full, half_horizontal, half_vertical, quadrant); mashup-sized variants are first-class.
- Monochrome/grayscale only: 1-bit dithering on OG, 16 solid grays on X. Content overflow is hidden, not scrollable.
- Domain terminology is defined in CONTEXT.md (Partition, Bucket, Hero, Late, Attention).

## Brand Commitments

- Voice and tone: informational, fun, digestible. Emotional target is delightful calm — easy to read, lightly satisfying, never demanding; rewards attention without requiring it.
- Reference direction: Not Boring apps — personality, polish, playful consumer appeal — translated into a monochrome e-paper language rather than copied literally.
- Anti-reference: the default Parcel experience. Nothing generic, flat, corporate, or administratively boring.
- Aesthetic: playful consumer with disciplined restraint. Lean into the monochrome constraint; Jony Ive-style respect for reduction — crisp hierarchy, deliberate whitespace, delight through precision rather than decoration.

## Product Principles

1. Glanceability is primary. The most important delivery information must be readable in a second or less.
2. Reduce cognitive load. Clear hierarchy, sparse choices, obvious grouping over dense data display.
3. Delight through form, not clutter. Composition, rhythm, contrast, and TRMNL-native constraints create charm.
4. Lean into monochrome. Design for black, white, and dithered gray intentionally; do not mimic full-color app conventions.
5. Make anticipation legible. What is arriving, when it is expected, and what needs attention come before secondary metadata.
