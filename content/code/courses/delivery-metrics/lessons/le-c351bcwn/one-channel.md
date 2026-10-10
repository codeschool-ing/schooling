---
title: One channel, and updates on a clock
version: 1
---

An incident generates a great deal of talk, and the worst place for that talk is everywhere: direct messages, three chat channels, a phone call, a corridor. Information said in one place does not reach the people in the others; two people try the same fix; a decision made on a call is not known to the person about to do the opposite.

## One incident, one channel

**Every incident gets its own channel**, created when it is declared and named after it, and everything said by the responders is said there. It becomes the incident's record without anybody having to assemble one: the scribe's timeline, lesson 14, is written from it. A phone or video call is fine for speed, but every decision taken on the call is written into the channel within a minute, by the scribe.

People who are not responding stay out of the incident channel. They need information, not the investigation, and their questions in the working channel interrupt the people fixing. That is what the communications lead is for.

## Updates on a clock

The communications lead posts updates **on a fixed rhythm set by the severity**, whether or not anything has changed: every 30 minutes for a SEV1, every hour for a SEV2 in the Billing team's scale. "No change, still investigating, next update at 18:30" is a useful update. It stops people asking, and it proves somebody is on it.

Each update answers four questions, in the same order every time:

1. **What is happening**, in the users' terms: "Some shops are being charged twice for their monthly subscription."
2. **Who is affected**, as precisely as is known: "Shops charged since 17:20 today; about 140 so far."
3. **What we are doing**: "We are rolling back this afternoon's release."
4. **When the next update is**: "Next update at 18:30, or sooner if this changes."

What updates leave out is speculation about cause. "We think it was the new retry logic" in a message to the support team becomes, an hour later, what support tells the shops, and it may be wrong. **Cause belongs in the postmortem**, lesson 15.

## The audiences

| who | what they need | where |
|---|---|---|
| responders | everything | the incident channel |
| support | what to tell users, and when it will be fixed | a support channel, or a pinned message |
| leadership | severity, impact, and whether they need to act | a short message on the same rhythm |
| users | that we know, what is affected, when to expect news | the status page, and messages to affected shops |

One person writing for all four, from the same facts, is how the four stay consistent.
