---
title: The wrappers, built in plain Swift
version: 1
---

**Every claim in this lesson about wrapping and order can be checked without SwiftUI, by building the
wrappers as ordinary generic types.** That is what this section does: a text, a padding and a
background, each a `Layer` with a size, and two methods that wrap one layer in another exactly the way
a modifier does. It is a model, written for this course; SwiftUI's real types are more numerous and
private. The arithmetic is section 03's.

Save this as `wrappers.swift` in `~/l05`:

```schooling-example
{"language": "swift", "file": "wrappers.swift", "parts": [{"code": "// wrappers.swift: modifiers as wrapper types, each one a layer with a size\nstruct Size: CustomStringConvertible {\n    var width: Double, height: Double\n    var description: String { \"\\(Int(width)) by \\(Int(height))\" }\n}\n\nprotocol Layer {\n    var label: String { get }\n    func size(offered: Size) -> Size\n    func inner() -> (any Layer)?\n}\n", "note": "A layer can say what it is, what size it chooses for an offer, and what is inside it, if anything."}, {"code": "/// Stands for Text: 8 points a character, 20 high.\nstruct Words: Layer {\n    let text: String\n    var label: String { \"Words(\\\"\\(text)\\\")\" }\n    func size(offered: Size) -> Size { Size(width: Double(text.count) * 8, height: 20) }\n    func inner() -> (any Layer)? { nil }\n}\n", "note": "The innermost layer, standing for a `Text`. Eight points a character is the model's number, not a font's."}, {"code": "/// Stands for .padding(n): offers less inward, reports more outward.\nstruct Padded<Content: Layer>: Layer {\n    let content: Content, amount: Double\n    var label: String { \"padding \\(Int(amount))\" }\n    func size(offered: Size) -> Size {\n        let inside = content.size(offered: Size(width: offered.width - 2 * amount,\n                                                height: offered.height - 2 * amount))\n        return Size(width: inside.width + 2 * amount, height: inside.height + 2 * amount)\n    }\n    func inner() -> (any Layer)? { content }\n}\n", "note": "Padding, as lesson 4 section 06 described it: it proposes the offer minus the padding to what it wraps, and reports that size plus the padding."}, {"code": "/// Stands for .background(colour): exactly the size of what it wraps.\nstruct Filled<Content: Layer>: Layer {\n    let content: Content, colour: String\n    var label: String { \"background \\(colour)\" }\n    func size(offered: Size) -> Size { content.size(offered: offered) }\n    func inner() -> (any Layer)? { content }\n}\n", "note": "A background takes the size of what it wraps, no more and no less. That one line is why order matters."}, {"code": "extension Layer {\n    func padding(_ amount: Double = 16) -> Padded<Self> { Padded(content: self, amount: amount) }\n    func background(_ colour: String) -> Filled<Self> { Filled(content: self, colour: colour) }\n}\n", "note": "The modifier syntax: a method that returns a new value wrapping `self`, with a type built from `Self`."}, {"code": "/// Print each layer from the outside in, with the size it reports.\nfunc show(_ view: some Layer) {\n    print(type(of: view))\n    var layer: (any Layer)? = view\n    var depth = 1\n    while let l = layer {\n        let indent = String(repeating: \"  \", count: depth)\n        print(indent + l.label + \": \" + l.size(offered: Size(width: 390, height: 800)).description)\n        layer = l.inner()\n        depth += 1\n    }\n}\n\nshow(Words(text: \"50 min\").padding().background(\"yellow\"))\nshow(Words(text: \"50 min\").background(\"yellow\").padding())\n", "note": "Section 03's two chains, offered a 390-by-800 space, each printed as its type and then layer by layer."}]}
```

```
ana@vm:~/l05$ swift wrappers.swift
Filled<Padded<Words>>
  background yellow: 80 by 52
    padding 16: 80 by 52
      Words("50 min"): 48 by 20
Padded<Filled<Words>>
  padding 16: 80 by 52
    background yellow: 48 by 20
      Words("50 min"): 48 by 20
```

**The types are the chains, read backwards.** `Filled<Padded<Words>>` is "a background around a
padding around a text", which is the first chain, `.padding().background(…)`. The first modifier
written is the innermost type.

**And the sizes are section 03's picture in numbers.** In the first chain the yellow layer reports
80 by 52: the text's 48 by 20 plus 16 on every side. In the second the yellow layer reports 48 by 20,
the text's own size, and the padding outside it brings the total to 80 by 52 with nothing painted in
the extra space. Same outer size, different yellow.
