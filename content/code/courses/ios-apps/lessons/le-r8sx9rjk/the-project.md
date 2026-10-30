---
title: The Xcode project: targets and schemes
version: 1
---

**An Xcode project is a list of things to build and the settings to build each one with.** It is a
directory, `Planner.xcodeproj`, that Xcode reads and writes; you change it through Xcode's editors
rather than by hand, and you commit it to git like any other source. Nothing in this section was run
for the course: it is written from Apple's documentation for Xcode projects, targets and schemes, as
it stood on 30 October 2026.

## Targets

A **target** is one product: an app, a framework, a set of tests. A new iOS app project made with
the *App* template gives you three:

- `Planner`, the app. Its build settings say which iOS it needs, which devices it runs on, and the
  bundle identifier section 07 is about;
- `PlannerTests`, unit tests, built into a bundle that runs inside the app;
- `PlannerUITests`, UI tests, which drive the app from outside as a person would. Lesson 20 writes
  both kinds.

**Each target has its own build settings**, and most of what you will change in this course is a
build setting of the app target: the deployment target, the bundle identifier, the version, the
signing team in lesson 21. A setting can be given at the project level and inherited, or overridden
per target, and Xcode's *Build Settings* tab shows which level each value came from.

## Schemes

A target says what to build. A **scheme** says what to do with it: which targets to build, which one
to run, which tests to run, and with which **build configuration**. A new project has two
configurations, `Debug` and `Release`. `Debug` compiles fast and keeps everything a debugger needs;
`Release` optimises, and it is what an archive for the App Store uses, which lesson 21 shows.

The scheme is what the *Run*, *Test* and *Archive* commands in Xcode's Product menu act on, and the
menu beside the stop button chooses both the scheme and the device or simulator to run on. A project
with one app target has one scheme, named after it, and that is all this course needs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l01-project\" aria-label=\"An Xcode project, Planner.xcodeproj, drawn as a large box holding three targets: the Planner app, PlannerTests and PlannerUITests. Below them, the Planner scheme, whose Run, Test and Archive actions point at the targets. To the right, outside the project, the planner directory: a Swift package whose library PlannerCore is linked into the app target. The project is built by Xcode on a Mac; the package is built by swift on any computer.\"><defs><marker id=\"l01-project-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l01-project-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-project-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l01-project-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"430\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Planner.xcodeproj</text><text x=\"235\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">built by Xcode, on a Mac</text><rect x=\"40\" y=\"70\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"104\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Planner</text><text x=\"104\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the app</text><rect x=\"178\" y=\"70\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"242\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerTests</text><text x=\"242\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unit tests</text><rect x=\"316\" y=\"70\" width=\"128\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PlannerUITests</text><text x=\"380\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">UI tests</text><text x=\"235\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">targets: what to build</text><rect x=\"40\" y=\"200\" width=\"394\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"237\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">scheme Planner</text><text x=\"237\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Run · Test · Archive, in Debug or Release</text><text x=\"237\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">scheme: what to do with them</text><path d=\"M104 200 L104 130\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><path d=\"M242 200 L242 130\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><path d=\"M380 200 L380 130\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-amber)\"></path><rect x=\"500\" y=\"70\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">planner/</text><text x=\"600\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Swift package</text><rect x=\"520\" y=\"124\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">PlannerCore</text><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">built by swift,</text><text x=\"600\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on any computer</text><path d=\"M520 144 L170 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-project-ah-phosphor)\"></path><text x=\"345\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">import PlannerCore</text></svg>", "caption": "A target is a product to build and a scheme says what to do with it. The package sits beside the project, and only its library crosses into the app."}
```

## The package beside the project

The planner's package from section 05 joins the project as a **local package**: in Xcode, *File*,
then *Add Package Dependencies*, then *Add Local*, and choose the `planner` directory. The package's
library, `PlannerCore`, then appears among the app target's frameworks, and any file of the app can
say `import PlannerCore`. Edit a file of the package in Xcode and the next build of the app picks it
up; run `swift test` in the package's directory and the same files are tested without Xcode at all.

**That arrangement is the course's way of being honest about the wall.** What is in the package is
practised and captured; what is in the app target is described from Apple's documentation. Lesson
14 moves more of the planner into the package, and lesson 20 tests it from both sides.

The app target's first file is the entry point. Lesson 2 is about what each line means; here it
shows that the app reaches the package:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    let plan = Plan(
        courses: [Course(id: "sql", title: "SQL Databases")],
        sessions: [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)]
    )

    var body: some Scene {
        WindowGroup {
            let total = plan.weekTotal(today: "2026-10-21")
            Text("\(total.done) of \(total.planned) minutes this week")
        }
    }
}
```

Not run: there is no Mac in this course's recording. On a Mac, *Run* builds this for the simulator
you picked and opens it there, and Apple's documentation for `Text` says it draws the string; the
string itself, `50 of 50 minutes this week`, is the package's arithmetic, which section 05 tested.
