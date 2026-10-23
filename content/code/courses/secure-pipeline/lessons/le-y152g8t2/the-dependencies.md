---
title: "Incidents in the dependencies: event-stream, ua-parser-js, torchtriton, xz"
version: 1
---

Four incidents in which the victims' own build was sound and the problem arrived inside something
they depended on. **Each one is a different way for a package to change hands**: given away, stolen,
impersonated, or earned over two years. Each is told from the public write-ups, at the level of what
broke and what would have caught it.

### event-stream, 2018: a maintainer hand-off

event-stream was a popular npm package whose author had lost interest in it. In September 2018 a
volunteer offered to maintain it, and the author handed over publishing rights. The new maintainer
added a dependency, `flatmap-stream`, and a later release of that dependency carried obfuscated code
that targeted one particular application, the Copay bitcoin wallet. It was found in November 2018.

**The malicious code was in the release of `flatmap-stream` published to npm and not in its
source on GitHub**, which is
why SLSA uses it as its example of a dependency threat: a package that does not match its source.

What would have caught it:

- **Reading the lockfile's diff**: a new transitive dependency appearing in a minor release is a
  change worth a look, and it is visible only if somebody reads it.
- **Watching who publishes**: a change of maintainer on a package you depend on is an event, not a
  detail.
- **Provenance linking a package to its source**, so that a published file with no matching source
  stands out.

### ua-parser-js, 2021: a stolen account

ua-parser-js parses browser user-agent strings and was downloaded millions of times a week. In
October 2021 the maintainer's npm account was taken over, and three versions were published, 0.7.29,
0.8.0 and 1.0.0, **that installed a cryptocurrency miner and, on Windows, a program that stole
passwords**. The maintainer noticed within hours and released fixed versions; CISA, the United
States' cybersecurity agency, issued an alert.

What would have caught it:

- **Two-factor authentication on publishing accounts**, which registries have since required of the
  maintainers of popular packages.
- **A lock that does not take new versions by itself**: a project whose lockfile pinned 0.7.28
  installed 0.7.28 that day.
- **A cooling-off period**: a release younger than a few days is not adopted automatically. Lesson
  15 resolves with a date for this reason, and lesson 18 gives the update bot a minimum age.

### torchtriton, 2022: a name nobody had claimed

PyTorch's nightly builds depended on a package called `torchtriton`, served from PyTorch's own
index. Nobody had registered that name on PyPI. Somebody did, and between 25 and 30 December 2022
users who installed the Linux nightly with pip got the PyPI package instead, **because pip, given
both indexes, took the one on PyPI**. It collected information from the machine and sent it out.
PyTorch renamed the dependency, claimed the new name on PyPI, and published the steps to check for
and remove the package.

What would have caught it is the subject of the next section: one index, hashes, and claimed names.
SLSA puts it at letter H, the choice of package.

### xz-utils, 2024: trust earned over two years

xz is a compression library present in nearly every Linux distribution. Over about two years a
contributor using the name Jia Tan became a trusted co-maintainer of the project, which had had a
single, overworked maintainer. In February and March 2024 versions 5.6.0 and 5.6.1 were released
with a backdoor aimed at the SSH server on some distributions. **The part that activated it was in
the release tarballs and not in the Git repository**, hidden among build files that people rarely
read.

On 29 March 2024 Andres Freund, a developer investigating why SSH logins on a Debian test system
used more processor time than they should, traced it and reported it. It was given CVE-2024-3094.
It had reached rolling and development releases of some distributions, and was caught before the
stable releases of the major ones.

What would have caught it:

- **Building from the repository rather than the release tarball**, or comparing the two: the
  difference was exactly where the backdoor was. In SLSA's terms, an artefact built from something
  other than its source.
- **Paying attention to a project's health**: one unpaid maintainer under pressure is a risk to
  every project that depends on him, and lesson 15 reads that health before adopting a package.
- **Noticing**: it was caught by a person who looked at a half-second delay instead of ignoring it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"sp-l12-timeline\" aria-label=\"Seven incidents placed by year, from 2018 to 2025, and by the link of the chain where they broke. Dependencies: event-stream 2018, ua-parser-js 2021, torchtriton 2022, xz-utils 2024. The build and what feeds it: SolarWinds 2020, Codecov 2021, tj-actions 2025.\"><defs></defs><text x=\"66\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2018</text><line x1=\"66\" y1=\"40\" x2=\"66\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"152\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2019</text><line x1=\"152\" y1=\"40\" x2=\"152\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"238\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2020</text><line x1=\"238\" y1=\"40\" x2=\"238\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"324\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2021</text><line x1=\"324\" y1=\"40\" x2=\"324\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"410\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2022</text><line x1=\"410\" y1=\"40\" x2=\"410\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"496\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2023</text><line x1=\"496\" y1=\"40\" x2=\"496\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"582\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2024</text><line x1=\"582\" y1=\"40\" x2=\"582\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"668\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025</text><line x1=\"668\" y1=\"40\" x2=\"668\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"10\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">in a dependency</text><text x=\"10\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">in the build and its inputs</text><rect x=\"22\" y=\"49\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">event-stream</text><rect x=\"280\" y=\"39\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ua-parser-js</text><rect x=\"366\" y=\"75\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">torchtriton</text><rect x=\"538\" y=\"49\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"582.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">xz-utils</text><rect x=\"198\" y=\"147\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SolarWinds</text><rect x=\"284\" y=\"177\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Codecov</text><rect x=\"628\" y=\"147\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tj-actions</text></svg>", "caption": "Seven years, seven incidents, and none of them in the code the victims reviewed."}
```

| incident | year | how the package changed hands | the control |
|---|---|---|---|
| event-stream | 2018 | given to a volunteer | read the lockfile diff; watch maintainers |
| ua-parser-js | 2021 | publishing account stolen | 2FA; locked versions; a cooling-off period |
| torchtriton | 2022 | an unclaimed name registered | one index; hashes; claimed names |
| xz-utils | 2024 | trust earned over years | build from source; compare tarball and repository |
