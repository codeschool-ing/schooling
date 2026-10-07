---
title: The reader's other preferences
version: 1
---

Lesson 10 section 06 answered `prefers-color-scheme`. A reader can say more than that, and media queries can hear it. Two matter for every site.

## Reduced motion

People with vestibular disorders can feel dizzy or sick from things moving on a screen: parallax, a panel that slides in, a page that zooms. Operating systems have a setting to **reduce motion**, and **`prefers-reduced-motion: reduce`** is how a page sees it. The bookshop's notice slides down when the page loads; lesson 12 is about animations, and here only the switch matters:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; padding: 1rem; font-family: system-ui, sans-serif; }

      .notice { animation: drop-in 600ms ease-out; }
      @keyframes drop-in { from { translate: 0 -1rem; opacity: 0; } }

      @media (prefers-reduced-motion: reduce) {
        .notice { animation: none; }
      }

      button { min-height: 2rem; }
      @media (pointer: coarse) {
        button { min-height: 2.75rem; }
      }
    </style>
  </head>
  <body>
    <p class="notice">The shop closes at 5 pm on Saturday.</p>
    <button type="button">Dismiss</button>
  </body>
</html>
```

```
ana@laptop:~/site$ probe prefs.html style .notice animation-name
p.notice  animation-name: drop-in
ana@laptop:~/site$ probe --reduced-motion prefs.html style .notice animation-name
p.notice  animation-name: none
```

Without the setting, the notice runs its animation, `drop-in`. With it, the animation is **none**, and the notice is simply there. WCAG's success criterion 2.3.3, at level AAA, asks for exactly this for motion that is triggered by interaction, and it is a good habit for any decorative motion: keep what moves only when moving tells somebody something, and let everything else stop.

## A finger or a mouse

**`pointer`** describes the reader's main pointing device: `fine` for a mouse or a trackpad, `coarse` for a finger. **`hover`** says whether that device can hover at all. A finger cannot, so anything that only appears on `:hover` is out of reach on a phone:

```
ana@laptop:~/site$ probe prefs.html media "(pointer: coarse)" box button
(pointer: coarse)  does not match
button  x 16     y 68     width 62.66  height 32
ana@laptop:~/site$ probe --mobile --width 390 --height 844 prefs.html media "(pointer: coarse)" box button
(pointer: coarse)  matches
button  x 16     y 68     width 62.66  height 44
```

On the desktop window, `(pointer: coarse)` does not match and the button is **32** tall. With `--mobile`, which makes Chromium a touch screen, it matches and the button is **44**. WCAG 2.2's success criterion 2.5.8 asks for targets of at least 24 by 24 CSS pixels, and Apple's guidelines for a finger ask for 44 points, Android's for 48.

**These features describe a device, not a screen size.** A tablet with a keyboard and trackpad attached reports a fine pointer; a large touch screen on a desk reports a coarse one. Never assume that narrow means touch or that wide means mouse.

## Others worth knowing

`prefers-contrast: more` is set by readers who need stronger contrast. `forced-colors: active` means the operating system is replacing the page's colours with a small palette of its own, as Windows' contrast themes do; borders and outlines survive it, while background colours used as the only sign of something do not. `print`, from section 03, is a preference too: the reader wants paper.
