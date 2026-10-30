---
title: Where Kotlin runs
version: 1
---

This course was reached through the Android door, and the next course is Android. The language is wider
than that door. **One Kotlin compiler has several back ends**, and each turns the same source into
something a different machine runs:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l20-targets\" aria-label=\"One box on the left, Kotlin source, with arrows to four back ends: Kotlin/JVM producing class files that run on servers, desktops and Android; Kotlin/JS producing JavaScript for browsers and Node.js; Kotlin/Wasm producing WebAssembly for browsers; Kotlin/Native producing machine code for Linux, macOS, Windows and iOS. The JVM and JS rows are marked as run in this lesson; the Native row as described and not run.\"><defs><marker id=\"l20-targets-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Kotlin source</text><text x=\"85\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.kt</text><rect x=\"240\" y=\"20\" width=\"340\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin/JVM</text><text x=\"490\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">class files: servers, Android</text><path d=\"M152 130 L238 42\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-targets-ah-wire)\"></path><text x=\"600\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">run here</text><rect x=\"240\" y=\"80\" width=\"340\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin/JS</text><text x=\"490\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JavaScript: browsers, Node.js</text><path d=\"M152 130 L238 102\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-targets-ah-wire)\"></path><text x=\"600\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">run here</text><rect x=\"240\" y=\"140\" width=\"340\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin/Wasm</text><text x=\"490\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">WebAssembly: browsers</text><path d=\"M152 130 L238 162\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-targets-ah-wire)\"></path><rect x=\"240\" y=\"200\" width=\"340\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"320\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Kotlin/Native</text><text x=\"490\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">machine code: Linux, macOS, iOS</text><path d=\"M152 130 L238 222\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-targets-ah-wire)\"></path><text x=\"600\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">described</text></svg>", "caption": "One compiler, four back ends: this lesson runs the JVM and JavaScript ones, and describes the native one."}
```

| back end | produces | runs on | where you meet it |
|---|---|---|---|
| Kotlin/JVM | `.class` files, in jars | any JVM: servers, desktops, Android | every lesson of this course |
| Kotlin/JS | JavaScript | browsers and Node.js | web front ends, Node tools |
| Kotlin/Wasm | WebAssembly | browsers and Wasm runtimes | web apps that need speed |
| Kotlin/Native | machine code | Linux, macOS, Windows, iOS, with no JVM | iOS apps, command-line tools |

Android is the JVM back end: an Android app is compiled to `.class` files and then converted to
Android's own bytecode, which is why every line of this course runs there unchanged.

**What changes from one back end to another is the library, not the language.** `java.io.File`, used
since lesson 13, is the JVM's; it exists on no other target. `List`, `map`, data classes, sealed types,
coroutines and `Flow` are Kotlin's own, and exist on all of them. Section 06 builds one function for two
back ends and shows where that line falls.

The rest of this lesson takes three steps out of the Android door, each small enough to run: a web
server on the JVM, a library compiled for the JVM and for JavaScript, and a script.
