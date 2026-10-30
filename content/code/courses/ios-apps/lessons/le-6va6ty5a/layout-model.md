---
title: The stack's arithmetic, as a model you can run
version: 1
---

**An `HStack` shares its width out by asking each child how flexible it is and serving the least
flexible first.** Apple's documentation for `ProposedViewSize` describes the measuring half: a
container proposes special sizes to a child, zero for its minimum, infinity for its maximum and
nothing for its ideal, and an `HStack` might use the answers to measure how flexible each child's
width is. The order that follows, least flexible first, is the one Apple's WWDC19 session *Building
Custom Views with SwiftUI* describes for stacks.

This section turns that into about fifty lines of plain Swift. **It is a model, written for this
course, and it is not SwiftUI**: it leaves out layout priority, a spacer's minimum length, heights,
and everything else a real stack weighs. What it keeps is the arithmetic of section 02's three steps,
which is the part people get wrong. Save it as `layout.swift` in `~/l04`:

```schooling-example
{"language": "swift", "file": "layout.swift", "parts": [{"code": "// layout.swift: a model of how a horizontal stack shares out its width\nimport Foundation\n\n/// What a parent offers: a width, or nil for \"whatever you would like\".\nstruct Proposal { var width: Double? }\n\nprotocol Child {\n    var name: String { get }\n    func width(for proposal: Proposal) -> Double\n}\n", "note": "Step one and step two of section 02, as types. A `Proposal` is the parent's offer, and every child answers it with the width it chooses. Only width, to keep the arithmetic readable."}, {"code": "/// Stands for Text: its ideal width, or less when offered less.\nstruct Label: Child {\n    let name: String\n    let ideal: Double\n    func width(for p: Proposal) -> Double { min(ideal, p.width ?? ideal) }\n}\n\n/// Stands for Spacer(minLength: 0): all the width it is offered.\nstruct Gap: Child {\n    let name = \"Spacer\"\n    func width(for p: Proposal) -> Double { p.width ?? 0 }\n}\n\n/// Stands for .frame(width:): its own width, whatever it is offered.\nstruct Fixed: Child {\n    let name: String\n    let fixed: Double\n    func width(for p: Proposal) -> Double { fixed }\n}\n", "note": "Three kinds of child. A label takes its ideal width or less and never more; a gap takes everything; a fixed frame ignores the offer. The ideal widths given to the labels below are numbers chosen for the model: real text is measured in its font."}, {"code": "/// How much a child's width moves between being offered nothing and everything.\nfunc flexibility(_ c: Child) -> Double {\n    c.width(for: Proposal(width: .infinity)) - c.width(for: Proposal(width: 0))\n}\n", "note": "The two special proposals from Apple's documentation, infinity and zero, and the difference between the answers. A fixed frame scores 0, a label its ideal width, a gap infinity."}, {"code": "func hstack(_ children: [Child], width: Double, spacing: Double = 8) {\n    print(\"offered \\(Int(width)):\")\n    var remaining = width - spacing * Double(children.count - 1)\n    var widths = [Double](repeating: 0, count: children.count)\n    let leastFlexibleFirst = children.indices.sorted { flexibility(children[$0]) < flexibility(children[$1]) }\n    for (served, i) in leastFlexibleFirst.enumerated() {\n        let share = remaining / Double(children.count - served)\n        widths[i] = children[i].width(for: Proposal(width: share))\n        remaining -= widths[i]\n    }\n", "note": "The stack takes the spacing off first, then serves the children least flexible first. Each is offered an equal share of what is left, chooses, and what it did not take goes back into the pot for the ones still waiting."}, {"code": "    var x = 0.0\n    for (child, w) in zip(children, widths) {\n        print(\"  \" + child.name.padding(toLength: 20, withPad: \" \", startingAt: 0)\n              + String(format: \"x %5.1f  width %5.1f\", x, w))\n        x += w + spacing\n    }\n}\n", "note": "Step three: placing. The children go left to right in the order they were written, which is not the order they were served in."}, {"code": "let row: [Child] = [Label(name: \"SQL Databases\", ideal: 104), Gap(), Label(name: \"50 min\", ideal: 48)]\nhstack(row, width: 360)\nhstack([Fixed(name: \"icon\", fixed: 24), Label(name: \"Mobile Fundamentals\", ideal: 150),\n        Label(name: \"40 min\", ideal: 48)], width: 180)\n", "note": "Two rows of the planner's course list: one with room to spare, and one too narrow for its title."}]}
```

```
ana@vm:~/l04$ swift layout.swift
offered 360:
  SQL Databases       x   0.0  width 104.0
  Spacer              x 112.0  width 192.0
  50 min              x 312.0  width  48.0
offered 180:
  icon                x   0.0  width  24.0
  Mobile Fundamentals x  32.0  width  92.0
  40 min              x 132.0  width  48.0
```

**In the first row the spacer gets what the labels did not want**, 192 points, because it was served
last. That is how a `Spacer` pushes `50 min` to the right edge without anyone computing where the
edge is.

**In the second row the title is the one that gives way.** The icon was served first and took its
24; `40 min` was served next, offered 70 and took its 48; the title came last and got the 92 that
remained, against an ideal of 150. In SwiftUI a `Text` given less than it wants truncates or wraps,
which lesson 5 decides between. Notice that the label written in the middle was served last: **the
order of service is flexibility, not position.**

What the model cannot tell you is exactly how SwiftUI would draw these rows on a phone. The numbers
are the model's, and a Mac running these views in a preview would measure the text and might differ.
The rule the numbers illustrate, least flexible first and the leftover to the rest, is the one to
carry into lesson 5, where modifiers wrap views in new layout participants of their own.
