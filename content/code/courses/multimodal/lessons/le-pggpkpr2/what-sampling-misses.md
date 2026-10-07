---
title: What any of this can miss
version: 1
---

The course's video was built to have one blind spot, and every method in this lesson had one of its own. In real video the blind spots are not planted, so it helps to know where they tend to be.

**What is shown and not said.** The truth file lists what each slide shows and what the narration says over it:

```
ana@lab:~/mm$ python -c "import json; s = json.load(open(\"media/truth/returns.json\"))[\"slides\"]; [print(x[\"slide\"], \"shown:\", x[\"shown\"], \"| said:\", x[\"said\"] or \"-\") for x in s if x[\"slide\"] in (3, 5, 7)]"
3 shown: ['( ) Damaged in transit', '( ) Wrong book sent', '( ) Changed my mind'] | said: Second, press Return this item and choose a reason from the list.
5 shown: ['Quote it if you call us'] | said: -
7 shown: ['Within 30 days of delivery', 'Damaged books: refunded in full', 'The label is valid for 7 days'] | said: Refunds go back to the card you paid with. A damaged book is refunded in full, shipping included.
```

Slide 3 shows three reasons and the narration says *choose a reason from the list*. Slide 7 shows *The label is valid for 7 days*, and nobody says it. Slide 5 says nothing at all. A pipeline that only listens loses all three, and so does any customer who cannot see the screen, which is lesson 14's subject: the information a sighted viewer gets for free has to be put into words for everybody else.

**What is said and not shown.** *Refunds go back to the card you paid with* is only in the speech. A pipeline that only looks loses it, and so does a viewer who cannot hear it.

**What happens between samples.** A fixed rate sees the world through a fence, and anything shorter than the gap between posts can pass unseen. Scene detection closes that gap for cuts and opens a different one for gradual change: a slow fade, a pan across a shelf, a person walking into frame. The safe default for unknown video is both, a fixed rate for coverage and scene changes for cuts, and the cost section of lesson 13 is where that combination gets a budget.

**What is in neither stream.** A video can carry meaning in its edit (a reaction shot, a pause), in on-screen motion (an arrow pointing at a button), or in things a model reading frames cannot know (that this is last year's returns policy). The honest output of a video pipeline says what it looked at: *frames at every scene change and the full soundtrack*, so a reader knows what it could not have seen.

## For long video

Everything above scales with length. An hour of video is 3,600 frames at one a second, 3,978,000 tokens at high detail by the same tile rule, before a word of the soundtrack. Long video is handled in pieces: transcribe all of it (audio is cheap, lesson 13), detect scenes, keep a frame per scene at low detail, summarise each piece, and summarise the summaries, keeping the times so any claim can be traced back to a moment.
