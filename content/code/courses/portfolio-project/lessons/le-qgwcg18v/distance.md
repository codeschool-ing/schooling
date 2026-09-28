---
title: Distance
version: 1
---

The hardest part of reviewing your own work is that you remember what you meant, and your memory fills
in what the diff does not say. Three ways to get some distance, in order of how much they help:

- **Time.** Read the diff the next morning, not five minutes after writing it. The gap is what lets you
  see the code instead of the intention. For a portfolio project there is no deadline so tight that a
  night's sleep does not fit.
- **A different view.** Read it in the hosting site's pull-request page rather than your editor. The
  change looks different in a different place, and it looks the way a reviewer will see it.
- **A different order.** Read the tests first, then the code. The tests say what the change claims to
  do; then check whether the code does it, which is what a reviewer is doing.

And one habit that works even without distance: **read the diff out loud**, or at least the parts you
are least sure about. A line you cannot explain out loud is a line lesson 20's interviewer will ask
about, and it is better to find that now.

None of this replaces another person. If a friend, a study group or a mentor will read one of your pull
requests, ask them; a real review is the best preparation for the questions in lesson 20. But most
portfolio projects have no second reader, and a careful first one is most of the value.
