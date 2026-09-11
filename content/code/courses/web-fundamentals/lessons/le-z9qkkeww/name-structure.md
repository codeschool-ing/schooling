---
title: Reading a name from the right
version: 1
---

`app.codeschool.ing` looks like it should be read the way you read a sentence. It is the other way
round: the part that matters most is at the end, and each dot is a step down into something the
part on its right delegated.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The name staging.api.codeschool.ing read from the right: the invisible root, then the top level domain ing, then the registered domain codeschool, then two subdomains. Each level delegates to the one on its left.\"> <text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">read it from the right, because that is the order it is answered in</text> <rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">staging</text> <rect x=\"182\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"257\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">api</text> <rect x=\"344\" y=\"40\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"434\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">codeschool</text> <rect x=\"536\" y=\"40\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"588\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ing</text> <rect x=\"652\" y=\"40\" width=\"48\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"676\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">.</text> <text x=\"676\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the root</text> <text x=\"588\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the TLD</text> <text x=\"434\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">what you register</text> <text x=\"257\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">yours to invent</text> <text x=\"95\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and so is this</text> <rect x=\"20\" y=\"140\" width=\"680\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the root knows who runs ing, and nothing else</text> <text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">whoever runs ing knows which servers answer for codeschool</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">those servers know everything to the left of it</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nobody holds the whole list, and nobody ever has</text> </svg>", "caption": "Each dot is a delegation. Every level knows one thing: who to ask next."}
```

## The parts

At the far right, after a dot nobody types, is the **root**. It is real, it is written as an empty
label, and the only reason you never see it is that software adds it for you.

Then the **top-level domain**: `ing`, `com`, `br`, `org`. There are more than a thousand, and they
come in recognisable kinds — the original handful, the two-letter ones belonging to countries, and
the several hundred newer ones that are words. Each is run by an organisation that decides what
goes underneath it.

Then the **domain** you register: `codeschool`. This is the part somebody paid for, and the pair
`codeschool.ing` is what the next reading is about.

And to the left of that, **subdomains**: `app`, `www`, `api`, `mail`, and anything else you like,
including several dots' worth — `staging.api.codeschool.ing` is perfectly ordinary. These cost
nothing and are yours to invent, which is the single most useful fact in this reading.

## Delegation is the whole design

Each level hands responsibility to the level below it, and stops caring.

The root does not know `codeschool.ing` exists. It knows who runs `ing`, and that is all it has
ever known. Whoever runs `ing` does not know what is inside `codeschool.ing`; they know which
servers were named as answering for it. And those servers know the subdomains, because that is
where the people who own the domain put them.

This is what the opening video meant by a database with no centre. There is no list. There is a
chain of *ask that one instead*, and every step of it is somebody else's responsibility, which is
why the system has kept working through thirty years of growth that nobody planned for.

## `www` is a subdomain like any other

Worth stating plainly, because it causes real confusion: `www` is not special. It is a subdomain
somebody created, by convention, in an era when a company's machines were named by what they did —
`www` for the web server, `ftp` for file transfer, `mail` for the mail server.

So `example.com` and `www.example.com` are two different names, and a site has to decide which one
is the real one and send the other there. Which one you pick barely matters; picking neither is
what produces two copies of a site, two sets of cookies, and search engines treating them as
separate places.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A site that answers on both the bare domain and the www name without redirecting produces two copies: two sets of cookies, two entries in search results and two places to keep correct.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">both answer, neither redirects</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com and www.example.com</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">two sets of cookies, two sessions</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">two entries in a search result</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">one is canonical, the other redirects</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">one name, and a 301 from the other</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">one set of cookies, one session</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">one place to keep correct</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">which of the two you choose matters very little</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">choosing neither is what costs, and it costs in three places at once</text> </svg>", "caption": "They are two different names. Software treats them as two different sites, because they are."}
```

The choice has a small practical edge worth knowing. A name with nothing to its left — a **bare
domain** — has a restriction you will meet in the records reading: it cannot be pointed at another
name in the ordinary way, only at an address. Providers have worked around this with extensions of
their own, and it is the reason some hosting documentation quietly insists on `www`.

## Rules about the characters

Short, and each one saves an argument.

Labels — the parts between dots — are up to 63 characters, and the whole name up to 255. Letters,
digits and hyphens; no hyphen at the start or end. Case is ignored entirely: `CodeSchool.ing` and
`codeschool.ing` are the same name, always.

Names in other alphabets exist and work — `café.fr`, names in Arabic, in Chinese — and they are
carried by a translation into the restricted alphabet that happens inside the resolver, producing
the odd-looking names beginning `xn--` that you may have seen in a log.

That mechanism has a security consequence worth one line: some characters in one alphabet look
exactly like characters in another, so a name can be registered that is visually identical to a
famous one. Browsers defend against it by showing the translated form when a name mixes alphabets
suspiciously, and it is the reason a legitimate site occasionally displays as `xn--` gibberish.

## Where the boundary of ownership really is

One subtlety, because it decides something you met in the last lesson.

A browser has to know where one owner's territory ends, so that a page on `shop.example.com` cannot
set a cookie for `example.com` if those belong to different people. For most names the rule looks
obvious — one label to the left of the TLD is the registered domain — and for a great many it is
wrong.

`example.co.uk` is a registration; `co.uk` is not something anybody owns. `yourname.github.io` is a
registration of a sort; `github.io` hands out names to strangers, and a cookie set for it would
reach every one of them.

So browsers ship a published list of these boundaries — the **public suffix list** — maintained in
the open and updated as new arrangements appear. It is what stops a cookie being set for `.com`,
and it is why a provider handing out subdomains to customers asks to be added to it.

Two things follow. The rule for *what counts as one site* is a list rather than an algorithm. And
if you ever hand subdomains to people who are not you, the list is something you have to be on.

## What this buys you, today

Two things to carry into the rest of the lesson.

**One purchase, unlimited names.** Buying `codeschool.ing` means every name under it is yours to
create, free, immediately, with no third party involved. A new environment, a new service, a
customer-specific address — all of them are a line in a file you already control.

**Nothing about a name says where it points.** `app.codeschool.ing` and `www.codeschool.ing` can be
on different continents at different providers, and the name gives no hint of it. A name is a
question, and the next readings are about who answers.
