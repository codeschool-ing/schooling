---
title: What Bazel is for
version: 1
---

The tempting picture is that Bazel is a third Maven: one more file format that downloads
dependencies and runs `javac`, perhaps a faster one. It does download and it does compile, but
the picture misses what Bazel is built around. **Bazel knows nothing about Java.** It knows
**actions**: commands with every input and every output declared in advance. Teaching it Java is
the job of a set of rules, `rules_java`, loaded like a library. Maven, by contrast, starts from
Java's conventions and fills in the rest.

Bazel began inside Google as **Blaze**, the tool that builds Google's single repository, which
holds most of the company's code in many languages. Google published it as Bazel in 2015. Its
design follows from that one repository: when a change touches one file among millions, the build
has to find exactly what that file affects, rebuild that and nothing else, and run only the tests
the change could have broken.

## Hermetic, so it can be cached

An action is **hermetic** when nothing outside its declared inputs can change its result. Bazel
enforces it: each action runs in a sandbox where only the declared files exist, so a source file
somebody forgot to declare is a compile error on every machine, rather than a build that works on
the laptop where the file happens to be present. The tools count as inputs too. Left to itself,
Bazel downloads the JDK it compiles with and pins it, instead of using whichever `java` the
machine has on its `PATH`.

That discipline pays for the cache. Because every input is known, Bazel can hash them all into an
**action key**, and two actions with the same key produce the same output wherever they run:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Four inputs of one compile action, the source file, the jar it uses, the javac command line and the JDK, are hashed together into one action key. With the key, Bazel looks in its local cache, then in a remote cache the team shares, and only when neither has the output does it run javac and store the result under the key.\"><defs><marker id=\"bz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IsbnCheck.java</text><line x1=\"220\" y1=\"38\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"75\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">commons-validator-1.11.0.jar</text><line x1=\"220\" y1=\"93\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"130\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the javac command line</text><line x1=\"220\" y1=\"148\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"20\" y=\"185\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the JDK it runs on</text><line x1=\"220\" y1=\"203\" x2=\"268\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><rect x=\"270\" y=\"95\" width=\"150\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">action key</text><text x=\"345\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a hash of every input</text><rect x=\"470\" y=\"20\" width=\"210\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  look in the local cache</text><rect x=\"470\" y=\"85\" width=\"210\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  then in the remote cache</text><text x=\"575\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the whole team shares</text><rect x=\"470\" y=\"160\" width=\"210\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  only then run javac,</text><text x=\"575\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">and store the output under the key</text><line x1=\"420\" y1=\"125\" x2=\"468\" y2=\"38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#bz-ah)\"></line><line x1=\"575\" y1=\"56\" x2=\"575\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#bz-ah)\"></line><line x1=\"575\" y1=\"131\" x2=\"575\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#bz-ah)\"></line><text x=\"575\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a hit at 1 or 2 never starts the compiler</text></svg>", "caption": "One action, as Bazel sees it. Change any input and the key changes; change none and the output already exists somewhere."}
```

The **local cache** lives under `~/.cache/bazel` and makes the second build on a machine fast,
which Gradle's incremental build in lesson 2 also does. The **remote cache** is where the design
earns its keep: a server the whole team and the CI machines share. A colleague who compiled the
same commit an hour ago has already stored the outputs, so your build downloads them instead of
compiling. **Remote execution** goes one step further and sends the actions themselves to a farm
of machines, so a build of thousands of targets runs a thousand compilers at once. Both speak one
open protocol, the Remote Execution API, and several companies sell them as a service.

## Where a Java developer meets it

Mostly in two places. The first is a company with a **monorepo**, one repository holding many
services and libraries, often in several languages at once: Java services beside Go tools, a
TypeScript front end and the Protocol Buffers files they all share. Maven and Gradle build one
language well and the rest through plugins; Bazel builds them all with one graph, and `bazel test
//...` reruns only the tests a commit could have changed. The second is an open-source project
that builds with it. Selenium and the code-review server Gerrit, both largely Java, are two you
may clone one day and find a `MODULE.bazel` where you expected a `pom.xml`.

What you are unlikely to meet is a Spring Boot service of one team, built with Bazel, standing on
its own. The last section of this lesson says why.
