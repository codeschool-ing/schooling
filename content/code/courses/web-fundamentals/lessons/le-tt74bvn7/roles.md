---
title: The two roles
version: 1
---

Almost everything that happens on the internet is a conversation between two parties, and the two
parties have fixed jobs. The **client** asks. The **server** answers.

That is not a simplification you will outgrow. It is the actual shape, and it holds from the
smallest exchange to the largest — from a phone checking whether a message was delivered to a bank
settling a payment.

## The roles belong to the moment, not to the machine

This is the sentence worth reading twice, because almost every later confusion comes from getting
it wrong.

"Server" is not a kind of computer. It is not a black rack in a cold room, and it is not something
you buy. **It is the part a machine is playing in one particular exchange**, and the same machine
plays a different part in the next one.

Consider a web server building a page. To build it, it needs data it does not have, so it asks a
database for that data:

- to your browser, it is the **server** — you asked, it answered;
- to the database, it is the **client** — it asked, the database answered.

Same machine. Same second. Two roles, because there are two exchanges.

The laptop you are reading this on is a client right now. It is also, at this moment, very
probably running a server: if you have ever opened `localhost:3000` while building something, that
was your own machine answering its own question. One computer, both roles, no contradiction.

## Watch one page load

Abstractions are easier to trust once you have counted something. Open any news site and a rough
version of this happens:

1. Your browser asks for the page at that address. One exchange. It gets back a document — a few
   dozen kilobytes of HTML, and **no images, no styling, no code**.
2. Reading that document, the browser discovers it needs a stylesheet, four scripts, a font and
   nine images. It asks for each of them. **Fourteen more exchanges**, most of them started before
   the first one has finished being read.
3. One of those scripts, once running, asks for your notification count. **Another exchange**, this
   one to a different machine entirely.
4. Meanwhile the server that answered step 1 asked a database for the headlines, and asked a second
   service for the advertisement. **Two more exchanges you never see**, because they happened on
   the far side.

What felt like "loading a page" was somewhere between fifteen and a hundred separate exchanges,
each one with an asker and an answerer, each one complete in itself.

Two things follow, and both matter more than they look:

**Your browser is not one client, it is a client many times over.** It holds a dozen exchanges open
at once and assembles a page out of the answers as they arrive, in whatever order they arrive.

**Most of the exchanges are invisible to you.** The ones between the server and the machines behind
it never touch your computer. When something is slow, the cause is very often in a conversation you
cannot see — which is exactly why the vocabulary in this lesson is worth having.

## What each side is responsible for

The asymmetry between the two roles is not about power or size. It is about who starts and who
waits.

| | client | server |
|---|---|---|
| starts the exchange | **yes** | no |
| waits, doing nothing, until spoken to | no | **yes** |
| decides *what* to ask for | **yes** | no |
| decides *whether and how* to answer | no | **yes** |
| has to be reachable at a known address | not usually | **always** |
| can refuse the other party | not meaningfully | **yes, and does** |

Two rows deserve more than a cell.

### "Has to be reachable at a known address"

**A server has to be findable.** It sits at an address that other machines already know, or can
look up, and it waits there. A client does not need a fixed address in the same way — it goes out,
asks, and comes back with an answer.

This is why "the server went down" is a sentence people say and "the client went down" is not. If a
client stops, one person is inconvenienced. If a server stops, everybody who was going to ask it
anything finds nobody home.

It is also why running a server on your home laptop is harder than it sounds. Your laptop's address
changes, it sits behind equipment that does not forward incoming requests by default, and it goes
to sleep. None of those matter for a client. All of them are fatal for a server. Lesson 4 explains
the addressing part and lesson 9 explains what people rent to avoid the whole problem.

### "Can refuse"

The server decides whether to answer, and refusing is a normal, healthy thing for it to do — not a
malfunction. It may refuse because you are not allowed, because you asked for something that does
not exist, because you are asking too often, or because it is protecting itself from work it cannot
finish.

The client's power is the opposite one: it decides *whether to ask at all*, and it can walk away
before the answer arrives. Nothing obliges a client to wait, and this is why "cancel" works.

## The word "server" in the wild

You will meet the word used three different ways, and the ambiguity is real rather than something
you are failing to understand:

1. **The role** — "at that instant it is the server". This is the meaning this lesson is about.
2. **The program** — "we run an Nginx server on that machine". A piece of software whose whole job
   is to wait for requests and answer them.
3. **The hardware** — "we bought two servers". A physical machine bought to run programs of the
   second kind.

When someone says "server" and you cannot tell which one they mean, the useful question is: *is
this a thing that could be playing a different part in the next exchange?* If yes, they mean the
role. If it is bolted into a rack, they mean the metal.

## Three confusions worth clearing now

**"Client" does not mean "browser".** A browser is one kind of client. So is a mobile app, a
command-line tool like `curl`, a script that runs at three in the morning, a smart television, and
a payment terminal in a shop. If it asks, it is a client. This matters because a great deal of
traffic on the internet is machines talking to machines, with nobody watching.

**"Client and server" is not the same axis as "frontend and backend".** Frontend and backend
describe *where code runs and who wrote it* — the interface a person touches, against the system
behind it. Client and server describe *the part something plays in one exchange*. They line up
often enough to be confusing and they are not the same distinction: the backend is a server to the
browser and a client to the database, all while remaining, in every sentence, the backend.

**A server is not necessarily a big machine.** It is whatever is waiting to answer. A twenty-euro
computer the size of a credit card, sitting on a shelf and serving your photographs, is a server in
the fullest sense of every one of the three meanings above. Size is a consequence of how many
people ask, not of the role itself.

## What to carry into the rest of the course

Everything else in `web-fundamentals` is an answer to some part of one question: **how do the two
sides find each other, and how do they understand what was said?**

- Lessons 2 to 5 are about *finding* — packets, addresses and the layers that carry them.
- Lesson 6 is about *understanding* — the language the two sides speak.
- Lessons 8 and 9 are about *being findable* — names, and where a server lives.
- Lessons 10 and 11 are about what the client does with the answer once it has it.

Hold on to the shape and the rest hangs off it.
