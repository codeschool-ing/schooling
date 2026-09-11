---
title: Which word, and what it promises
version: 1
---

The first word of a request says what to do. There are a handful in common use, and the difference
between them is not really about what the server does — a server can do whatever it likes — but
about what everybody else is entitled to assume.

## The words

| method | asks for | usually carries a body |
|---|---|---|
| `GET` | a copy of something | no |
| `HEAD` | the headers a `GET` would give, with no body | no |
| `POST` | this, processed — submit, create, trigger | yes |
| `PUT` | this thing put at this address, replacing what was there | yes |
| `PATCH` | this part of the thing changed | yes |
| `DELETE` | the thing at this address removed | rarely |
| `OPTIONS` | what is allowed here | no |

Two of those are worth a sentence before the rest. `HEAD` gives the headers alone: it is how you
ask *has this changed?* or *how big is it?* without moving the file. `OPTIONS` asks what a server
will permit, and you will meet it again as the question a browser asks before it lets one site call
another.

## Safe, and idempotent

Those two words are how the difference is actually described, and they are not synonyms.

**Safe** means the request is not meant to change anything. `GET` and `HEAD` are safe. Anything
that is not asking to change the world can be done freely by anybody: a browser may fetch a link
before you click it, a proxy may keep the answer, a crawler may visit everything it finds.

**Idempotent** means doing it twice leaves the world as it was after doing it once. `PUT` is
idempotent — set the price to ten, set it again to ten, the price is ten. `DELETE` is idempotent;
the thing is gone either way. `POST` is not, and neither is `PATCH` in general: add one to the
count, twice, and the count is two higher.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A square divided into four. Safe and idempotent holds GET, HEAD and OPTIONS. Idempotent but not safe holds PUT and DELETE. Neither holds POST and PATCH. The remaining corner, safe but not idempotent, is empty because it cannot exist.\"> <text x=\"230\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">idempotent — twice is the same as once</text> <text x=\"580\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">not idempotent</text> <rect x=\"60\" y=\"36\" width=\"340\" height=\"108\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"230\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">GET HEAD OPTIONS</text> <text x=\"230\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">fetch it early, keep a copy, follow it</text> <text x=\"230\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">without asking anybody</text> <rect x=\"410\" y=\"36\" width=\"250\" height=\"108\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect> <text x=\"535\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">empty, and it has to be</text> <text x=\"535\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">changing nothing changes nothing twice</text> <rect x=\"60\" y=\"156\" width=\"340\" height=\"108\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">PUT DELETE</text> <text x=\"230\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">changes things, and a repeat is harmless</text> <text x=\"230\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">so a lost answer can be retried</text> <rect x=\"410\" y=\"156\" width=\"250\" height=\"108\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"535\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">POST PATCH</text> <text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a repeat does it again</text> <text x=\"535\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and that is the hard case</text> <text x=\"30\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">safe</text> <text x=\"30\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">not</text> <text x=\"360\" y=\"288\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the bottom left is the quadrant people forget, and it is where retries become possible</text> </svg>", "caption": "Safe is about whether it changes anything. Idempotent is about whether doing it twice matters."}
```

Every safe method is idempotent, because a request that changes nothing changes nothing twice. The
reverse does not hold, and the interesting quadrant is the one with `PUT` and `DELETE` in it.

## Why the distinction has teeth

It decides what happens when something goes wrong, which is the only time anybody finds out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A request is sent and no answer comes back. Two possibilities are drawn: the request never arrived, or it was carried out and the answer was lost. From the client both look identical.\"> <rect x=\"20\" y=\"34\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"90\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">you send it</text> <text x=\"200\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and nothing comes back, which can mean either of these</text> <rect x=\"200\" y=\"40\" width=\"500\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">it never arrived, and nothing happened</text> <text x=\"450\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">or it arrived, was carried out, and the answer was lost</text> <text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">from where you are standing, the two are the same picture</text> <rect x=\"20\" y=\"158\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PUT, DELETE, GET</text> <text x=\"185\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">send it again; a second time costs nothing</text> <rect x=\"370\" y=\"158\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">POST</text> <text x=\"535\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">retry and it may be paid twice; do not, and it may be unpaid</text> </svg>", "caption": "The choice of method is a decision about what happens on the day an answer goes missing."}
```

A request is sent and no answer comes back. That is all the client knows. The request may have
been lost on the way out, or it may have been carried out perfectly and the answer lost on the way
back — and from where you are standing those two look identical.

If the method was idempotent, there is nothing to decide: send it again. At worst it is done for a
second time, and being done twice is what idempotent means you can survive.

If it was a `POST`, you are stuck with a real choice. Send it again and the payment may go through
twice. Do not send it, and it may not have gone through at all. That dilemma is why every checkout
page asks you not to press the button twice, and why serious systems attach an identifier to the
attempt so the server can recognise a repeat.

## The promise is not enforced

Nothing stops a server from deleting a record when it receives a `GET`. The protocol describes what
the word is *supposed* to mean; it does not police it.

Which sounds harmless until you notice who is relying on the promise. A crawler follows links —
all of them, without asking — because links are `GET`s and `GET`s are safe. A browser fetches a
page before you have clicked it, for the same reason. A proxy keeps a copy.

So an administration page whose delete buttons were ordinary links is a page where something will
eventually visit every one of them. This is not a cautionary tale invented for a lesson: it has
happened to real applications, more than once, and the first sign was a database emptying itself
overnight with no human logged in.

The rule that follows is short. **If it changes something, it is not a `GET`.**

## Choosing, in practice

Most days the decision is small. Fetching anything at all is a `GET`. A form that creates something
is a `POST`. Replacing a whole record at a known address is a `PUT`; changing one field of it is a
`PATCH`; removing it is a `DELETE`.

Where teams argue is the edge: is marking an order as shipped a `PATCH` on the order, or a `POST`
to something that represents the shipping? Both are defensible, and the question worth asking is
the one this section began with — what would I like a proxy, a browser and a retry to assume? The
method is a message to software you did not write and will never meet, and that is what you are
choosing when you pick the word.
