---
title: Choosing a model
version: 1
---

Price is the easiest number to compare and the last one to decide on. **A model is good enough for
a task or it is not**, and only your own evaluation says which, run on your own cases, as lesson 5
built. A leaderboard measures someone else's task.

## The order to decide in

1. **Can it do the task?** Run the evaluation from lesson 5 against each candidate. Keep the ones
   that pass the bar the task needs, and drop the rest whatever they cost.
2. **Does it fit?** The context window must hold your largest real prompt with room for the reply,
   and the reply limit must hold your longest real answer. Both are in the price sheet of lesson 2.
3. **Is it fast enough?** Measure time to first token and total time, as lesson 9 did, from where
   your servers are, at the hours your users ask.
4. **May the data go there?** The provider's terms, the region the request is processed in and
   what is kept afterwards, as lesson 10 section 09 lists. A model that fails this is out, however
   good.
5. **Then the price**, among the models still standing, on your workload, as lesson 10 section 06
   computed it.

## Keep the choice reversible

Models are replaced every few months, and prices move. **The decision you can make once is how
easy the next decision will be**:

- **Name the model in configuration**, not in the code, as the adapter in lesson 10 section 08
  does. Changing model is then a deploy, not a pull request across the codebase.
- **Keep the evaluation runnable.** A new model is a question the evaluation answers in minutes,
  instead of an opinion argued in a meeting.
- **Pin the model's full version** where the provider offers one. An alias that moves to a newer
  model changes your product on the provider's schedule instead of yours.
