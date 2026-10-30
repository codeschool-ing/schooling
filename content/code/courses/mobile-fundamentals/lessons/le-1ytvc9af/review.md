---
title: Review, and the reasons apps are sent back
version: 1
---

**Review is a person, or a process, at the store checking your app against written rules before
users get it, and most rejections are about an app that was not ready rather than an app that broke a
rule on purpose.** The common picture is a gatekeeper looking for forbidden content. That happens, and
the rules on content are long, but the commonest reasons are duller: the app crashed, a link went
nowhere, a screen still said "lorem ipsum", or the reviewer could not get past the login.

## Apple's guidelines, and what Apple says goes wrong

**Apple's rules are the App Review Guidelines**, a public page at `developer.apple.com/app-store/review/guidelines`,
organised in five parts: safety, performance, business, design and legal, each rule with a number
like 2.1. Apple's page on App Review, read on 30 October 2026, says it reviews
"at least 50% of submissions in less than 24 hours and 90% in less than 48 hours", and it lists the
most common issues. Its first claim is the one to remember: "over 40% of unresolved issues are
related to guideline 2.1: App Completeness, which covers crashes, placeholder content, incomplete
information, and more."

| what Apple lists | what it means for the planner |
|---|---|
| **crashes and bugs** | test on devices running the latest software before submitting; a crash on launch is a rejection |
| **broken links** | every link must work, and every app needs a link to user support and one to its privacy policy |
| **placeholder content** | no sample text, no empty screens, no "coming soon" images |
| **incomplete information** | if features need signing in, give the reviewer "a valid demo account username and password" |
| **privacy policy issues** | guideline 5.1: a policy linked in the metadata and inside the app, saying what is collected and who it is shared with |

**The demo account is the one that catches beginners.** Guideline 2.1 asks you to "include demo
account info (and turn on your back-end service!) if your app includes a login". A planner that syncs
to a server and asks for an account on its first screen is an app the reviewer cannot open without
one. A demo account that works, on a server that is up during review, is part of the submission.

**Privacy is reviewed against what you declared.** Lesson 13 covered the declarations each store
makes you fill in. Review compares them with what the app does: an app that asks for location while
its privacy information says it collects none has two statements that cannot both be true, and the
second one was written by you.

## Google Play's review

**Play reviews apps too, against the Developer Program Policies.** Android's documentation on
publishing says an app becomes available "once it has passed Google Play review". The policies
themselves, and Google's account of common rejection reasons, are on Google's Play Console Help and
policy pages, which could not be reached from the machine this course was written on; this lesson
quotes none of them. What it can say from Android's own documentation is narrower, and it is the next
paragraph.

**Play also tests the app on devices before a person ever sees it.** Android's documentation describes
the **pre-launch report**: when a build is uploaded to the open or closed testing track, Play runs it
on a range of devices and Android versions and reports problems with "stability", "Android
compatibility", "performance", "accessibility" and "security vulnerabilities". It is the cheapest
reviewer the app will ever have, and it checks the subject of lesson 19.

## When an app is rejected

**A rejection is a message, not a verdict.** It names what the reviewer found, and the usual answer is a new build or corrected metadata,
submitted again. Apple also lets you appeal to its App Review Board, one appeal per submission, when you think the
reviewer misunderstood the app. How to answer one, how long each step takes and how the appeal works are `mobile-delivery`
lesson 6.

**The cheapest rejection is the one you catch yourself.** Before submitting, the planner's release
checklist is short and comes straight from the table above: launch it on a real device on the latest
system; open every link; search for placeholder text; sign in with the demo account you are about to
give the reviewer; and read the privacy declaration against what the app actually collects.
