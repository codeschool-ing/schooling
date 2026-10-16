---
title: When a test should switch the cache off
version: 1
---

A test switches the cache off when caching is not what it is about, and leaves it alone when it is.
**Most of the time Playwright has already made that choice for you**, because a new context starts
with an empty cache. What is left is knowing the other ways the cache goes off, so that none of them
happens by accident.

## There is no `--disable-cache` flag

People look for one because the DevTools panel has a checkbox. Playwright 1.56 has no option of that
name, on the command line or in the configuration. The reference that ships with it mentions the
HTTP cache in two places. One is the promise that a new context shares no cache with another. The
other is a note on `page.route` and `context.route`: **enabling routing disables the HTTP cache**.
That gives three ways a test ends up without the cache, and only one of them is usually chosen on
purpose:

| way | what it does | when it is the right tool |
|---|---|---|
| a new context | an empty cache, which is the `page` fixture's default | almost always |
| `page.route` | turns the cache off for that page as a side effect | when you meant to intercept requests anyway |
| a DevTools Protocol session | turns the cache off and nothing else; Chromium only | rarely; see below |

The second row is the dangerous one, because nobody reads it as a cache setting. A test that
intercepts one request to answer it with prepared data, or merely to watch it, also stops the
browser keeping anything for the rest of that page's life. The last test in `tests/cache.spec.js`
is exactly that: the returning customer's steps, with a route that changes nothing, passing.

The third row is the checkbox itself. DevTools talks to Chromium through the DevTools Protocol, and
Playwright can open a session on the same protocol for a page:

```javascript
const cdp = await page.context().newCDPSession(page);
await cdp.send('Network.enable');
await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
```

Run against this lab's Chromium 141 with the returning customer's steps, the second visit reached
the server and showed the new offer. Without the `Network.enable` line it did not, and nothing
complained. Firefox and WebKit do not speak this protocol, so a suite that relies on it has quietly
become a Chromium suite. These three lines are for reading; the project does not need them.

## When to leave it on

**When the customer you are imitating has been here before.** The returning customer, a page opened
twice in one session, a user who comes back through a bookmark: all of them meet the cache, and a
test that turns it off has decided not to look. Two visits in one context, or a kept profile, are
the tools from two sections back.

**When speed is the subject.** A page that loads in one second on a first visit and much faster on
the second is behaving as designed, and measuring only the first visit misses half of it.
`non-functional-testing` lesson 10 is about measuring a page's speed, and the cache belongs there.

## When to switch it off

**When the test is about content, and the cache would only add a question.** The answer here is the
default: one context per test. Turning the cache off inside a test that already has a new context
changes nothing, and it hides the decision in a line nobody connects with it.

**When you are hunting a defect and want to know whether the cache is part of it.** Run the same
steps with the cache on and with it off. If the result differs, the cache is in the story, and the
headers are the next thing to read; the previous section asserted them.

## What a new context does not clear

A new context starts with an empty **browser** cache. A CDN or a proxy between the browser and the
server is not inside the browser, so a test cannot empty it, and a response it keeps reaches every
new context exactly as it reaches a returning customer. When a test passes on your machine and fails
against an environment behind a CDN, or the other way round, that cache is worth asking about;
`manual-testing` lesson 21 is about how environments differ. A page with a service worker keeps
copies of its own as well, and lesson 5 meets one.
