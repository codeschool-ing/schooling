---
title: Contrast, computed
version: 1
---

Most accessibility defects are a yes or a no: the image has a text alternative or it does not.
Contrast is a number, and **the number is computed from the two colours, never judged by eye**. A
designer's monitor, the room's light and the tester's own eyes all change what looks readable;
the ratio does not change. It is also the commonest failure there is. WebAIM's yearly survey of
the home pages of the million most visited sites has found low-contrast text on most of them,
year after year, and it is the defect lesson 13's tool reports first.

## The formula, as a program

WCAG defines the ratio in two steps, and twenty lines of Python are enough to hold both. Make the
directory lesson 13 uses, and open the file:

```sh
mkdir -p ~/a11y && cd ~/a11y
nano contrast.py
```

```schooling-example
{"language": "python", "file": "a11y/contrast.py", "parts": [{"code": "# a11y/contrast.py\n# The contrast ratio between two colours, the way WCAG 2.2 defines it.\n#   python3 contrast.py 999999 ffffff\nimport sys", "note": "A directory of its own, `~/a11y`, which lesson 13 turns into a Playwright project. Two colours go in as hex, with or without the `#`."}, {"code": "\ndef luminance(colour):\n    channels = [int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4)]\n    r, g, b = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4\n               for c in channels]\n    return 0.2126 * r + 0.7152 * g + 0.0722 * b", "note": "**Relative luminance** is how bright a colour looks, from 0 for black to 1 for white. Each channel is turned from the screen's encoding back into light, then weighted: green counts ten times as much as blue, because the eye is that much more sensitive to it. The constants are the ones WCAG 2.2 gives in its definition."}, {"code": "\ndef ratio(first, second):\n    light, dark = sorted((luminance(first), luminance(second)), reverse=True)\n    return (light + 0.05) / (dark + 0.05)", "note": "**The ratio** is the lighter luminance plus 0.05 over the darker plus 0.05. The 0.05 stands for the light a real screen reflects, and it is why black on white is 21:1 and not infinite. The order of the arguments does not matter."}, {"code": "\ntext, background = sys.argv[1].lstrip(\"#\"), sys.argv[2].lstrip(\"#\")\nr = ratio(text, background)\nmarks = [f\"{name} {'yes' if r >= need else 'no'}\"\n         for name, need in ((\"AA text\", 4.5), (\"AA large\", 3), (\"AAA text\", 7))]\nprint(f\"#{text} on #{background}: {r:.2f}:1   \" + \", \".join(marks))", "note": "Three thresholds, from three criteria: 4.5:1 for text at AA (1.4.3), 3:1 for large text at AA, which is also what 1.4.11 asks of the parts of a control, and 7:1 for text at AAA (1.4.6)."}]}
```

Run it on the colours `book.html` uses: the grey note, a replacement for it, the white text of
the Book control on its dark red, the red of the error border, and the body text.

```
ana@nft:~/a11y$ python3 contrast.py 999999 ffffff
#999999 on #ffffff: 2.85:1   AA text no, AA large no, AAA text no
ana@nft:~/a11y$ python3 contrast.py 767676 ffffff
#767676 on #ffffff: 4.54:1   AA text yes, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py 777777 ffffff
#777777 on #ffffff: 4.48:1   AA text no, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py ffffff 7a1f2b
#ffffff on #7a1f2b: 10.20:1   AA text yes, AA large yes, AAA text yes
ana@nft:~/a11y$ python3 contrast.py dd0000 ffffff
#dd0000 on #ffffff: 5.15:1   AA text yes, AA large yes, AAA text no
ana@nft:~/a11y$ python3 contrast.py 222222 ffffff
#222222 on #ffffff: 15.91:1   AA text yes, AA large yes, AAA text yes
```

**The note fails at 2.85:1**, well under the 4.5:1 that 1.4.3 asks for, and it would fail even if
it were large text. `#767676` is the lightest grey that passes on white, at 4.54:1: one step
lighter, `#777777`, is 4.48:1 and fails. It is not close to AAA's 7:1, which is the trade a
designer makes on purpose or not at all. The Book control's white on dark red is 10.20:1 and the
body text is 15.91:1, both comfortably over every line.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-contrast\" aria-label=\"A contrast scale from 1:1 to 21:1, drawn on a logarithmic axis, with three thresholds: 3:1 for large text and for the parts of controls, 4.5:1 for text at AA, 7:1 for text at AAA. The colours of the booking page sit on it: the grey note #999999 at 2.85, below every line; #777777 at 4.48, just under AA; #767676 at 4.54, just over it; the red border at 5.15; white on the dark red button at 10.20; the body text at 15.91.\"><path d=\"M50.0 150.0 L680.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50.0 146.0 L50.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"50.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1:1</text><path d=\"M193.4 146.0 L193.4 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"193.4\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2:1</text><path d=\"M277.3 146.0 L277.3 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"277.3\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3:1</text><path d=\"M361.2 146.0 L361.2 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"361.2\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.5:1</text><path d=\"M452.7 146.0 L452.7 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"452.7\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7:1</text><path d=\"M526.5 146.0 L526.5 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"526.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:1</text><path d=\"M680.0 146.0 L680.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:1</text><path d=\"M277.3 40.0 L277.3 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"277.3\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AA large · non-text</text><path d=\"M361.2 40.0 L361.2 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"361.2\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">AA text</text><path d=\"M452.7 40.0 L452.7 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"452.7\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AAA text</text><circle cx=\"266.7\" cy=\"150.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M266.7 144.0 L266.7 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"266.7\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#999</text><circle cx=\"360.3\" cy=\"150.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M360.3 144.0 L360.3 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"356.3\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#777</text><circle cx=\"363.1\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M363.1 144.0 L363.1 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"363.1\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#767676</text><circle cx=\"389.2\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M389.2 144.0 L389.2 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"389.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">red border</text><circle cx=\"530.6\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M530.6 144.0 L530.6 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"530.6\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Book button</text><circle cx=\"622.6\" cy=\"150.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M622.6 144.0 L622.6 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"622.6\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">body text</text><text x=\"360.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2.85 fails at every level; one step of grey separates 4.48 from 4.54</text></svg>", "caption": "The booking page's colours on the contrast scale. Only the grey note falls under the lines that matter for it."}
```

## Large text, and what is not text

**Large text** in WCAG is at least 18 point, or 14 point when bold, which in CSS is about 24 and
18.7 pixels. It gets the lower threshold, 3:1, because thicker strokes stay readable at lower
contrast. The note in `book.html` is 16 pixels and normal weight, so it is ordinary text.

*1.4.11 Non-text Contrast*, from WCAG 2.1, asks 3:1 of what is not text: the border of an input,
the ring of focus, an icon that carries meaning. The red border of defect 8 is 5.15:1 against
white and passes it. **That is worth noticing, because defect 8 is still a defect**: the border is
easy to see, and it is still only a colour. Contrast and use of colour are two different
criteria, and passing one says nothing about the other.

## Where a tool helps and where it stops

Measuring contrast is the most automatable check in WCAG, and lesson 13's tool does it for every
element on the page. It works out the colours the browser actually drew, which is harder than it
sounds: text over a gradient or a photograph has no single background colour, and there the tool
says it cannot decide rather than guessing. For those, and for colours in a design file that is
not a page yet, a program like this one, or the colour picker in a browser's developer tools, is
how the number gets found.
