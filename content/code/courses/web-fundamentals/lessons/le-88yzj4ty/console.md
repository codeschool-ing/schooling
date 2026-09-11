---
title: What the page is saying
version: 1
---

The console is two things at once: a place where the browser reports problems, and a place where
you can type a line and have it run against the page in front of you.

Both halves are useful before you write any code of your own.

## Reading what is already there

Open it on any site and there is usually something. Learning to tell the four kinds apart is most
of the value.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four kinds of console line: an error that stopped something, a warning the browser disapproved of, a log the page printed itself, and a network failure.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">an error</text> <text x=\"290\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">something threw, and what it was doing stopped</text> <rect x=\"20\" y=\"84\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a warning</text> <text x=\"290\" y=\"105\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">disapproved of, and done anyway — tomorrow's error</text> <rect x=\"20\" y=\"134\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">a log</text> <text x=\"290\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the page's own code, printing on purpose</text> <rect x=\"20\" y=\"184\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a network failure</text> <text x=\"290\" y=\"205\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">blocked, refused, or unhandled — also in the network panel</text> </svg>", "caption": "Four kinds, and telling them apart is most of the value. A red line and a button that does nothing are usually one fact."}
```

**An error** — something threw and nothing caught it. Whatever was happening at that moment stopped
happening. If a button does nothing and there is a red line here, those two facts are very likely
the same fact.

**A warning** — something the browser disapproves of and did anyway. A deprecated feature, a cookie
that will stop being sent when a browser policy changes, an image whose declared type does not
match its contents. These are tomorrow's errors and they are worth reading once.

**A log** — something the page's own code chose to print. On a site you did not build, this is
occasionally more revealing than anybody intended.

**A network failure** — a request that did not arrive, reported here as well as in the network
panel. A blocked request, a refused connection, a failure that a script did not handle.

## Reading an error properly

An error has three parts and people read one of them.

The **message** says what went wrong, in the browser's words. The **file and line** say where. And
the **stack** — usually collapsed — says how it got there: which function called which, most recent
first.

The stack is the half that answers *why was that code running at all?*, which is frequently the
real question. Expanding it once, on a real error, is the moment this panel stops being a wall of
red.

There is one common source of confusion worth naming. A file that has been minified reports line
1, column 40000, which is useless. The answer is a **source map**, a file that maps the built code
back to what was written, which the browser loads automatically when it is published beside the
script. If your errors are unreadable, this is the thing that is missing.

## Typing into it

The second half, and it is a genuinely good way to learn.

Anything you type is evaluated against the current page. `document.title` prints the title.
`document.querySelectorAll('img').length` counts the images. `document.cookie` shows the cookies a
script is allowed to see — which, after lesson seven, you can predict will be missing the important
one.

Two conveniences worth knowing. `$0` is whatever element is selected in the elements panel, so
inspecting something and then typing `$0` is the fastest way to get hold of it. And a bare
expression prints its value, so you rarely need to wrap anything in a print.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three lines typed into the console and what each prints: the page title, the number of images, and the cookies a script is allowed to see.\"> <rect x=\"20\" y=\"34\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document.title</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the title of this page</text> <rect x=\"20\" y=\"82\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$$('img').length</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">how many images it has</text> <rect x=\"20\" y=\"130\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">document.cookie</text> <rect x=\"380\" y=\"130\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and not the HttpOnly one</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">`$0` is whatever is selected in the elements panel, which saves a great deal of typing</text> </svg>", "caption": "A line at a time, against the page in front of you, with nothing saved. It is the cheapest place to experiment."}
```

This is also where a great deal of experimenting belongs. A selector you are unsure about, a piece
of arithmetic, a check of what a value actually contains — all of it is faster here than in a file,
and none of it is saved, which is the same safety the elements panel has.

## The warning that is not about your code

One thing to be prepared for, because it is startling the first time.

Many large sites print a warning in the console telling you not to paste anything into it. It is
there because a real attack works like this: somebody is persuaded, over the phone or in a message,
to paste a line into the console of a site they are signed in to, and the line sends their session
elsewhere.

It is worth taking seriously in both directions. Nothing in this course asks you to paste something
you do not understand into a console on a site that matters, and if somebody asks you to, that is
the attack.

## Two other tabs people confuse with this one

Worth separating, because all three print things and only one of them is the console.

The **sources** panel holds the files as the browser received them, and lets you stop the code on a
chosen line and look at every value at that moment. It is the tool for *why is this variable
wrong*, where the console is the tool for *did anything go wrong at all*.

The **performance** panel records what the page spent its time on: the layout, the paint and the
script execution of lesson ten, as a chart with durations. It is where the answer lives when the
network panel is idle and the page still stutters.

Neither replaces the console, and the console does not replace either. The sequence that works is
console first, because it is the cheapest, and then whichever of the two the console pointed at.

## What it is not

The console reports what the browser noticed. It does not report what your server did, and an empty
console is not evidence that anything worked.

The form of lesson six that returns `200` with an error in the body produces a perfectly clean
console, because nothing failed as far as the browser is concerned. That case is found in the
network panel, and the next reading is about reading it.

*No errors* is information. It is the information that nothing threw, and nothing more.
