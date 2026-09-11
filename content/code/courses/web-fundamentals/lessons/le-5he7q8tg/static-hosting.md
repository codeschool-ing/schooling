---
title: When there is nothing to run
version: 1
---

Every option so far assumed a program running on a machine, waiting to build a page for whoever
asks. An enormous number of sites do not need one.

If the page is the same for everybody, it can be built once, in advance, and served as a file. That
is static hosting, and it is the cheapest, fastest and most reliable arrangement in this lesson —
for the sites it fits.

## What a file server does not have

The list is the reason it is better, so it is worth reading as a set of absences.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"What a static site does not have: no application to crash or exploit, no database to back up, no work per request, and no runtime to keep patched. The file already exists.\"> <rect x=\"20\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">no application to crash or exploit</text> <rect x=\"20\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">no database to back up or to be slow</text> <rect x=\"20\" y=\"134\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">no runtime to keep patched</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"142\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">a file, which already exists</text> <text x=\"540\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">serving it is the thing</text> <text x=\"540\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">computers are best at</text> <text x=\"540\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no work per request at all</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a static site under sudden load costs a little more bandwidth</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is a different relationship with popularity than anything else in this lesson</text> </svg>", "caption": "The advantages are all absences, and absences do not need operating."}
```

There is no application, so there is nothing to crash, nothing to exploit through your code, and no
version of anything to keep patched. There is no database, so there is nothing to back up and no
query to be slow. There is no work per request: the file already exists, and serving it is the
thing computers are best at.

The consequence is that the failure modes of the previous three readings mostly stop applying. A
static site under sudden load does not fall over; it costs slightly more bandwidth. That is a
different relationship with popularity than anything else in this lesson.

## Static does not mean unchanging

The common objection is that a real site has content, and content changes. It does, and the
distinction is about **when** the page is assembled rather than whether it ever changes.

A **generator** takes your content — files, or a database, or an editing interface somebody else
hosts — and produces the pages, once, at build time. Publish an article and the site is rebuilt and
re-uploaded, in seconds. The visitor still receives a file.

This site is built that way, which is why it loads the way it does.

The part that surprises people is how far it stretches. Documentation, marketing sites, blogs,
courses, product catalogues that change daily rather than by the second — all of them can be
produced in advance. A build that takes a minute and runs ten times a day is invisible to everybody
and removes an entire category of operational work.

## And it still does things

A static site is not a site without behaviour. The page is fixed; what the browser does with it is
not.

Search, a comment form, a payment, a login — each of these can be a call from the page to something
else: a service you rent, a function from the previous reading, a small application on a server
somewhere. The site stays a set of files, and the few parts that genuinely need a computer to think
are the only parts that have one.

That arrangement has a name in the industry and several competing acronyms; the shape is what
matters. **The default is a file, and the exceptions are calls.**

## Object storage, which is the same idea underneath

The service that holds files for these sites is usually **object storage**, and it is worth knowing
as a thing in its own right because you will use it for much more than websites.

It stores objects — files with a name and some metadata — in buckets, by the gigabyte, cheaply,
with no machine involved and no practical limit on how much you put in. It is where uploads go,
where backups go, where anything large that is not a database goes.

Two things to know. It is not a disk: there are no folders, despite the slashes in names, and there
is no rename that is not a copy. And it has **permissions**, which are the source of the most
common serious mistake in this part of the industry: a bucket left readable by everybody, holding
things that were not meant to be. Every provider now warns loudly, and it still happens, because
the default that was convenient once became a habit.

## When it does not fit

Four cases, and they are recognisable rather than subtle.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four cases where files alone do not fit: a page that differs per visitor, content that changes faster than a rebuild, a build that outgrows patience, and something that must happen when a request arrives.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the page differs per visitor — a dashboard, a basket, a feed</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the content changes faster than you can rebuild</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the build outgrows the patience for it</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">something must happen on receipt — a payment, an email</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">put as much of a site as possible on the other side of this line</text> </svg>", "caption": "Four recognisable cases. Everything that is not one of them costs nothing to operate."}
```

**The page differs per visitor** — a signed-in dashboard, a basket, a personalised feed. Something
has to assemble that, either on a server or in the browser after a call.

**The content changes faster than you can rebuild.** A build of a minute is fine for a blog and
useless for a price that moves every second.

**The build outgrows the patience.** A generator producing a hundred thousand pages takes time, and
teams do hit this, usually at the worst moment.

**Something must happen on receipt** — a payment, an email, a record written. That is a call to
something else, and the something else is a small piece of one of the earlier readings.

None of these argues against the arrangement. They mark the line, and the useful instinct is to put
as much of a site as possible on the file side of it, because everything on that side costs
nothing to operate.
