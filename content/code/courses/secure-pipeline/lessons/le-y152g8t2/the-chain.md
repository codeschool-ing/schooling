---
title: The chain, drawn end to end
version: 1
---

"Supply chain security" is often read as "check the dependencies". Dependencies are one link. **The
chain is every step between somebody's intention and the software that runs**, and each step is a
place where what arrives can differ from what was meant. linkbox has all of them, small enough to
name:

1. **A person writes a change** and commits it to `~/linkbox`.
2. **The source repository** holds it: `~/ci/linkbox.git` here, GitHub or GitLab elsewhere.
3. **The build** turns source into an artefact: the hook clones the commit and runs `ci/pipeline.sh`,
   which runs `docker build`.
4. **Dependencies** enter the build from outside: the base images from Docker Hub and gcr.io, the
   Python packages from PyPI, the scanners from GitHub releases.
5. **The artefact** is published: `ci/push.sh` sends the image to the registry.
6. **The registry** distributes it: `localhost:5000`, or Docker Hub, or PyPI for a library.
7. **The consumer chooses and deploys it**: the kind cluster pulls `localhost:5000/linkbox:main`.

### SLSA's letters

SLSA (Supply-chain Levels for Software Artifacts, said "salsa") is a framework of the Open Source
Security Foundation that names the threats along this chain and grades the controls against them.
Its threat overview labels each point with a letter. The letters are worth knowing, because incident write-ups and tools use them:

| letter | threat to | in linkbox |
|---|---|---|
| A | the producer: the people who make the software | whoever can commit |
| B | authoring and reviewing a change | a commit nobody else read |
| C | source code management | `~/ci/linkbox.git`, its history and its hooks |
| D | the build's external parameters | what the build was told to build, and from where |
| E | the build process | the hook and `ci/pipeline.sh` running as ana |
| F | artefact publication | `docker push` from `ci/push.sh` |
| G | the distribution channel | the registry, a mirror, a CDN |
| H | package selection | which name and version the consumer asks for |
| I | usage | how the deployed software is configured and run |

Dependencies are not a letter of their own: **each dependency has this whole chain behind it**, A to
H again, inside somebody else's project. A compromised dependency is one of those letters going wrong
one level down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l12-chain\" aria-label=\"The software supply chain from a person's change to the running software, with SLSA's threat letters. A person writes a change (A, B), the source repository holds it (C), the build is told what to build (D) and builds it (E), the artefact is published (F) through a registry (G), the consumer chooses a package (H) and runs it (I). Each dependency enters the build carrying the same chain, A to H, inside another project.\"><defs><marker id=\"sp-l12-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l12-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A · B</text><text x=\"64.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">person and change</text><text x=\"64\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/linkbox</text><rect x=\"128\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"182.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">source</text><text x=\"182\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/ci/linkbox.git</text><path d=\"M116 68 L126 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"246\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">D · E</text><text x=\"300.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">build</text><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/pipeline.sh</text><path d=\"M234 68 L244 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"364\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">F</text><text x=\"418.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">publish</text><text x=\"418\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/push.sh</text><path d=\"M352 68 L362 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"482\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">G</text><text x=\"536.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registry</text><text x=\"536\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:5000</text><path d=\"M470 68 L480 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"600\" y=\"40\" width=\"108\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">H · I</text><text x=\"654.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">choose and run</text><text x=\"654\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">kind</text><path d=\"M588 68 L598 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-paper-dim)\"></path><rect x=\"150\" y=\"170\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"315.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">each dependency</text><text x=\"315.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the same chain, A to H, in somebody else's project</text><path d=\"M315 168 L315 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-chain-ah-amber)\"></path></svg>", "caption": "Seven steps between an intention and running software, and a dependency is the whole chain again, one level down."}
```

### What "where it breaks" means

At each letter, the question is the same: **could what arrives here differ from what was intended,
and would anybody notice?** For linkbox, today:

- a commit could be made by anybody with access to ana's account, and nothing records who reviewed
  it (A, B);
- the build runs on a laptop, as the same user who writes the code, with Docker access, which lesson
  16 names for what it is (E);
- the dependencies are pinned by version but not by hash, so a different file under the same version
  would be installed (the dependency chains, H);
- the image is pushed by tag, and a tag can be moved to point at other bytes (F, G);
- the cluster deploys whatever `main` points at, with no check of who built it (H, I).

None of that is a mistake for a study project, and the course closes most of it: lesson 13 records
what is in the artefact, lesson 14 signs it and records how it was built, lesson 15 pins
dependencies by hash, lesson 16 hardens the build. **The point of drawing the chain first is that a
control belongs to a letter**, and a team that knows which letter a control covers also knows which
letters nothing covers.

The next two sections place seven public incidents on this chain, each with the control that would
have caught it.
