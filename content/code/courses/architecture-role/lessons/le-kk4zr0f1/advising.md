---
title: Questions before answers
version: 1
---

When a developer brings a design question to the architect, the obvious help is an answer. **An
answer solves today's problem and teaches the team to come back with the next one**, and an
architect who answers every question becomes the queue that every design waits in. Lesson 17 has a
name for where that ends: the architect as bottleneck. This section is about the habit that avoids
it, which is asking before answering and helping a team decide rather than deciding for it.

## The question Kátia brought

Three weeks into the role, Kátia Lemos, the tech lead of Matching, stopped Renata in the corridor.
Matching offers each load to suitable drivers, and to do that it needs to know which drivers are
free and where they are. Every offer made two calls to Tracking, and at the Monday morning peak the
offers were slow. "We want to put a Redis cache in front of Tracking. Is that all right?"

Renata had an opinion within ten seconds. She had been a staff engineer at Carreto for six years,
she knew the Tracking service, and a cache was a reasonable idea. "Yes, go ahead" would have taken
one sentence and earned a thank-you. Instead she asked four questions.

1. **What number are you trying to move?** "Slow" became a measurement: at the Monday peak,
   building the list of candidate drivers for one load took 1.8 s at the 95th percentile, and Kátia
   wanted it under 400 ms.
2. **What happens when the cached position is wrong?** A driver who accepted another load two
   minutes ago would still look free. Kátia had not thought about it; her team did, and worked out
   that an offer to a driver who is no longer free costs one rejected offer and about thirty
   seconds, which they could live with.
3. **Who else reads these positions?** The Shipper app shows trucks on a map. If Matching cached
   positions and the map did not, a shipper could see a truck in one place and receive an offer
   computed from another.
4. **What would you try first if a cache were not allowed?** The team looked again and found that
   one of the two calls fetched a driver's whole history when Matching needed only the last
   position.

The fourth question did the most work. Removing the wasted call brought the 95th percentile down
to 650 ms. The cache, which the team still added, took it to 280 ms, with a sixty-second expiry the
team chose because of question 2. **Kátia's team made the decision, and it was a better one than
Renata's ten-second answer**, because they now knew things about their own system that a yes would
never have sent them looking for.

## Why asking works better than telling

There are three reasons, and the third is the one that matters over a year.

**The team knows things the architect does not.** Renata knew Tracking's design. Kátia's team knew
which call was expensive, how often a driver changes status and what a rejected offer costs. An
architect's answer is built on the architect's information, and at a company of 50 engineers that
information is always partial.

**People carry a decision they reached themselves.** A team told to add a cache adds the cache and,
when it misbehaves at 3 a.m., remembers whose idea it was. A team that chose it understands the
trade it made, and fixes it.

**The questions are reusable and the answers are not.** "What happens when this is stale?" works on
the next cache, the next read replica and the next copy of anybody's data. Kátia's team now asks it
with Renata nowhere near, which was the purpose. An answer helps once; a question the team has
learnt to ask helps every time after.

## Questions that help, and one that only pretends

Not every question does this. The useful ones come in three kinds.

- **Clarifying**: what is the goal, what number, for whom, by when. These turn a request into a
  problem, the way lesson 7 does with the business.
- **Probing**: what happens when this fails, what happens at ten times the load, who else depends on
  it. These find the cases the design has not met yet.
- **Widening**: what else did you consider, what would you do if this option were not allowed, what
  is the smallest thing that could work. These stop a team comparing its favourite option with
  nothing.

**The one that only pretends is the leading question**: "Don't you think a queue would be better
here?" It is an answer wearing a question mark, and developers recognise it at once. It is worse
than an honest answer, because it adds a guessing game to the instruction. If Renata has a view,
she states it plainly and says what kind of view it is.

## Say which hat you are wearing

That last point carries a lot of weight. Lesson 3 described the advice process: anyone may make an
architectural decision, provided they first seek advice from the people it affects and from people
with the relevant expertise, and the person deciding is not obliged to follow the advice. It works
only when everybody knows which of three things the architect is doing.

| what Renata is doing | how it sounds | who decides |
|---|---|---|
| giving advice | "My advice is to measure before you cache. It is your call." | the team |
| pointing at a standard | "Services read another team's data through its API, never its tables. That is a standard." | already decided, by the standard (lesson 9) |
| making a decision | "This changes the contract with Tracking, so Tracking's lead and I decide it, and we write an ADR." | the architect, with the people affected |

**Mixing these up costs trust in both directions.** Advice that turns out to have been an order
teaches teams to stop asking. An order delivered as a suggestion gets ignored and then becomes an
argument. Renata closes most conversations by saying which row of that table they were in.

## When to just answer

Asking is not always right, and treating it as a rule produces an architect who answers "what time
is it?" with "what do you think?". Renata answers directly in four situations.

- **It is a fact, not a judgement**: which version of the CT-e layout the tax authority accepts,
  where the Payments contract is documented, what a standard says.
- **Something is on fire.** During an incident the team needs a decision in minutes, and the
  learning happens in the review afterwards.
- **The decision is a one-way door** (lesson 5) and the team has not met one of its kind before.
  Learning by getting it wrong costs too much, so she gives the answer and explains the reasoning
  as she does.
- **The team has already done the thinking** and wants a second opinion. Then her opinion, with its
  reasons, is exactly the help they asked for.

Even then, a short "here is why" turns an answer into something the team can reuse. What separates
it from a lecture is length: a sentence or two of reasoning, not a seminar.

## The shape of the conversation

Renata's conversations with teams settled into a pattern that takes about half an hour:

1. **Restate the problem** in her own words until the team agrees she has it right.
2. **Ask about the goal and the number** before looking at any solution.
3. **Ask what happens when things fail**, and what else the team considered.
4. **Give her view**, labelled as advice, with its reason.
5. **Say who decides**, and what she would like to see written down, if anything.

It is slower than answering in the corridor. Over her first quarter it was also why the number of
design questions reaching Renata fell while the number of design decisions at Carreto did not.
Lesson 10 described the architecture forum, where those decisions become visible to everybody;
this is the one-to-one version of the same idea.
