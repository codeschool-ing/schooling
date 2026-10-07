---
title: Pairing at a distance
version: 1
---

**Remote pairing works as well as pairing at a desk once three things are settled: both people can
type, both can hear each other without effort, and the swap takes seconds rather than minutes.** Half
of Marola's engineers work from home most days, so most of its pairing is remote, and the failures
are almost always one of those three.

## Both people can type

The worst setup is one person sharing their screen while the other watches a video of it. The
navigator cannot point at anything except by describing it ("no, the line above, the other one"), and
the swap means stopping the share, pushing a branch, pulling it and sharing again. Pairs who work this
way stop swapping, and the session turns into a demonstration.

What works is a shared editing session, which most editors and development environments now offer, or
a short-lived branch that both people push to on every swap, with a tool that does the push and pull
in one command. **The test is whether a swap takes less than ten seconds.** If it takes longer, people
stop doing it.

## Both can hear

Audio matters more than video. A headset, a quiet room, and an agreement to say "can you repeat that?"
without apology. Video helps in the first minutes and at the moments of disagreement, when a face
carries what words do not; for the rest of the session many pairs turn it off and keep the editor on
the whole screen.

## A timer, and breaks

At a desk, people notice when the other person is tired. Remotely they do not, so the structure has to
do it:

- **a timer for swaps**, visible to both, every twenty-five minutes or so;
- **a break every hour**, a real one, away from the screen;
- **an agreed end**, said at the start: "until lunch", "until the test passes".

## Writing down where you got to

Remote pairs often end mid-task, at a different time for each person. The last five minutes go to a
note in the pull request or the ticket: what was done, what is next, and anything decided that is not
yet in the code. **That note is the difference between a pair that can resume tomorrow and one that
spends the first half hour reconstructing yesterday.**
