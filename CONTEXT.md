# Context

Renders Parcel package-tracking data on TRMNL e-paper displays. The domain is delivery anticipation: partitioning tracked deliveries into glanceable buckets and choosing what deserves the biggest slot on screen.

## Language

**Delivery**:
One tracked package from the Parcel API.

**Partition**:
The single canonical assignment of every Delivery to exactly one Bucket, computed once in `shared.liquid` and consumed by all views.

**Bucket**:
One of the disjoint groups a Delivery lands in: Today, Upcoming, or Delivered.

**Today**:
Bucket for Deliveries that are out for delivery (status 4), ready for pickup (status 3), or expected today while active. Overdue Deliveries do not belong here.

**Upcoming**:
Bucket for active Deliveries not arriving today, ordered by expected date ascending; date-less Deliveries keep API order at the end.

**Delivered**:
Bucket for Deliveries with status 0. Rendered dimmed, at the bottom of the left panel.

**Hero**:
The single Delivery promoted out of its Bucket into the large left slot. Precedence: sole Today item > Attention (7, then 6) > soonest expected arrival > date-less actives. A promoted Delivery never also renders in its Bucket's list.

**Today Panel**:
The left-slot list that replaces the Hero when more than one Delivery is in Today.

**Attention**:
A Delivery with status 7 (exception) or 6 (failed attempt). Rendered bold with its status label in the Upcoming manifest; only takes the Hero slot when nothing arrives today.

**Late**:
A marker (not a Bucket) on any undelivered Delivery whose expected date has passed. Replaces the days-away number. Persists even if the Delivery is promoted to Today or Hero (e.g. late package goes out for delivery).

## Relationships

- Every **Delivery** belongs to exactly one **Bucket**; the **Hero** is removed from its Bucket's rendered list (exactly-once invariant).
- **Late** and **Attention** are markers orthogonal to Buckets: a Late Delivery may sit in Today or Upcoming.
- If all **Deliveries** are **Delivered**, a celebratory **All-Arrived** hero is shown.
