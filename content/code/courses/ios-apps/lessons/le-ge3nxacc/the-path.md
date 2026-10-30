---
title: The path is an array you own
version: 1
---

**Give `NavigationStack` a binding to an array of values, and the array is the stack.** Every value
in it is a screen pushed; the first is the screen above the root, the last is the one on top. A link
tapped by the person appends to it, the back button removes the last element, and code can do either
by changing the array. Nothing that SwiftUI does here was run for the course; the array itself is
plain Swift and is built below.

```swift
// in PlannerModel, from this lesson on
public var path: [Route] = []
```

```swift
// CourseListView.swift
struct CourseListView: View {
    @Environment(PlannerModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.path) {
            List(model.plan.courses) { course in
                NavigationLink(course.title, value: Route.course(id: course.id))
            }
            .navigationDestination(for: Route.self) { route in
                RouteView(route: route)
            }
        }
    }
}
```

**Navigating in code is changing an array**, and every operation a screen needs is one line of it:

| the person or the app… | the path |
|---|---|
| taps the SQL course | `[.course(id: "sql")]` |
| then taps session `s3` | `[.course(id: "sql"), .session(id: "s3")]` |
| taps back | `path.removeLast()` → `[.course(id: "sql")]` |
| saves a new session and returns to the list | `path.removeAll()` → `[]` |
| opens a link to session `s3` | `path = [.course(id: "sql"), .session(id: "s3")]` |

The last row is the reason to keep the path in the model rather than let SwiftUI keep it. A
notification tapped by the person, lesson 17, or a link from another app, section 06, has to put the
app on a particular screen, and with the path in hand that is an assignment. Apple's documentation
for `NavigationStack` also offers `NavigationPath`, a type-erased path for stacks that push values
of several types; the planner pushes one type, `Route`, so a plain array says more.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-path\" aria-label=\"On the left, a stack of three screens drawn as overlapping cards: the root, CourseListView, which is not in the path; above it the SQL course; on top, session s3. On the right, the path array, model.path, with two elements, .course(id: &quot;sql&quot;) at index 0 and .session(id: &quot;s3&quot;) at index 1, each joined by a line to the screen it pushes. Below, the operations: a tap appends, back removes the last element, and a deep link assigns the whole array.\"><defs><marker id=\"l09-path-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l09-path-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-path-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l09-path-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"150\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseListView</text><text x=\"165\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the root, not in the path</text><rect x=\"70\" y=\"100\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CourseDetailView</text><text x=\"195\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">course sql</text><rect x=\"100\" y=\"50\" width=\"250\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SessionDetailView</text><text x=\"225\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">session s3, on top</text><text x=\"560\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">model.path</text><rect x=\"440\" y=\"50\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"452\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"570\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.session(id: \"s3\")</text><rect x=\"440\" y=\"100\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"452\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"570\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.course(id: \"sql\")</text><path d=\"M440 70 L354 72\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-path-ah-amber)\"></path><path d=\"M440 120 L324 122\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-path-ah-amber)\"></path><text x=\"440\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tap a link</text><text x=\"540\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path.append(…)</text><text x=\"440\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">back</text><text x=\"540\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path.removeLast()</text><text x=\"440\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deep link</text><text x=\"540\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path = […]</text></svg>", "caption": "The path holds one value per pushed screen, the root excluded. Navigating is changing the array: append to push, remove the last to go back, assign it to jump."}
```

## The route type

Copy lesson 1's package for this lesson, `cp -r ~/planner ~/navigate`, and add the type the whole
lesson uses. Save this as `Sources/PlannerCore/Route.swift`:

```swift
// Sources/PlannerCore/Route.swift
import Foundation

/// One screen the planner can push, named by the id of what it shows.
public enum Route: Hashable, Codable, Sendable {
    case course(id: String)
    case session(id: String)
    case week(day: String)
}
```

**The associated values are labelled, `id:` and `day:`,** and that is for section 05, where the
labels become the keys of the saved JSON. `Hashable` and `Codable` are both synthesised by the
compiler because every associated value is a `String`, which is both. Build it:

```
ana@vm:~/navigate$ swift build
Building for debugging...
[Pre-planning 1 / 95]
[4 / 8] PlannerCore
[6 / 10] PlannerCore
[13 / 14] PlannerCore
[18 / 21] week-product
[22 / 22] week-product
Build complete! (1.07 secs)
```
