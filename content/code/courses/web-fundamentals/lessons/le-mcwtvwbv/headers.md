---
title: The lines in between
version: 1
---

Between the start line and the blank line sits a list of `Name: value` pairs. They are where
almost everything interesting about a request actually lives, and there are only a few you need to
recognise at this stage.

## `Content-Type`, which decides what the thing *is*

A response is a pile of bytes. `Content-Type` is the only thing that says what they mean.

```
Content-Type: text/html; charset=utf-8
```

Two parts. The type — `text/html`, `application/json`, `image/png` — and often a parameter, here
the character encoding.

Get it wrong and nothing else can save you.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The same bytes sent twice with different content types. Declared as HTML they are drawn as a heading; declared as plain text the tags are shown as characters.\"> <rect x=\"20\" y=\"26\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">the bytes on the wire: &lt;h1&gt;Preço&lt;/h1&gt;</text> <rect x=\"20\" y=\"84\" width=\"330\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Content-Type: text/html</text> <text x=\"185\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-weight=\"600\" font-size=\"22\" fill=\"var(--paper)\">Preço</text> <text x=\"185\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">drawn as a heading</text> <rect x=\"370\" y=\"84\" width=\"330\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Content-Type: text/plain</text> <text x=\"535\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&lt;h1&gt;Preço&lt;/h1&gt;</text> <text x=\"535\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shown as the characters they are</text> <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the browser did what it was told both times; only one of the two labels was right</text> </svg>", "caption": "Nothing in the bytes says what they are. One header does, and everything downstream believes it."}
```

The same bytes, labelled `text/html`, become a heading; labelled `text/plain`, they are shown as
the characters they are. Neither is a failure of the browser: it did what it was told, and what it
was told was wrong.

The `charset` half misbehaves more quietly. Declare `utf-8` and send something else and the accented
characters become a scattering of question marks and boxes — the defect that appears only in
languages the person who built it does not speak, which is why it survives so long in so many
systems.

Two rules follow, and they are short. **Say what it is, every time.** And when you are producing
text in any language that has accents, **say `utf-8`**.

## `Content-Length`, and its two failure modes

The size of the body in bytes, which is how the far end knows where a response ends.

It is counted in **bytes, not characters**, and in a language with accented letters those are not
the same number. A string of twelve visible characters can be fourteen bytes, and a length
calculated by counting characters is a response the receiver will wait forever for the end of.

The other failure is subtler: a length larger than reality leaves a connection hanging, and a
length smaller than reality leaves trailing bytes to be read as the start of whatever comes next.
Both are the kind of defect that behaves differently depending on whether a proxy is in the way,
which makes them memorable to debug.

## `Host`, which turned one machine into many

Mentioned already and worth stating once more plainly: `Host` names the site. The address found the
machine; this header picks which of the hundreds of sites on it you meant.

Without it, a server could host one site per address. With it, a small machine answers for a
thousand names, and did so from the day HTTP/1.1 required it.

## `User-Agent`, which is mostly fiction

Every browser sends a line describing itself. Here is a real one, taken apart.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A real user agent string taken apart line by line. Four of its six fragments are claims to be other browsers, accumulated over decades. Two are true: the system underneath and the browser actually asking.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one real string, one fragment per row</text> <rect x=\"20\" y=\"32\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Mozilla/5.0</text> <text x=\"256\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a browser discontinued in 2008</text> <rect x=\"20\" y=\"74\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">(X11; Linux x86_64)</text> <text x=\"256\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">true — the system underneath</text> <rect x=\"20\" y=\"116\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AppleWebKit/537.36</text> <text x=\"256\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the engine Safari uses, which this is not</text> <rect x=\"20\" y=\"158\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">(KHTML, like Gecko)</text> <text x=\"256\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">two more engines, neither of them this one</text> <rect x=\"20\" y=\"200\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Chrome/140.0.0.0</text> <text x=\"256\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">true — the browser actually asking</text> <rect x=\"20\" y=\"242\" width=\"220\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Safari/537.36</text> <text x=\"256\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Safari again, in case once was not enough</text> </svg>", "caption": "Every claim in here was added because some site once refused to serve a browser it did not recognise."}
```

Two fragments of that are true. The rest is a chain of claims to be other browsers, accumulated over
thirty years for one reason: sites checked the string and refused to serve anything they did not
recognise. So each new browser claimed to be the ones before it, every time, until the string became
an archaeological record of which browsers were once worth pretending to be.

Two practical conclusions. **Do not decide what to send based on this string** — that is the habit
that created the mess, and the modern answer is to ask what the browser can do rather than what it
is called. And when you see a strange one in a log, remember that anybody can send anything here;
it is a claim, not a measurement.

## Request, response, and the ones that go both ways

Some headers make sense in only one direction. `Accept` is a request asking for a format;
`Content-Type` describes a body, so it appears on a response and on any request that has one.
`Date` appears on both. `Server` and `Set-Cookie` are a response's alone.

Three mechanical details that save an afternoon each.

**Names ignore case.** `content-type` and `Content-Type` are the same header, and different software
capitalises differently.

**A header can appear more than once**, and for most of them that is the same as one header with
the values separated by commas. `Set-Cookie` is the famous exception, which is part of why cookies
are awkward to handle.

**Values are text, and text has limits.** Servers cap the total size of the headers — often around
eight kilobytes — and exceeding it gets a response about a header being too large rather than
anything about what you were trying to do. It is almost always a cookie that grew.

## Your own headers

You can invent one. `X-Request-Id` and friends are ordinary text that anything not expecting them
ignores.

The convention used to be that a private header started with `X-`, and that convention was
withdrawn, because too many `X-` headers became standard and then had to keep a prefix that said
they were not. Pick a name that will not collide and use it without the prefix.
