---
title: Animations with @keyframes
version: 1
---

A transition needs a change to start it. An **animation** runs by itself, through stages described in an **`@keyframes`** rule:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; font-family: system-ui, sans-serif; }

      @keyframes drop-in {
        from { opacity: 0; translate: 0 -16px; }
        to   { opacity: 1; translate: 0 0; }
      }

      .notice { animation: drop-in 400ms ease-out; }

      /* Starts late, and shows itself during the delay. */
      .late { animation: drop-in 400ms ease-out 300ms; }

      /* Starts late, and waits in the first keyframe. */
      .late-filled { animation: drop-in 400ms ease-out 300ms backwards; }

      @keyframes spin { to { rotate: 1turn; } }
      .spinner {
        width: 24px; height: 24px;
        border: 3px solid #2f6f4e; border-top-color: transparent; border-radius: 50%;
        animation: spin 1s linear infinite;
      }
    </style>
  </head>
  <body>
    <p class="notice">The shop closes at 5 pm on Saturday.</p>
    <p class="late">New arrivals are on the front table.</p>
    <p class="late-filled">Bookbinding has two places left.</p>
    <div class="spinner" role="status" aria-label="Loading"></div>
  </body>
</html>
```

`@keyframes drop-in` names an animation and describes its stages: `from` is 0% and `to` is 100%, and percentages in between are allowed, `50% { … }`. The `animation` shorthand on `.notice` applies it: the **name**, the **duration**, the **timing function**, and optionally a **delay**, an **iteration count**, a **direction** and a **fill mode**. Here is the notice 100 ms in, and at its end:

```
ana@laptop:~/site$ probe keyframes.html at 100 style .notice opacity,translate at 400 style .notice opacity,translate
p.notice  opacity: 0.378138
p.notice  translate: 0px -9.94979px
p.notice  opacity: 1
p.notice  translate: none
```

At 100 ms it is **37.8% opaque** and **9.9 pixels** above its place. At 400 ms it is fully opaque and its `translate` is **none**: the animation is over, and the element is back to its own styles, which happen to match the last keyframe. That is the usual design, and the one to aim for: the keyframes describe how an element **arrives at** the state its normal styles already give it, so nothing depends on the animation having run.

## The delay, and the fill mode

The second and third paragraphs start 300 ms late. At 100 ms, neither has started:

```
ana@laptop:~/site$ probe keyframes.html at 100 style .late,.late-filled opacity
p.late  opacity: 1
p.late-filled  opacity: 0
```

`.late` is **fully visible**: during the delay, the animation does not apply yet, so the element shows its own styles. Then at 300 ms it jumps to the first keyframe, transparent, and fades in: a flash. `.late-filled` adds the fill mode **`backwards`**, which applies the first keyframe during the delay, and it is **transparent** while it waits. **`forwards`** keeps the last keyframe after the end, and **`both`** does both. Any delayed entrance needs `backwards` or `both`.

## Repeating

The spinner uses `animation: spin 1s linear infinite`:

```
ana@laptop:~/site$ probe keyframes.html at 250 style .spinner rotate at 750 style .spinner rotate
div.spinner  rotate: 90deg
div.spinner  rotate: 270deg
```

At 250 ms it has turned **90 degrees**, at 750 ms **270**: a quarter of a turn every quarter of a second, the even speed of `linear`, and `infinite` repeats it for ever. `alternate` as a direction would make each repetition run backwards after the forwards one, which is how the dots of section 07 went back and forth.

The spinner has `role="status"` and an `aria-label`: the spinning tells a sighted reader that something is loading, and the name tells a screen reader the same thing. Movement alone never carries a message.
