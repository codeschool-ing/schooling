---
title: Privacy policy
effective: 2026-08-19
covers: accounts, account_credentials, sessions, visitors, account_visitors, events, section_progress, resume_pointer, notes, practice_state, practice_review, practice_drawn, exam_attempts, exam_answers, certificates, ledger_entries, subscriptions, subscription_events, staff, audit_log
---

This says what we hold about you, why, and what happens to it when you ask us to
stop. It describes the system as it is actually built rather than the widest
thing we might one day be entitled to do — where those two differ, this document
is the one that binds us.

> **Still to be filled in before this is published.** The name and registration
> number of the company behind the platform, its address, and the address to
> write to about anything below. Until those are here, treat this as a
> description of the system rather than as a published policy — a policy with no
> controller named on it is not one you could act against.

## The short version

- We hold your e-mail, your name, and what you have studied.
- We do not hold your card number. We never see it.
- We give you a **random identifier before you have an account**, so we can tell
  how many people who looked went on to sign up. It has no name in it.
- Nothing on these pages is loaded from anybody else's server, so no third party
  learns which lessons you read.
- You can ask for everything we hold, and you can ask us to erase you. What
  erasure does, and the one thing it cannot remove, is described exactly below.

## Before you have an account

The first time a browser reaches us we set a cookie containing a **random
identifier**. It is not your name, your address or anything derived from them —
it is a number that means "this browser" and nothing else.

It exists to answer one question: of the people who arrived, how many signed up.
That cannot be reconstructed afterwards, because by the time somebody signs up
the visit that brought them is over. If you later create an account, we record
the link between that identifier and the account, which is what makes the answer
possible at all.

What we record against it is the pages you asked for and the country the request
came from. **We do not store your IP address.** The country is derived from the
request and the address itself is discarded.

## Once you have an account

We hold:

- **Your e-mail address and the name you gave us.** The e-mail is how you sign
  in and how we reach you about your subscription.
- **Your password, as a hash.** Not the password. We cannot read it, tell you
  what it is, or recover it for you.
- **Your sessions** — one row per browser you are signed in on, holding a hash
  of the session token and the browser's own description of itself. Changing
  your password ends every other session.

## What you do here

Studying produces a record, and it is the record that makes the product work —
it is what puts you back where you left off, schedules a review, and decides
whether you have passed.

- **Which sections you have finished, and where you were.**
- **The notes you write in the margin of a lesson.** We do not read them and
  nothing analyses them; they are text you wrote for yourself, stored so it is
  there tomorrow.
- **Your practice**: which cards you have drilled, how each one is scheduled,
  and a log of every review — whether it was right, how long it took, and the
  schedule it produced. The log is kept so a better scheduler can be fitted to
  real answers later rather than argued about.
- **Your exams**: the paper as it was set, the answers you gave, and what each
  scored.
- **Your certificates**, which carry the name you gave us, the course, and the
  date — because a certificate a stranger can verify is the point of having one.
  Anybody holding the code on a certificate can see those.

## Payments

**We never see your card.** The payment provider takes it, and what reaches us
is a reference to a transaction, an amount, and whether it succeeded.

We hold what you are paying for, the state your subscription is in, the history
of how it got there, and a record of every payment, refund and chargeback.

## Counting

Everything the platform reports on is built from a stream of events: something
happened, when, in which school, in which country, in which language, and under
which plan. Every one of them carries only identifiers — the visitor identifier
above, or the account one.

These are how we know which lessons are read, where people stop, and which
questions are so badly written that everybody gets them wrong. They are about
the material rather than about you.

## People who operate the platform

Two people run this. We record who they are and **every administrative action
they take**: what they did, to what, when, and what the value was before and
after. That record exists so that anything done to your account can be
attributed, and it is kept for that reason — an audit that the person it
recorded could delete would not be one.

## What we do not do

- **We do not load anything from another origin.** No fonts, no analytics, no
  embedded widgets. Your browser talks to this server and to nobody else, so no
  third party can learn which subject you study.
- **We do not sell anything about you, or share it for advertising.**
- **We do not track you across other websites.**
- **We do not profile you automatically in any way that decides something about
  you.** Whether you passed an exam is decided by the answers you gave.

## Cookies and what your browser keeps

Three things, and none of them is for advertising:

- **The visitor identifier**, described above.
- **The session cookie**, once you sign in. It is `HttpOnly`, so no JavaScript
  on the page can read it — including ours.
- **Your language and theme**, kept in your own browser's storage. They never
  reach us.

## Which law, and who to complain to

This is governed by **Brazilian law**, and specifically by the General Data
Protection Law (Law 13.709/2018). The rights it gives you are the ones described
here: to know what we hold, to get a copy of it, to have a mistake corrected, to
have it erased, and to know who we have shared it with — which, as the section
above says, is nobody.

If we get something wrong and you are not satisfied with our answer, you can
complain to the **ANPD**, the national data protection authority.

## Getting a copy

You can ask for everything we hold about you and we will give you the lot, as
data rather than as a summary. Two things are deliberately not in it, and
neither is about you:

- **The answer keys** to questions you have been asked. An export is a file you
  can be asked to hand to somebody else, and it must not be a way of obtaining
  the answers to an exam.
- **The text of the questions themselves**, which is material we wrote.

## Erasure, exactly

When you ask us to erase you, we delete the rows that make an identifier mean a
person: your account, your credentials, your sessions, the visitor identifiers
that belong to you and the link between them. Everything that then remains — the
events, the practice log, the record of payments — **still exists and no longer
joins to anybody**. There is no key left that connects them to you, to your
e-mail, or to each other through you.

We are telling you this rather than saying "we delete everything", because it is
what actually happens and because the alternative would be worse for everybody:
those rows are how we know which questions are bad, and deleting them would
degrade the material for the people still studying without making you any more
private than being unidentifiable already does.

Two things do not disappear:

- **The record that money changed hands.** We are required to keep it, and it is
  the other half of a bank statement. After an erasure it holds an amount, a
  date and an identifier that means nobody.
- **The record of administrative actions**, for the reason given above.

Your certificates **are** deleted, and the verification page then answers for
their codes exactly as it does for a code that never existed — because answering
differently would say that one had been there, which is the fact being erased.

## Keeping

We keep what you have studied for as long as you have an account, because that
is the account. Payment records are kept as long as Brazilian tax law requires
them, and then no longer.

## Changes to this document

Every version of this policy is in a public repository with its full history, so
what it said on any given day can be established rather than remembered. The
date at the top is the day the current version took effect.
