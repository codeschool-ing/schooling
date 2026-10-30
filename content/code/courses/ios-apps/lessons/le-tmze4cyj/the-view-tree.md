---
title: The view hierarchy the planner will grow
version: 1
---

**Inside a scene, everything on the screen is a tree of views, and the root is the view the scene
was given.** For the planner that is `CourseListView`. Each view's `body` names the views it is made
of, those name theirs, and the tree ends at views SwiftUI draws itself: `Text`, `Image`, a `Toggle`.
Nothing on the screen is outside the tree, and nothing in the tree is drawn by a view that is not in
it.

The picture worth replacing is a screen as a canvas you paint on and repaint. **In SwiftUI you never
paint.** You say what the tree is for the data you have, SwiftUI draws it, and when the data changes
you say what it is now. Lesson 3 is about how SwiftUI turns two such descriptions into the few
changes the screen actually needs.

## The planner's four screens

The planner has the same four screens on every platform this track builds it on, and these are their
names in this course:

| view | what it shows | built in |
|---|---|---|
| `CourseListView` | the courses, each with the minutes planned this week | lessons 6 and 8 |
| `CourseDetailView` | one course's sessions, with a way to mark one done and to add one | lessons 8 and 9 |
| `SessionForm` | a date and a number of minutes for a new session | lesson 10 |
| `WeekView` | the week's total, planned against done | lesson 6 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-tree\" aria-label=\"The planner&#x27;s view tree. PlannerApp at the top, then WindowGroup, then CourseListView. Below CourseListView, CourseDetailView, and below that SessionForm; WeekView hangs from CourseListView as well. Data travels down the tree, drawn as arrows pointing down on the left; events travel up as changes to data a parent owns, drawn as arrows pointing up on the right.\"><defs><marker id=\"l02-tree-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l02-tree-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-tree-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l02-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"13\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PlannerApp</text><rect x=\"280\" y=\"68\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WindowGroup</text><rect x=\"280\" y=\"123\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseListView</text><rect x=\"180\" y=\"183\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CourseDetailView</text><rect x=\"390\" y=\"183\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WeekView</text><rect x=\"180\" y=\"243\" width=\"160\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionForm</text><path d=\"M360 47 L360 66\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 102 L360 121\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 157 L260 181\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M360 157 L470 181\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M260 217 L260 241\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-wire)\"></path><path d=\"M70 60 L70 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-phosphor)\"></path><text x=\"70\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">data goes down</text><path d=\"M650 250 L650 60\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-tree-ah-amber)\"></path><text x=\"650\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">events go up</text></svg>", "caption": "The four screens in one tree. Lesson 6 makes the downward arrow a value and the upward one a Binding."}
```

**Two kinds of thing travel through the tree, in opposite directions.** Data goes down: a parent
creates a child and hands it what it needs to draw, the way `CourseListView` will hand each row its
course. Events go up: a tap on a row, a toggle flipped, a form saved. In SwiftUI an event travels up
as a change to data the parent owns, through a `Binding`, which is lesson 6, or through an
observable model, which is lesson 7.

## A first version, with nothing in it yet

So that lesson 3 has something to take apart, here is the smallest `CourseListView` that compiles
against the package. Nothing here was run; it is written from Apple's documentation for `View`,
`List` and `Text`:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let courses = [
        Course(id: "sql", title: "SQL Databases"),
        Course(id: "mobile", title: "Mobile Fundamentals"),
    ]

    var body: some View {
        List(courses) { course in
            Text(course.title)
        }
    }
}
```

`List(courses)` can take the array directly because `Course` is `Identifiable`, which lesson 1 gave
it for this reason. Lesson 8 is about why that identity matters more than it looks, and what goes
wrong when a list is built on positions instead.
