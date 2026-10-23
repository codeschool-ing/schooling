---
title: Updating as a routine
version: 1
---

Pinning moves the risk from surprise to neglect. A pinned version never breaks on its own, and it
never gets fixed on its own either. **The defence is a routine, small enough that it actually
happens**, rather than a large update every two years that nobody dares to start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l17-loop\" aria-label=\"The routine that keeps pinned dependencies safe, drawn as a loop of five steps. Pin exact versions. An advisory is published for one of them. The audit run on every change fails and names the fixed version. Raise the pin to that version and run the tests. Commit the new pin, and the loop starts again.\"><defs><marker id=\"l17-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"20\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pin exact versions</text><rect x=\"510\" y=\"90\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an advisory is published</text><rect x=\"430\" y=\"180\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the audit fails, naming</text><text x=\"530.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the fixed version</text><rect x=\"110\" y=\"180\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">raise the pin,</text><text x=\"210.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the tests</text><rect x=\"20\" y=\"90\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">commit the new pin</text><path d=\"M450 40 L605 40 L605 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M605 130 L605 155 L530 155 L530 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M430 205 L310 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M160 180 L110 180 L110 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M110 90 L110 40 L270 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path></svg>", "caption": "A pin is a decision you renew, not one you make once."}
```

### A routine that holds

1. **Audit on every change**, so a new advisory surfaces within a day of being published, in the
   change that happens to be in front of somebody. Lesson 19 adds it to the project's checks.
2. **Update one dependency at a time** when you can. If the tests fail after one change, you know
   which package did it.
3. **Read the changelog between your version and the new one.** A patch release (`3.1.4` to
   `3.1.6`) should fix things and break nothing; a major release (`2.x` to `3.0`) is allowed to
   break things on purpose, and its notes say what.
4. **Run the tests.** The tests written in every lesson of this course are what make an update
   safe to take: if escaping, validation or a refusal stopped working after an update, a test
   says so before a patient does.
5. **Commit the new pin with a message that names the advisory.** In a year, `Raise jinja2 to
   3.1.6 for PYSEC-2026-1471` explains itself; `update deps` does not.

### Letting a bot open the change

Services such as GitHub's Dependabot and Renovate watch a repository's pins and open a pull
request when a new version or an advisory appears. That turns step 1 into a notification and
steps 2 to 5 into reviewing a small, single-purpose change. Neither was run for this course; both
are configured with a short file in the repository, and both depend on the tests to tell a safe
update from a breaking one.

### When there is no fixed version

Sometimes the advisory has no fix yet, or the package is no longer maintained. The choices then
are the ones from the first section: check whether the application uses the affected part, put a
compensating control in front of it, replace the dependency, or accept the risk for a stated
period. Each is legitimate; **the one that is not is forgetting.** Write the decision down beside
the pin, with a date to come back to it.
