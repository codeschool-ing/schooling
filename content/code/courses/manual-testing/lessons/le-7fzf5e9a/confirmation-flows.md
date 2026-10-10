---
title: What a confirmation flow promises
version: 1
---

The first idea most people have of testing e-mail is checking that a message arrived. Arrival is
the easy part. **A confirmation e-mail is one step in a flow with state**: an account waiting to be
confirmed, a secret sent to an address, a clock running on that secret, and rules about what
happens when somebody asks for another. Most of what goes wrong lives in those rules, and none of
it is visible in the message itself.

## Why an application confirms an address

When somebody types an e-mail address into a sign-up form, the application has no idea whether the
address is theirs. It may carry a typo, which sends every future message to a stranger. It may be
somebody else's, typed on purpose. Sending a link to the address and waiting for somebody to open it
proves one thing: **the person who signed up can read that inbox.** For boxoffice it also decides
money, because R5 gives a confirmed account, a member, 10% off.

## The parts of the flow

R3 states boxoffice's flow in two sentences: a new account receives an e-mail with a link that
confirms it, valid for 24 hours, and asking for a new link makes the old one stop working. Read as a
tester, that is five things to check.

**The link carries a token**, a random string that stands for "this account, this address". Whoever
holds the token can confirm the account, so the token is a small secret. It has to be long enough
that nobody can guess it, and it should exist in one place only, the e-mail.

**The token expires.** A link that worked forever would be a secret that never stops being one, sitting
in an inbox for years. R3 gives it 24 hours.

**Asking again replaces the link.** People ask for a second link when the first did not arrive, or
arrived and was lost, or was sent to an inbox they share. In each case the first link is now in a
place nobody is watching, and R3's second sentence exists to switch it off.

**Using a link may or may not end it.** Many products make a confirmation link single use: once it
has confirmed the account, opening it again says it is no longer valid. R3 says nothing about this,
which is a different finding from a defect, as the next section shows.

**The answers say only what they must.** The page that receives a request for a new link answers the
same sentence whether or not an account exists for that address. If it answered "no such account"
instead, the form would tell anybody who asks whether a given person has an account at the theatre,
which is information about that person. A tester checks that the two answers are identical.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l22-two-links\" aria-label=\"A timeline with three bars. Events along the bottom: sign-up, when link A is sent; a request for a new link, when link B is sent; 24 hours after A; and 24 hours after B. The first bar, link A as R3 says, is live from sign-up until the new link is asked for, and stops working there. The second bar, link A in boxoffice 1.1, stays live until 24 hours after sign-up, so from the request for a new link until then two links are live at once, which is defect 10. The third bar, link B, is live from its request until 24 hours after it.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M190.0 26.0 L190.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M280.0 26.0 L280.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M640.0 26.0 L640.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M550.0 26.0 L550.0 128.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M550.0 152.0 L550.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link A, as R3 says</text><text x=\"20.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link A, in boxoffice 1.1</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link B</text><rect x=\"190.0\" y=\"32.0\" width=\"90.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M280.0 40.0 L550.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"290.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stops working</text><rect x=\"190.0\" y=\"82.0\" width=\"90.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"280.0\" y=\"82.0\" width=\"270.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">two live links: defect 10</text><rect x=\"280.0\" y=\"132.0\" width=\"360.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M180.0 180.0 L670.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"670.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><text x=\"190.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sign-up:</text><text x=\"190.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">link A sent</text><text x=\"280.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new link asked:</text><text x=\"280.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">link B sent</text><text x=\"550.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 hours</text><text x=\"550.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">after A</text><text x=\"640.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 hours</text><text x=\"640.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">after B</text></svg>", "caption": "How long each confirmation link lives. R3 ends link A when link B is sent; boxoffice 1.1 lets it run its full 24 hours."}
```

## Cases, from the requirement

Each of those parts turns into one or more cases, and every expected result comes from R3, or is
marked as a question when R3 is silent. That mark is the honest one: **a case whose expected
result nobody wrote down is a question for the client**, and lesson 12 is about putting it to them.

| # | case | expected |
|---|---|---|
| 1 | sign up, open the link within 24 hours | the account is confirmed (R3) |
| 2 | open the link with one character of the token changed | the link is not valid |
| 3 | open the link more than 24 hours after it was sent | the link is not valid (R3) |
| 4 | ask for a new link, then open the old one | the link is not valid (R3) |
| 5 | ask for a new link, then open the new one | the account is confirmed (R3) |
| 6 | open a link that has already confirmed the account | not written: ask the theatre |
| 7 | ask for a new link for an address with no account | the same answer as for one that has, and no e-mail |
| 8 | ask for a new link for an account already confirmed | no e-mail |
| 9 | read the e-mail itself | the right address, the account's name, a link to the right site |

Case 9 hides a classic. **The link in the e-mail is built by the application from its own
settings**, and boxoffice builds it from `127.0.0.1` and its port. On the theatre's server it would
have to name the theatre's real address. A link that points at a test machine, or at the wrong port,
looks perfectly normal in the message and fails only when somebody clicks it from home. It is the
kind of defect lesson 21 is about, one that lives in the environment rather than in the code.

## Where the e-mail goes while you test

Every case above needs you to read the e-mail. In production that means a real inbox, and nobody
wants a test run sending confirmation links to real customers. So test environments stop e-mail
before it leaves, and keep it where a tester can read it. boxoffice does it with the outbox, and the
next section runs the cases there.
