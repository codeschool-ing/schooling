---
title: Risk is likelihood times impact
version: 1
---

**A risk is something that might go wrong, judged by how likely it is and how much damage it would do.** Testing
reduces risk by finding the defects before customers do, so the areas with the most risk get the most testing. This is
called **risk-based testing**, and it is how most test teams prioritise, whether they call it that or not.

## Scoring it

Precise probabilities are rarely available, so teams score both halves on a small scale, often 1 to 3, and multiply:

| score | likelihood | impact |
|---|---|---|
| 1 | low: old, simple, unchanged code | low: an annoyance with a workaround |
| 2 | medium: changed, or moderately complex | medium: a customer is inconvenienced or a staff member loses time |
| 3 | high: new, complex, or changed in a hurry | high: money is lost, the law is broken, or sales stop |

Cine Aurora's six areas, scored by Rafael and Tomás for likelihood and by Joana for impact:

| area | likelihood | impact | risk |
|---|---|---|---|
| price rule | 3 | 3 | 9 |
| coupons | 3 | 2 | 6 |
| orders | 2 | 3 | 6 |
| refunds | 2 | 2 | 4 |
| seat map | 1 | 2 | 2 |
| nightly report | 1 | 1 | 1 |

The price rule scores highest on both: it was changed this sprint, it has had more defects than anything else, and a
wrong price is money lost on every ticket. The nightly report scores lowest: a new column in a report nobody acts on in
real time, where a mistake is noticed the next morning and costs nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 300\" role=\"img\" data-fig=\"l20-matrix\" aria-label=\"A three by three risk matrix, likelihood across from low to high, impact up from low to high. Price rule sits at high likelihood and high impact, marked start here. Orders: medium likelihood, high impact. Coupons: high likelihood, medium impact. Refunds: medium and medium. Seat map: low likelihood, medium impact. Nightly report: low and low.\"><rect x=\"90.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"90.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"90.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"172.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"96.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"20.0\" width=\"150.0\" height=\"76.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">low</text><text x=\"82.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">low</text><text x=\"315.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">medium</text><text x=\"82.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">medium</text><text x=\"465.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">high</text><text x=\"82.0\" y=\"58.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">high</text><text x=\"315.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">likelihood</text><text x=\"30.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">impact</text><rect x=\"403.0\" y=\"46.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">price rule</text><rect x=\"403.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">coupons</text><rect x=\"253.0\" y=\"46.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">orders</text><rect x=\"253.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">refunds</text><rect x=\"103.0\" y=\"122.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">seat map</text><rect x=\"103.0\" y=\"198.0\" width=\"124.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nightly report</text><text x=\"465.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">start here</text></svg>", "caption": "Cine Aurora’s six areas before usage and history were added. The top right gets the most hours."}
```

## Reading the matrix

Plotted on a grid, likelihood across and impact up, the areas fall into zones. The top right is where testing starts and
where most of the hours go. The bottom left gets a quick check and nothing more. The other two corners need thought:

- **high impact, low likelihood**, like a seat map that double-books, is exactly where a team is tempted to skip
  testing because "that code never changes". A short check is cheap insurance;
- **high likelihood, low impact** is where defects will be found, and most of them will not matter much. Finding them is
  still worth something, but not first.

## The scores are a conversation, not a measurement

Nobody can measure that coupons have a likelihood of exactly 3. The numbers are a way of making three people say what
they believe and see where they disagree. When Joana scored refunds at 2 and Célia said a refund that fails in front of
a customer at the counter was the worst thing that could happen to her all week, the impact became 3 and the order
changed. That conversation is the value; the multiplication is just its record.

Two cautions keep the scores honest. **Write down why** each score is what it is, so a later reader can disagree with the
reason rather than the number. And **score again** when something changes: a hurried fix the day before release raises
a likelihood, whatever it was on Monday.
