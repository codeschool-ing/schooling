---
title: From a build to a user, on both stores
version: 1
---

**Nothing in this lesson was run against a store.** There is no Play Console account and no App
Store Connect account behind it, no app was uploaded, and no screen of either console is shown.
What it describes comes from each store's own documentation, read on 30 October 2026 and named
where it is used. The two small programs near the end run on Node.js like the rest of the course,
and they model rules; they talk to no store. Nothing here asks you to pay for anything.

**The common picture of publishing is a button: the app is finished, you upload it, and people
download it.** The real path has five stages, and the ones in the middle are where an app spends its
first weeks. Both stores have the same five, with different names and different rules inside each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l20-path\" aria-label=\"The path from a build to every user, on both stores, in five stages left to right. A signed build; review; testing tracks; a staged release; everyone. Top row, Google Play: an app bundle signed for Play, Google Play review, internal then closed then open testing, a staged rollout to a percentage the team chooses, and production. Bottom row, the App Store: a build signed through Apple, App Review, TestFlight with internal and external testers, a phased release over seven days, and all users. Under the stages, a note that review comes before the public on both, and that external TestFlight builds are reviewed too.\"><defs><marker id=\"l20-path-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"156\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">a signed build</text><text x=\"280\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">review</text><text x=\"404\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">testing tracks</text><text x=\"528\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">staged release</text><text x=\"652\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">everyone</text><text x=\"12\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Google Play</text><text x=\"12\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">App Store</text><rect x=\"100\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"156.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app bundle,</text><text x=\"156.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signed</text><path d=\"M212 76 L224 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"224\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Google Play</text><text x=\"280.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">review</text><path d=\"M336 76 L348 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"348\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">internal, closed,</text><text x=\"404.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">open testing</text><path d=\"M460 76 L472 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"472\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">staged rollout,</text><text x=\"528.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">% you choose</text><path d=\"M584 76 L596 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"596\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"652.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">production</text><rect x=\"100\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"156.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">build signed</text><text x=\"156.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">through Apple</text><path d=\"M212 166 L224 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"224\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">App Review</text><path d=\"M336 166 L348 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"348\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TestFlight:</text><text x=\"404.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">internal, external</text><path d=\"M460 166 L472 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"472\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phased release,</text><text x=\"528.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7 days</text><path d=\"M584 166 L596 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"596\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"652.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">all users</text><text x=\"404\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">external TestFlight builds go through review as well</text><path d=\"M404 204 L404 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path></svg>", "caption": "The same five stages on both stores. The names differ; the order does not. Nothing here was run against either store."}
```

## The stages, briefly

**A signed build.** Each store accepts only an app signed with a key that proves it came from you,
and the same key, or one the store manages for you, signs every later version. Signing is the whole of
lessons 1 and 2 of `mobile-delivery`; this lesson assumes a signed build exists.

**An account with the store.** Google's is the Play Console, Apple's is App Store Connect, reached
through the Apple Developer Program. The next part says what each costs.

**Review.** Both stores look at an app before the public gets it. Android's documentation on
publishing says an app is live "once it has passed Google Play review"; Apple reviews every app and
every update. The next section is about what review rejects.

**Testing tracks.** Before everybody, a build can go to the team, then to a group of testers, then to
anyone who opts in. Play calls these internal, closed and open testing; Apple calls its version
TestFlight. Two sections on, both are laid out.

**A staged release, then everybody.** A new version does not have to reach every user on the same
day. Both stores can hand it to a fraction first and widen it, and both let you stop when something
is wrong. The last section models Apple's schedule.

## What an account costs

**Apple charges a yearly membership; Google charges a registration fee.** Apple's page on the Apple
Developer Program lists a "$99 annual membership", as read on 30 October 2026, and an individual or
an organisation pays it every year the app stays on sale. The same page lists the Enterprise
Program at $299 a year, which is for distributing apps privately to an organisation's own employees,
not through the App Store.

Google charges a fee to register a Play Console developer account. Its amount and terms are on Google's
Play Console Help pages at `support.google.com`, which could not be reached from the machine this
course was written on, so this lesson does not quote a number it did not read. Look it up there
before you register, and look up Apple's again too: both are prices, and prices change.

**`mobile-delivery` lesson 3 is about the accounts in depth**: the consoles, the roles a team gives
its members, and the fees with their conditions. This course needs neither account. The planner never
leaves your computer here, and the courses after the fork reach a phone through an emulator, a
simulator or Expo, none of which needs a store account.

## What changes, and what does not

**The code is a small part of what the store sees.** It also sees a listing, screenshots, a
description, a privacy declaration (lesson 13), a content rating, the countries the app is sold in,
and a contact address. Each of those is reviewed, each can be the reason for a rejection, and some of
them can be changed later without a new build. The version number, the next sections show, cannot be
taken back once a build carrying it is out.
