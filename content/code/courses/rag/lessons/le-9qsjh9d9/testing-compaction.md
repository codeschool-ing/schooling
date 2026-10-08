---
title: Testing compaction
version: 2
---

Everything in this lesson reduces to one test, and it is worth writing down as a test rather than as
advice:

- **A set of conversations**, real ones with the personal data replaced, long enough to be compacted.
- **For each, a list of essentials**, the facts a person taking over the conversation would need,
  written by someone who read it.
- **For each compaction**, after every round, the number of essentials still present. The pass mark is
  all of them; a compaction that drops an essential is a bug with a conversation that reproduces it.

The check in this lesson is a substring match, which suits identifiers and pinned sentences kept
verbatim. A language model's summary paraphrases: "I want my money back" came back as "a refund", and
"write to me by email only" may come back as "prefers email contact". So the check needs to be looser
where the fact allows it and strict where it does not. **Identifiers stay strict**: an order number either appears
exactly or it is lost. Preferences and decisions can be checked by a short list of acceptable phrasings,
or by a second model asked a yes-or-no question per essential, with lesson 8's caution about using a
model to judge a model: measure the judge on a few cases a person has marked before trusting its
count.

Run the test when anything that touches compaction changes: the summariser's model or prompt, the word
limit, the pinning rule, the threshold that triggers it. Each of those is a default somebody will one
day change for a good reason, and the test is how they find out what it cost.
