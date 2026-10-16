---
title: What earns a place in the browser layer
version: 1
---

The wrong idea is that a browser test is the most realistic test, so the most valuable one, so a
check is better the closer it runs to the user. It is realistic. **What a browser test buys is the
seam**: the page, the server and the browser running together, the way nothing else in a suite
runs them. A check that does not need the seam pays for it anyway and gets nothing for the money.

So the browser layer is decided by one question, asked of every check before it is written there:
**could a cheaper layer see this?** If yes, it goes down. If no, it has earned its place.

## What belongs there

- **A journey, end to end.** Open the shop, add a banana, read the total. One test per path a
  customer actually walks, and the paths that pay the bills first. It is the test that fails when
  anything in the chain is broken, which is what you want from the few tests at the top.
- **The seam between the page and the server.** This lesson's first defect lived there: the server
  answered 590 and was right, and the page drew it as R$ 590,00. Nothing below the browser reads
  what the page draws.
- **What only a browser does.** Lesson 4's cache, lesson 5's service worker, lesson 6's buttons that
  did nothing for a second and a half, and lesson 7's basket too wide for a phone. Each one is
  invisible to a request and to a function, because each is something the browser does with the
  answer after it arrives.
- **What a person perceives and operates.** Focus, the keyboard, what is visible and what is
  covered. `non-functional-testing` lessons 12 to 15 take accessibility on properly; the point
  here is only that it lives in this layer.

## What does not

- **Arithmetic.** `total()` is a rule over numbers, and three unit cases pinned what the browser
  test let through. A browser test of arithmetic is a slow unit test with more ways to fail.
- **Validation rules.** Whether a taken name is refused is an answer from the server, `409`, and
  lesson 15 met it. One browser test shows that the refusal reaches the screen; every other case of
  what the server accepts and refuses belongs to the layer that decides it.
- **Every combination of inputs.** This is where the cost section's arithmetic stops being
  theoretical. The shop has eight products, and a basket holding none to three of each is one of
  4 multiplied by itself eight times, 65,536 baskets. At the 281 ms the browser test took for a
  single click, they would cost 65,536 × 0.281 = 18,416 s, more than five hours, before counting
  the extra clicks a quantity needs. At 1 ms each at most, the unit layer runs them in about
  66 seconds. Even there you would not write them all: you would pick the cases with something to
  say (empty, one, several of one, several of many), and they would be unit cases.

## The test that was moved down, and what it lost

Moving a check down is not free either, and lesson 6 has the case to remember. The HTML of `/ssr`
was right all along, so the request test passed, during the second and a half when every button on
the page did nothing. **A check moved below the browser keeps its subject and loses the seam.** If
the seam was the subject, the cheaper test is a test of something else.

So the rule has two halves, and the second one is the one that gets forgotten. Push every check to
the cheapest layer that can see it, and keep at least one browser test over every seam, because
that test is the only one that crosses it. On quitanda that is a short list: the journey this
lesson measured, the hydration wait of lesson 6, the overflow of lesson 7, and the few others the
earlier lessons each argued for. Lesson 22 takes the same judgement one step further, to the test
that should not be written at all.
