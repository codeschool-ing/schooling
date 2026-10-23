---
title: Left of what
version: 1
---

"Shift left" is said in every DevSecOps meeting. Half the time it means something nobody would
agree to if it were said plainly: **the security team's work, handed to developers, with no time
added for it.** That is not what the phrase was coined for, and a team that hears it that way
learns to resent every check this course adds.

The left is a place on a drawing. Lay a change's life out from left to right, from the moment
somebody decides what to build to the moment it runs for users, and every check sits somewhere on
that line. **To shift left is to move a check to an earlier point, so its answer arrives while the
person who can act on it is still working on the change.** Nothing in that sentence says who does
the work, and nothing says every check should move.

### Where the phrase comes from

Larry Smith named it in 2001, in an article in *Dr. Dobb's Journal* called "Shift-Left Testing".
His subject was testing, not security: testers joining a project at the end found defects the
developers could no longer fix cheaply, so he argued for testing as early as the code allowed. The
security version arrived with the DevSecOps vocabulary of the 2010s, and it carries the same claim. A finding is worth more the sooner it reaches the person who made the change.

### The line, with the places on it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" data-fig=\"sp-l02-line\" aria-label=\"A change's life drawn from left to right, with the six places a check can run and the time a person waits at each: the editor, under a second, reading one file; the pre-commit hook, a few seconds, reading the staged lines; every push, about ten minutes, reading the whole commit; after the merge to main, about as long as a push, reading the merged commit; the nightly run, an hour or more, reading main rebuilt; production, which never ends, reading what is running. Shifting left moves a check towards the editor; it can only move as far left as the thing it reads.\"><defs><marker id=\"sp-l02-line-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"12\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the wait</text><rect x=\"12\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"66.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">editor</text><text x=\"66.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">under a second</text><text x=\"66.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one file</text><rect x=\"128\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"182.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pre-commit</text><text x=\"182.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a few seconds</text><text x=\"182.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the staged lines</text><rect x=\"244\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"298.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">every push</text><text x=\"298.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">about 10 minutes</text><text x=\"298.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the whole commit</text><rect x=\"360\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"414.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"414.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">like a push</text><text x=\"414.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the merged commit</text><rect x=\"476\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nightly</text><text x=\"530.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an hour or more</text><text x=\"530.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main, rebuilt</text><rect x=\"592\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">production</text><text x=\"646.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">never ends</text><text x=\"646.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">what is running</text><text x=\"12\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">what it reads</text><path d=\"M700 150 L20 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-line-ah-phosphor)\"></path><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">shift left: earlier, while the author still has the context</text></svg>", "caption": "Every place on the line has a budget and something it can read. A check moves left only as far as the thing it reads exists."}
```

Each place answers a different question, and what can be asked depends on what exists by then.
In the editor there is one file. At a commit there is a set of changes. On a push there is a whole
commit that can be built. After the merge there is an artefact that will ship. In production there
is a running service and an internet that keeps publishing advisories about what it runs. **A
check can only move as far left as the thing it reads.** A scan of the built image cannot run in
the editor, because there is no image yet.

### Three ways the phrase is misused

**Moving the work instead of the feedback.** The security team's backlog of findings is assigned
to the developers, and the scanner that produced it is wired into their pipeline, unchanged and
untuned. The checks have not moved earlier in anybody's change; the queue has moved to a different
desk. The test is simple: a check that has shifted left reports on the change in front of you,
and a check that has been dumped reports on everything anybody ever wrote.

**Moving every check, whatever it costs.** A dynamic scan that takes twenty minutes is put on every
push because earlier is better. The pipeline goes from four minutes to twenty-five, developers
batch their changes to push less often, and the batches are bigger and harder to review. Earlier
was supposed to make findings cheaper; this made every change slower, and lesson 1 already named
the end of that road, a check marked "allowed to fail".

**Moving left and leaving the right empty.** Code that has not changed for a year can become
vulnerable this morning, because an advisory was published about a library it uses. No check on
the left can see that: the change it would run on does not exist. The checks that watch what is
already running are the right-hand end of the same line, and **"shift left" never meant taking
them away**. Some people say "shift everywhere" to make the point; the drawing makes it without a
slogan.

### What this lesson does with it

The rest of the lesson turns the drawing into decisions for linkbox. The next section is about the
number used to justify all of this, and how much of it survives a look at its source. Then each
place gets a time budget, and the pipeline gets a second list, `ci/nightly`, for what does not fit
the budget of a push. **The aim is a push that answers in minutes, and checks that are not lost
because they are slow.**
