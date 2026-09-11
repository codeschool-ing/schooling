---
title: Three sizes of responsibility
version: 1
---

*The cloud* is not a technology. It is somebody else's machines, rented by the hour, with an
interface that lets you ask for another one without speaking to anybody.

That last part is the whole innovation. Buying a server used to be a purchase and a delivery; now
it is a call that returns in ninety seconds, and it can be undone just as quickly. Everything else
in this reading follows from that one change.

## The three layers, by what remains yours

The categories have unhelpful names, so read them as a line with your responsibility shrinking
along it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three layers with responsibility shrinking: with infrastructure the operating system, the runtime and the application are yours; with a platform only the application is; with functions only one piece of code is, and nothing runs between calls.\"> <text x=\"128\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">infrastructure</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">platform</text> <text x=\"592\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">functions</text> <rect x=\"20\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your code</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your code</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"592\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one piece of your code</text> <rect x=\"20\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the runtime, yours</text> <rect x=\"252\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the runtime, theirs</text> <rect x=\"484\" y=\"76\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the runtime, theirs</text> <rect x=\"20\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the operating system, yours</text> <rect x=\"252\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">theirs</text> <rect x=\"484\" y=\"118\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">theirs</text> <rect x=\"20\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"128\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the hardware, theirs</text> <rect x=\"252\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">theirs</text> <rect x=\"484\" y=\"160\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">theirs, and idle costs nothing</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the same trade at every step: less control, less work</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and more of your architecture decided by somebody whose interests are not yours</text> </svg>", "caption": "Read the names as positions on one line: how much of the machine remains your problem."}
```

**Infrastructure** — a machine, a disk, a network, by the hour. This is the previous reading with a
button instead of an invoice. The operating system, the updates, the web server and the application
are all yours.

**Platform** — you hand over your code and the provider runs it. It builds it, gives it a runtime,
puts it behind a load balancer, and issues the certificate. You stop choosing an operating system
and stop applying updates; you also stop being able to install whatever you like.

**Functions**, often sold as serverless — you hand over a single piece of code and it is run when
something calls it. There is no machine in your mental model at all: no process that stays up, no
disk you can rely on between calls, and nothing running when nobody is asking.

The trade is the same at every step. Less control, less work, and more of your architecture decided
by somebody whose interests are not identical to yours.

## What renting by the hour actually changes

Two things, and they matter more than the layer you picked.

**Capacity became a decision you can change.** The alternative to guessing how much machine you
need next year is to buy what you need this week and add more on the day you need it. That is why
the model won, and it is the reason a company can survive being on the news.

**Cost became a variable**, which is not automatically an improvement. A fixed monthly server has a
bill you can predict. Hourly pricing has a bill that follows your traffic — and, occasionally, your
mistake. A loop that calls a paid service, a job that fetches a file forty thousand times, a
misconfigured backup: the number that arrives at the end of the month is real, and there is a
well-worn genre of stories about it.

Anybody working this way should set a **budget alarm** before writing any code. Ten minutes, once,
and it converts a catastrophe into a message.

## Where serverless earns its keep, and where it does not

Worth being concrete, because it is the layer most oversold.

It is genuinely good at work that is **occasional and bursty**: a form that submits twice an hour,
an image resized on upload, a scheduled job. Nothing runs between calls, so nothing is paid for
between calls, and ten thousand at once is the provider's problem rather than yours.

It is a poor fit for work that is **constant**, where a small server is cheaper and simpler; for
anything needing to keep state between calls, since there is no reliable place to put it; and for
anything with a long-lived connection, which the model does not have a shape for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Work that is occasional and bursty suits functions, because nothing is paid for between calls. Work that is constant, stateful or long-lived does not, because a small server is cheaper and the model has no shape for it.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">a good fit</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a form that submits twice an hour</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">an image resized on upload</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ten thousand at once, occasionally</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">a poor fit</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">constant load, where a server is cheaper</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">anything that keeps state between calls</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a long-lived connection</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and the cold start, which lands on whoever arrives first</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">on a quiet service, that is every visitor</text> </svg>", "caption": "Nothing runs between calls. That is the whole advantage and the whole limitation."}
```

And it has one property worth knowing by name: the **cold start**. When nothing has run for a
while, the first call waits for a runtime to be created. It is usually a fraction of a second and
occasionally much worse, and it lands on whoever arrives first — which, on a quiet service, is
every visitor.

## The parts you rent instead of running

The part of this that changes daily work most is not the compute. It is that everything a server
used to have inside it can be rented separately: a database, object storage, a queue, a cache, a
mail sender.

A managed database is the clearest case. Somebody else takes the backups, applies the updates, and
keeps a second copy ready. It costs several times what the same database costs on your own machine,
and the honest way to compare is against the hours you would spend on those three things — and
against the cost of discovering, during an incident, that you had done none of them.

## Lock-in, told straight

The word gets used as an accusation, and the reality is a spectrum worth being clear-eyed about.

A machine running your own software is portable: the same configuration builds the same thing at
another provider in an afternoon. A managed database is portable with effort — the data comes out,
and the surrounding arrangements have to be rebuilt. A platform's build system, a provider's
functions, and their queues and identity services are the ones that become the architecture, and
moving means rewriting.

None of that is a reason to refuse the convenient thing. It is a reason to know, for each piece you
adopt, roughly what it would cost to leave — and to spend the deepest commitments on the parts you
are most confident about.
