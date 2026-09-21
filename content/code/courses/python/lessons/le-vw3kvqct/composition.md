---
title: Holding one, rather than being one
version: 1
---

```python
class Notifier:
    def __init__(self, transport):
        self.transport = transport      # it HAS one

    def notify(self, message):
        self.transport.deliver(format(message))
```

Composition is an object holding another object and calling it. No inheritance, no base class,
and no shared machinery either of them has to agree about.

## The question that decides

**Is this a KIND of that, or does it HAVE one?**

A `Student` is a `Person` — inheritance. A `Notifier` has a transport — composition. Said out
loud, the answer is usually obvious, and the reason people reach for inheritance anyway is that
it is taught first and it looks like reuse.

## What goes wrong with the wrong one

The requirement that arrives is never "another kind". It is "the SMS one should retry, the log
one should not". Retrying is not a kind of notification — it is something that happens around
one. With inheritance it goes in the base class behind a flag, and the base now knows about a
subclass it is not supposed to know about.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"With inheritance the retry rule has nowhere to live but the base class, which then knows about the subclass it is not supposed to know about. With composition the notifier holds a transport, and retrying is a transport that wraps another one.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"176\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">inheritance — it IS a kind of</text> <rect x=\"20\" y=\"36\" width=\"312\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"176\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Notifier, and now the retry flag</text> <rect x=\"20\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"94\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SmsNotifier</text> <rect x=\"184\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"258\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">LogNotifier</text> <path d=\"M94 112 L94 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M258 112 L258 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"176\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the base knows which subclass retries</text> <text x=\"544\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">composition — it HAS one</text> <rect x=\"388\" y=\"36\" width=\"312\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"544\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Notifier</text> <path d=\"M544 82 L544 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"556\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">transport</text> <rect x=\"388\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Retrying(Sms())</text> <rect x=\"552\" y=\"118\" width=\"148\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"626\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Log()</text> <text x=\"544\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">retrying wraps a transport and nothing else changes</text> </svg>", "caption": "The requirement that arrives is never another kind. It is something that happens AROUND one, and only one of these two designs has a place to put it."}
```

With composition it is a `RetryingTransport` that holds another transport and calls it again.
Nothing inherits, and the log notifier gets no retry because nobody wrapped it.

## What it does to a test

To test the e-mail subclass you have to test the base class with it, because they are one object.
To test the composed notifier you hand it a transport that records what it was given — an object
with one method — and the notifier cannot tell the difference. **That is the practical difference,
and it shows up long before the design one does.**

## The cost

Composition is one more object and one more name. `self.transport.deliver(...)` is a word longer
than `self.deliver(...)`, and where a class genuinely IS a specialisation of another, that word
buys nothing.

**Neither is the right default for everything.** What is a default is the QUESTION — kind, or
has — asked before either is written.
