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
