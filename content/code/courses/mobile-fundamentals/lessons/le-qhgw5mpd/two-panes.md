---
title: List and detail, as one pane or two
version: 1
---

**The planner has two screens that belong together, the list of courses and one course's detail,
and a wide window shows them side by side instead of one after the other.** On a phone in portrait
the student taps a course, its detail replaces the list, and *back* returns to the list. On a
tablet in landscape the list stays on the left and the detail fills the right; tapping another
course changes the right side and nothing else. Android's documentation calls this a canonical
layout, *list-detail*, and the pattern is the same on iOS, where a split view does the job.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-panes\" aria-label=\"Two ways to show the planner. On the left, one pane: the course list fills the window, tapping a course replaces it with that course's detail, and back returns to the list. On the right, two panes in a wide window: the list stays on the left with the selected course highlighted, and its detail fills the right.\"><defs><marker id=\"l08-panes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">one pane: the list, then the detail</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">two panes: list and detail side by side</text><rect x=\"20\" y=\"36\" width=\"130\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Courses</text><rect x=\"28\" y=\"66\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sql</text><rect x=\"28\" y=\"96\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">mobile</text><rect x=\"28\" y=\"126\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kotlin</text><rect x=\"200\" y=\"36\" width=\"130\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sql</text><rect x=\"208\" y=\"66\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-19  50 min</text><rect x=\"208\" y=\"96\" width=\"114\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-23  60 min</text><path d=\"M150 80 L200 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-panes-ah-paper-dim)\"></path><text x=\"175\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tap</text><path d=\"M200 190 L150 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-panes-ah-paper-dim)\"></path><text x=\"175\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">back</text><rect x=\"380\" y=\"36\" width=\"320\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"388\" y=\"44\" width=\"120\" height=\"174\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"398\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Courses</text><rect x=\"396\" y=\"74\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sql</text><rect x=\"396\" y=\"104\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">mobile</text><rect x=\"396\" y=\"134\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kotlin</text><rect x=\"516\" y=\"44\" width=\"176\" height=\"174\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"526\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sql</text><rect x=\"524\" y=\"74\" width=\"160\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"534\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-19  50 min</text><rect x=\"524\" y=\"104\" width=\"160\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"534\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">2026-10-23  60 min</text></svg>", "caption": "The same two screens, arranged by the window. In one pane the detail replaces the list and back brings it back; in two panes the list never leaves, so there is nothing to go back to."}
```

## The switch is a size-class decision

**The rule the planner uses is a size-class rule, written once**: two panes when the window is at
least expanded wide, 840 dp, and not compact tall. Below that, one pane. The height condition is
there for the case Android's documentation names: a phone in landscape can be wide enough, and
too short for two panes to hold anything useful.

Two consequences come out of a rule like that, and both are easy to miss:

- **The same app moves between the two while it is running.** A foldable opened with the detail
  on screen goes from one pane to two, and closed again goes back. The selected course has to
  survive the change, because it is state, not layout: in two panes it is the highlighted row, in
  one pane it is the screen on top.
- **Back means something different in each.** In one pane, back from the detail returns to the
  list. In two panes there is nothing to go back to, because the list never left. Lesson 10 is
  about the back stack, and this is the first place it changes with the window.

## Foldables: a hinge and a posture

A foldable adds two facts a flat screen does not have. Android's documentation on fold-aware apps
lists what the system reports about a fold or hinge: whether the device is *flat* or *half open*,
whether the fold runs horizontally or vertically, whether the hinge hides part of the display, and
whether it divides the window into two logical areas. It names two postures an app may design for:
*tabletop*, half open with the fold horizontal, like a small laptop, and *book*, half open with the
fold vertical.

**For the planner, the useful fact is the vertical fold that separates the window.** If a hinge
divides the window down the middle, the two panes should meet at the hinge, so that nothing is
drawn across it, and the list and the detail each get one half. The same documentation notes that
the system does not report the hinge's angle, so an app reacts to the posture rather than to a
number of degrees.

## Split screen is the same question, smaller

**Half of a tablet in split screen can be a medium window, and then the planner shows one pane
there**, exactly as on a large phone, even though the device is a tablet. That is the point of asking about
the window: the tablet did not change, the space did. iPad's own multitasking does the same, and
Apple's guidelines name the multitasking state, such as an app in Slide Over, among what sets an
app's size classes.

The section after this one runs the rule over nine example windows, including the same foldable
folded and open, and the same tablet whole and halved.
