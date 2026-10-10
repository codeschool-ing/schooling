---
title: Running the postmortem meeting
version: 1
---

The meeting reviews the document; it does not write it. Its job is to check the timeline with the people who were there, test the contributing factors, agree the action items, and say out loud the things that are hard to write down. An hour is usually enough for a SEV1.

## Who runs it

**A facilitator who was not the incident commander**, if possible. The IC made decisions during the incident that the meeting will examine, and it is hard to examine your own decisions while chairing. The facilitator's job is to keep the meeting on the second story, to make sure everybody who was involved speaks, and to stop the meeting from becoming a trial.

## How to ask

The single most useful habit is to ask **"how"** and **"what"** rather than **"why"**. "Why did you approve that change?" is heard as an accusation, however it is meant. "What did the review look at?", "How did it look at 17:20?", "What would have made the retry stand out?" ask about the situation, and people answer them fully.

Three more habits help:

- **Start with what went well.** It is easy to skip, and it is how a team learns what to keep. On 30 September, support asking within three minutes was the reason the response started as early as it did.
- **Go through the timeline in order**, and ask at each decision what the person knew at that moment. Hindsight creeps in when the meeting starts from the end.
- **End with the action items**, read aloud, each with its owner and date, and the overdue items from earlier postmortems. The previous section showed why the second half matters.

## What to do with the result

**Publish the document** within a day or two of the meeting, with the corrections the meeting made. **Put the action items on the board.** **Tell the people affected** what was learned and what will change, in their terms: the shops double-charged on 30 September were owed an explanation as well as a refund.

And **read other teams' postmortems**. Most incidents are not new: somebody, somewhere, has already been double-charged by a retry without an idempotency key, and written about it. A team that reads postmortems learns from incidents it never had to have.
