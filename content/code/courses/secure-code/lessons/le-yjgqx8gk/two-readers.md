---
title: Two readers for every failure
version: 1
---

When something breaks, two different people need to hear about it, and they need different
things. **The person who sent the request needs to know that it failed and what to do next. The
team needs to know exactly why.** The commonest mistake is to give both readers the same text,
which means either the team gets too little or the stranger gets too much.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-two\" aria-label=\"One failure, written for two readers. On the left, the error page, read by whoever sent the request, which may be anybody: it says that something went wrong on the portal's side and gives a short reference. On the right, the log, read only by the team: it carries the same reference, the time, the path that failed and the full traceback. The reference is the only thing both share, and it is what lets the team find the failure a patient reports.\"><defs><marker id=\"l15-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the error page</text><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">read by whoever sent the request</text><rect x=\"20\" y=\"56\" width=\"300\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">something went wrong on our side</text><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">reference: …</text><text x=\"535\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the log</text><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">read by the team only</text><rect x=\"370\" y=\"56\" width=\"330\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ref=…  path='/patients/…'</text><text x=\"386\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Traceback (most recent call last):</text><text x=\"386\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">  … KeyError: 'marta'</text><path d=\"M170 166 L170 200 L535 200 L535 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-two-ah-paper-dim)\" marker-start=\"url(#l15-two-ah-paper-dim)\"></path><text x=\"352\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the reference joins the two</text></svg>", "caption": "The page tells the person what happened; the log tells the team why. Only the reference appears in both."}
```

### The error page is public

Whoever sends a request reads its answer, and that may be a patient, a script or somebody mapping
the portal from outside. An error page that carries a traceback, an SQL statement, a file path or a
library version tells all of them how the application is built. Each fact is small. Together they
save somebody hours of guessing, which is time a defender would rather they spent.

So the page says what happened in words a patient can act on, and gives a **reference**: a short
random code that means nothing outside, and that the team can search for.

### The log is private, and still not a safe

The log is where the detail belongs: the reference, the time, the path, the traceback, the
identifiers needed to find the record that broke. **It is read by fewer people than the page, and by
more people than anybody remembers**: everybody with access to the log service, its backups, and
whatever a log line is copied into when somebody pastes it into a ticket. Lesson 16 listed a log
line among the places a secret leaks from. So the log carries what the team needs to fix things, and
nothing it would be harmful to read.

### Both are written on purpose

Neither the page nor the log line should be whatever the framework produces by default. Flask's own
500 page is a good default, saying *Internal Server Error* and nothing else; the trouble starts when
somebody replaces it with something more helpful to themselves, which is exactly what happened in the
portal, and the next section shows.
