---
title: One machine, many sites
version: 1
---

The cheapest way to put a site on the internet is to put it on a machine that is already running
several hundred others. That is shared hosting, and it was the only affordable option for most of
the web's life.

It works because of a header you met in lesson six. One machine, one address, and `Host` deciding
which of the sites on it you asked for — the arrangement that turned one address into as many sites
as anybody wanted.

## What you are given

An account, a folder, and a control panel.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"One machine carrying several hundred sites. Each account has its own folder and its own name, and the processor, the memory and the address are shared between all of them.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">one machine, one address</text> <rect x=\"40\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"115\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">your folder</text> <text x=\"115\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">yourname.com</text> <rect x=\"202\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"277\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a neighbour</text> <text x=\"277\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">someshop.com</text> <rect x=\"364\" y=\"70\" width=\"150\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"439\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a neighbour</text> <text x=\"439\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a-blog.net</text> <rect x=\"526\" y=\"70\" width=\"154\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"603\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and 300 more</text> <text x=\"603\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">all on this address</text> <rect x=\"40\" y=\"134\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">shared: the processor, the memory, the address, the software versions</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the `Host` header from lesson six is what keeps the sites apart</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and nothing keeps a busy neighbour from taking most of the machine</text> </svg>", "caption": "Your own folder and your own name. Everything underneath belongs to everybody."}
```

Inside the folder you put files. The web server is already running, configured by somebody else,
and it serves what is in your folder under your name. A database is provided, usually one, with a
size limit. Mail for your domain is often included. A certificate is issued and renewed for you,
which is why this is still the fastest route from *I bought a domain* to *it is live*.

What you do **not** get is the machine. You cannot install software, choose a version of anything,
change the web server's configuration beyond what the panel exposes, or see what else is running.

## What is actually shared

This is the part worth understanding, because it decides every failure mode.

**The processor and the memory** are shared, so a neighbour under sudden load makes your site slow.
There is no allocation that is yours; there is a machine, and whoever is busiest gets most of it.
This is the noisy neighbour problem, and it is the single most common complaint about shared
hosting.

**The address** is shared. If a neighbour sends spam or serves
malware, the address gets a reputation, and that reputation is attached to your mail and sometimes
to your site.

**The software versions** are shared. When the provider upgrades the language runtime, everybody
upgrades. You will be told, and the date will not be yours to choose.

**The limits are shared too**, which is the one nobody expects. Many panels count things per
account — processes, simultaneous connections, database queries — and a site that becomes popular
does not get slower, it gets **cut off**, with an error page while the machine sits idle.

## How the files get there

Worth a section because it is where shared hosting collides with everything else this course
implies.

The traditional routes are a **file manager in the browser** and **FTP** or its encrypted
successor. Both move files from your machine to the folder, one upload at a time, and both are
perfectly serviceable for a site of ten pages.

Neither is a deployment. There is no record of what changed, no way back to yesterday's version, and
no way for two people to be sure they are looking at the same thing. The site becomes whatever the
last person uploaded, and the only copy of the truth is on the server.

Better panels now offer a route from a repository — a button that pulls from a branch, or a shell
account you can push to. If you are choosing a shared host and you intend to keep working on the
site, that feature is worth more than any of the numbers on the pricing page.

## The variants, named

Three arrangements sit around shared hosting and are sold as if they were different categories.

**Managed hosting for one platform** — most commonly for the content system that runs an enormous
share of the web — is shared hosting with that platform pre-installed, updated for you, and with
the rest locked down. Convenient, and you are now on somebody else's upgrade schedule for the
application as well as the machine.

**Reseller hosting** is one shared account divided into several, so that somebody can sell hosting
to their own clients. The limits above apply, split further.

**Cloud hosting** on a shared provider's pricing page usually means the same product on better
hardware with a different name. It is worth reading what is actually included rather than the
category it is filed under, because in this part of the market the words are marketing and the
limits are the specification.

## What it is genuinely good at

It would be easy to read the above as a warning. It should not be. Shared hosting is the right
answer more often than people building things like to admit.

It is cheap enough to be an afterthought. It requires no knowledge you do not already have after
this course. Somebody else patches the operating system, which is the job most neglected by people
who took it on. And for the enormous number of sites that are a few pages and a form, none of the
limitations above will ever be reached.

The honest summary: if your site is content, and the traffic is human-sized, this is a considered
choice rather than a compromise.

## When to leave

Four signals, and each is about a limit rather than about ambition.

**You need something the panel does not offer** — a language version, a background worker, a
scheduled job, a piece of software.

**You are hitting the account limits** rather than the machine's capacity. The tell is an error at
a consistent number of visitors rather than a gradual slowdown.

**The neighbours are the problem** and the provider will not say who or move you.

**You need to deploy the way the rest of this course implies** — from a repository, repeatably,
with a way back. Panels that expect you to upload files by hand make that possible and unpleasant.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four specific signals that it is time to leave shared hosting: needing something the panel does not offer, hitting account limits rather than capacity, neighbours the provider will not move, and needing to deploy from a repository.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">you need something the panel does not offer</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">you hit an account limit, not the machine's capacity</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the neighbours are the problem and nobody will move you</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">you need to deploy from a repository, repeatably</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">not one of these is *I have outgrown it*, which is the reason people give</text> </svg>", "caption": "Four signals you will recognise. Until one arrives, the attention is better spent elsewhere."}
```

None of those is *I have outgrown this*, which is the reason people usually give. They are specific
and you will recognise them, and until one of them arrives the money and the attention are better
spent on what the site does.
