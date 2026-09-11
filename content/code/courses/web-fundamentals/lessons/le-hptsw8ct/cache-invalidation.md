---
title: Undoing a cache you asked for
version: 1
---

You told every browser in the world to keep the stylesheet for a year. It has been six hours and
the stylesheet is wrong.

There is no instruction that reaches into somebody's browser and removes a file. The copy is on
their disk, it is fresh, and until it goes stale their browser will not ask you anything. You have
the same problem as the permanent redirect in the last lesson, for the same reason: **you cannot
serve a correction to somebody who is not asking.**

## The way out is not to invalidate

It is to make the new thing a **different address**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Keeping the same filename means the cache time is a promise that has to be short. Putting a fingerprint of the contents in the filename means a new build is a new address, so the old one can be cached for a year without risk.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">the same name every time</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.css</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a long cache is a promise you may regret</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a short one costs a request every time</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">a fingerprint in the name</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.7f3c2a9.css</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a year is safe: this content is fixed</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a new build is a name nobody has</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nothing is invalidated; the old address is simply no longer mentioned</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is why the page that names them cannot be cached for long</text> </svg>", "caption": "The characters in the middle of a built filename are not decoration. They are what makes a year-long cache safe."}
```

Give every built file a name containing a fingerprint of its contents — `app.7f3c2a9.css` — and two
things become true at once. That address can be cached for a year without risk, because that exact
content will never change. And a new build produces a new name, which no browser has ever seen, so
every browser fetches it immediately.

Nothing is invalidated. The old file simply stops being mentioned, and expires quietly on its own
schedule while nobody waits for it.

This is what every build tool is doing when it produces filenames with a string of characters in
the middle, and it is worth knowing that the string is not decoration: it is what makes the
year-long cache safe.

## Then one file has to stay short-lived

If the names change, something has to tell the browser the new names, and that something cannot
itself be cached for a year.

The page is the entry point. It is small, it changes on every deploy, and it carries the addresses
of everything else. So the arrangement is:

| what | instruction | why |
|---|---|---|
| the HTML page | `no-cache` | always checked; usually answered `304` |
| hashed assets | `max-age=31536000, immutable` | the name guarantees the content |
| images and fonts under their own names | a long `max-age` | they change rarely, and can be renamed |
| an interface's responses | decided per address | some are public and shared, most are `private` |

`immutable` is worth a line: it tells the browser not even to make a conditional request when the
visitor presses reload. Without it, a reload revalidates everything, which is exactly the round
trips you were trying to avoid.

## What you can purge, and what you cannot

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A CDN and a cache inside your own network can be emptied on demand. A visitor's browser cache cannot be reached at all.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">yours to empty</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the CDN — a purge, seconds to minutes</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cache inside your own network</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">not yours at all</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">every visitor's browser</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a proxy at somebody's employer</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">generous at the edge, precise in the browser</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a mistake on the left is a button; a mistake on the right is a wait you cannot shorten</text> </svg>", "caption": "The asymmetry decides the whole policy: one side has an undo and the other does not."}
```

A CDN is a cache you have an account with, so you can empty it: every provider has a purge, and it
takes seconds to minutes. The same is true of a cache inside your own network.

A visitor's browser is not yours, and there is no purge. Whatever you promised, you promised.

That is the whole asymmetry, and it decides how to be careful: **be generous with cache times at
the edge, and precise with them in the browser.** A mistake at the edge is a button. A mistake in a
browser is a number of visitors you cannot count, holding a file you cannot reach, for as long as
you told them to.

## The cache your own code controls

There is one more, and it deserves naming because its failures are memorable.

A **service worker** is a piece of your own code that the browser runs between the page and the
network, and it can serve requests from a store it manages. It is what makes a site work offline
and what makes some sites open instantly.

It is also a cache with your bugs in it. The classic failure is a service worker that caches the
page and itself, incorrectly, so that a visitor who loaded the broken version is served the broken
version for ever — by code you wrote, running in their browser, that no longer asks you anything.
Sites have needed to ship a deliberate self-uninstalling version to recover.

The rule for now is to know what it is when you see one in the panel, and to treat adding one as a
decision rather than a checkbox.

## Why this bug never reproduces

The last thing, and it is the reason cache problems take so long to fix.

The person debugging it is the person who has been reloading the site all day, often with the cache
disabled in the developer tools. Their browser holds nothing old. The people affected are the ones
who visited a week ago and have not been back since, and there is no way to become one of them
except by clearing everything and waiting.

So the useful habit is to check the headers rather than the behaviour: ask what instruction the
server actually sent, read it, and decide whether it is what you meant. The answer is in the
response, and it is the same for everybody — which is more than can be said for the symptom.
