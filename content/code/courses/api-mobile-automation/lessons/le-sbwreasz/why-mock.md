---
title: Why a test replaces a dependency
version: 1
---

**boxoffice does not take money itself.** For every order it calls a payment provider, waits for an
answer, and confirms or refuses the order according to what came back. Up to now that call never
happened. With `PAYMENTS_URL` empty, boxoffice approves every charge on its own, which is why every
order so far carried a payment called `ch-local-ord-…`. A real deployment sets the variable, and
from then on a part of boxoffice's behaviour belongs to a program somebody else runs.

A test of boxoffice still has to cover that part. **The usual answer is to put a stand-in where the
provider would be**: a small server that answers the way the provider answers, run by you, on your
machine. Four reasons, and each is a thing the real provider cannot give a test:

- Money. A charge against a real provider is a real charge. Providers offer a sandbox for testing,
  with test cards and no money moving, but it is still their server, on their terms.
- Failures on demand. The tests that matter most are the ones where payment goes wrong: a decline,
  an error, an answer that never arrives. Nobody can ask a real provider to time out at 10:15 on a
  Tuesday, and lesson 13 needs exactly that, every run.
- Speed and availability. A test that crosses the internet takes the provider's time and fails when
  the provider has an outage, so your suite goes red for somebody else's bad morning.
- Observation. A test wants to know what boxoffice *sent*: the amount, the reference, the
  idempotency key. The provider does not show you the requests it received. A stand-in can.

## What a stand-in is called

**The vocabulary comes from unit testing, where the stand-ins are objects rather than servers.**
Gerard Meszaros named them in *xUnit Test Patterns* (2007), and the names travelled to the network
level unchanged:

| name | what it does | in this lesson |
|---|---|---|
| stub | answers with what it was told to answer, whatever it is asked | every stand-in here, at least |
| spy | a stub that also records what it received, for the test to read afterwards | `payments-stub.mjs` and WireMock |
| mock | holds expectations about the calls it should get, and fails the test itself if they do not arrive | WireMock's verification, used that way |
| fake | a working implementation, simplified: a database in memory, a provider that keeps balances | none |

In conversation **"mock server" means any of them**, and so does the title of this lesson. The
distinction is still worth having in your head, because it says what a stand-in can tell you. A stub
cannot tell you anything about the requests it got, and a spy can. *Service virtualisation* is the
same idea sold as a product: a stand-in for a whole service, recorded or modelled, run by a team for
other teams.

## Where the line goes

**Replace what is outside the thing under test, and nothing inside it.** Here the thing under test
is boxoffice, so the payment provider is replaced and boxoffice runs as it is, unchanged, with only
an address pointed elsewhere. Replacing part of boxoffice as well would be testing the stand-in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 244\" role=\"img\" aria-label=\"A client or a test sends requests to boxoffice, which sits inside a dashed boundary marked under test, unchanged. From boxoffice, PAYMENTS_URL leads either to the payment provider, in production, with real money, its outages and not yours, or, as a dashed line, to a stand-in, in a test, which answers what you wrote and records what it got.\"><defs><marker id=\"f11boundary-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"214\" y=\"58\" width=\"200\" height=\"124\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"314\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">under test, unchanged</text><rect x=\"20\" y=\"95\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client</text><text x=\"85\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">or a test</text><rect x=\"239\" y=\"95\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"314\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"520\" y=\"30\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payment provider</text><text x=\"600\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in production</text><rect x=\"520\" y=\"160\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a stand-in</text><text x=\"600\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in a test</text><line x1=\"152\" y1=\"120\" x2=\"237\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11boundary-ah)\"></line><line x1=\"391\" y1=\"112\" x2=\"518\" y2=\"58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11boundary-ah)\"></line><line x1=\"391\" y1=\"128\" x2=\"518\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#f11boundary-ah)\"></line><text x=\"455\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PAYMENTS_URL</text><text x=\"600\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">real money, its outages, not yours</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">answers what you wrote, records what it got</text></svg>", "caption": "The stand-in replaces what lies outside the boundary; boxoffice itself runs unchanged, with one address pointed elsewhere."}
```

That picture also shows what a stand-in costs. **A test against a stand-in proves that boxoffice
handles the answers you wrote.** It says nothing about whether the provider really answers that way.
The day the provider changes, the stand-in goes on answering as before and every test stays green.
Section 06 makes that happen on purpose and shows how to catch it.
