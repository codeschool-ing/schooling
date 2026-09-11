---
title: When the name is the problem
version: 1
---

*It's always DNS* is a joke with a high hit rate, and the reason is structural: name resolution
happens before everything else, so when it fails the symptom looks like whatever came next failed.
A site that will not load, a mail delivery that bounces, an interface call that times out.

This reading is about telling the difference, quickly, and it is mostly about learning four
answers.

## The four answers, and what each one means

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Four possible answers to a lookup and what each means: the name does not exist, the name exists with no record of that type, something broke on the way, and nothing answered at all.\"> <rect x=\"20\" y=\"32\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NXDOMAIN</text> <text x=\"250\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the name does not exist, and something authoritative said so</text> <text x=\"250\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a typo, a record not created yet, a domain that expired</text> <rect x=\"20\" y=\"92\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NOERROR, empty</text> <text x=\"250\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the name exists and has no record of that type</text> <text x=\"250\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the confusing one: it looks like an answer and holds nothing</text> <rect x=\"20\" y=\"152\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">SERVFAIL</text> <text x=\"250\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">something broke on the way, or an answer was disbelieved</text> <text x=\"250\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the one that fails for some resolvers and not others</text> <rect x=\"20\" y=\"212\" width=\"680\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">a timeout</text> <text x=\"250\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nothing answered at all</text> <text x=\"250\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">usually your own resolver rather than the domain</text> </svg>", "caption": "Reading which of these four came back is most of the diagnosis, and every tool prints it."}
```

**`NXDOMAIN`** — the name does not exist. Somebody who is authoritative for this part of the tree
said so. Typos produce this; so does a record you have not created yet; so does a domain that
expired last week.

**`NOERROR` with nothing in it** — the name exists, and it has no record of the type you asked for.
This is the one that confuses people, because it looks like an answer and contains nothing. It is
what you get asking for `AAAA` on a name with only an `A`, or for an `MX` on a domain that does not
receive mail.

**`SERVFAIL`** — something broke on the way. The authoritative servers were unreachable, or they
answered something the resolver refused to believe. This is the one that fails for some people and
not others, because it depends on which resolver you are using and how strict it is.

**A timeout** — nothing answered at all. Usually your resolver rather than the domain: the network,
the router, or port 53 being blocked somewhere between you and it.

Reading the answer is most of the diagnosis, and the tools all print it.

## Is it DNS at all?

Three questions, in order, and each takes seconds.

**Does the name resolve?** Ask directly with `dig` or `nslookup` or `host`. If you get an address,
DNS has done its job and the problem is somewhere in the rest of this course.

**Does it resolve to the right thing?** An old address is not a DNS failure; it is a cache holding
something you changed, and the previous reading says how long for.

**Does it resolve for other people?** A public resolver you do not normally use is the fastest
second opinion there is. Same answer means the fault is shared; different answers mean you are
looking at caching, at a resolver's own filtering, or at something the previous reading's timers
explain.

## The move that settles most arguments

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Asking a resolver tells you what the world currently believes; asking the authoritative server directly tells you what you published. The difference separates a wrong change from a change that is not live yet.\"> <rect x=\"20\" y=\"34\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ask a resolver</text> <rect x=\"20\" y=\"88\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">what the world currently believes</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dig @ns1.provider.net name</text> <rect x=\"380\" y=\"88\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">what you actually published</text> <rect x=\"20\" y=\"156\" width=\"330\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">right on the right, old on the left:</text> <text x=\"185\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">you are waiting for a TTL</text> <rect x=\"370\" y=\"156\" width=\"330\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">wrong on the right:</text> <text x=\"535\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">no amount of waiting will help</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one command, and it separates the two questions people keep conflating</text> </svg>", "caption": "A cache tells you what is believed. The authoritative server tells you what is true."}
```

A resolver's answer tells you what the world currently believes. The **authoritative server's**
answer tells you what you actually published. Asking it directly skips every cache between you and
the truth.

```
dig @ns1.dnsprovider.net www.example.com
```

The difference between those two answers separates the two questions people keep conflating: *is my
change wrong* and *is my change not live yet*. If the authoritative answer is right and the
resolver's is old, you are waiting for a TTL and there is nothing to fix. If the authoritative
answer is wrong, no amount of waiting will help.

That one command has settled more arguments than any other in this lesson.

## The three faults that account for most of it

**A change made at the wrong provider.** After the `NS` records were pointed somewhere new, the old
control panel still works, still shows your records, and is read by nobody. Everything you do there
appears to succeed. Check which servers are authoritative before editing anything.

**A trailing dot.** In record files, a name ending in a dot is complete, and one without a dot has
the domain appended to it. Write `mail.provider.net` without the dot and you have created a record
pointing at `mail.provider.net.example.com`, which does not exist. It reads correctly in a control
panel, and it is wrong.

**Records that were never copied.** Moving DNS providers moves everything at once, and the usual
casualty is mail, because the `MX` and the `TXT` records live with the old provider and the person
moving was thinking about the website.

## `SERVFAIL`, and the signature that breaks for half the world

Worth a section because the symptom is so distinctive.

There is an extension — `DNSSEC` — that signs DNS answers, so that a resolver can tell whether what
it received is what the domain published. It closes a real attack: without it, an answer is a small
unauthenticated packet that anybody in a position to forge one can replace.

The way it fails is what matters here. When a domain's signatures are wrong — expired, or a key
rotated without the parent being updated — a resolver that **validates** refuses the answer and
returns `SERVFAIL`, while a resolver that does not validate answers happily.

So the site is down for people using one resolver and perfectly fine for people using another, with
no pattern by geography. That is nearly a signature of the fault, and it is the case where the
question *does it work from another resolver?* gives you the diagnosis rather than a second opinion.

## Two red herrings

A file on your own machine — `hosts` — maps names to addresses before DNS is consulted at all. It
is genuinely useful for testing, and it is the reason for the occasional afternoon spent debugging
a name that resolves correctly for everybody except the person investigating. If your machine
disagrees with the world, look there first.

And the browser's own cache holds names for its own reasons, on its own schedule, ignoring your
TTL. A name that is fixed everywhere and wrong in one browser tab is usually this, and restarting
the browser is a faster test than believing it.
