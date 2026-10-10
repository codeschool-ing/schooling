---
title: Hosted inboxes, and catchers you run yourself
version: 1
---

The outbox works because boxoffice was built with one. Most applications are not: they hand every
message to a mail server over SMTP, the protocol mail servers speak, and from there it goes out to
the world. Testing their e-mail means deciding **where the messages go instead**, and there are three
kinds of answer. A catcher you run yourself, a public inbox anybody can use, and a real inbox that a
test reads for you. None of the tools below was run for this course, and the course quotes no
prices, because both change faster than a lesson does.

## A catcher you run yourself

**MailHog** and **Mailpit** are the same idea as boxoffice's outbox, for applications that speak
SMTP. Each is a small program you start on your own machine or on the test server. It pretends to be
a mail server, accepts every message the application sends, keeps it, and shows the messages on a
web page; nothing is delivered anywhere. The application's mail settings, which are part of its
environment, are pointed at the catcher instead of at the real server. Mailpit is the newer of the
two.

This is the safest of the three answers, and for a test environment it is usually the right one: no
message can reach a real person, every message stays where the team can see it, and the data never
leaves the machines you control. Its limit is the one the outbox has. **It proves the application
sent the right message, not that a real mail server would deliver it**, and the rare defects that live
in delivery, a message marked as spam, a link broken by an e-mail program, are invisible to it.

## A public inbox: Mailinator

**Mailinator** is a public, disposable inbox service. Any name at its domain receives mail with no
account and no password: a sign-up form given `vila-test-4471@mailinator.com` sends its confirmation
there, and the message can be read on Mailinator's website by typing the name. Messages are deleted
after a short time. The company also sells private versions of the service for teams, which this
course did not look at.

The convenience is real when you test a staging site that sends real e-mail and you need a fresh
address for every case. **The price is that a public inbox is public.** Anybody who types the same
name reads the same messages, including a confirmation link that confirms somebody's account, or a
password-reset link that takes it over. So the rules are absolute:

- never a real person's name, address or data in anything sent to it;
- never an account that matters, on any product, behind one of its addresses;
- never production. A public inbox is for test data and nothing else.

There is a test hidden in it too. Many products refuse addresses at known disposable domains when
somebody signs up, on purpose. If yours is meant to, that refusal is a requirement and a case of its
own; if it is not, a team that tests with Mailinator will find out the day the product starts
refusing it.

## A real inbox read by a test: Gmail Tester

**Gmail Tester** is an open-source package for Node.js. It signs in to a real Gmail account through
Google's Gmail API, with credentials created for it in Google's developer console, so that an
automated test can wait for a message to arrive and read its subject and body, and pull a
confirmation link out of it. It belongs to automation rather than to manual testing; the automation
courses that follow this one in the `qa` track are where that kind of test is written. It is here
because its existence answers a question manual testers ask: can a test check a real inbox? It can.

**A real inbox is real data.** Use an account created only for testing, never a person's own, and
keep its credentials out of anything shared, such as the test files themselves. Gmail delivers mail
addressed to `name+anything@gmail.com` to the inbox of `name@gmail.com`, so one test account can
receive at `ana.tests+case4@gmail.com` and `ana.tests+case5@gmail.com` and keep each case's messages
apart.

## Choosing

| | where messages go | who can read them | what it proves |
|---|---|---|---|
| the outbox, MailHog, Mailpit | a catcher on your own machines | the team | the application composed the right message |
| Mailinator | a public inbox on the internet | anybody who types the name | a message left and arrived |
| Gmail Tester | a real Gmail account | whoever holds its credentials | a message arrived in a real mailbox |

Most teams use the first row for nearly everything and one of the other two for a handful of checks
in staging. The production check lesson 1's plan left for after the release, that a real e-mail
reaches a real inbox, is a person signing up with an address the theatre owns and reading it.
