---
title: Where HSL lightness lies
version: 1
---

HSL was designed in the 1970s to be easy to compute, not to match the eye. Its "lightness" is the
average of a colour's brightest and dimmest RGB channels, and that average ignores something the eye
cares about a great deal: **the three lights do not look equally bright**. Green looks far brighter
than red, and red far brighter than blue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l11-same-l\" aria-label=\"Six fully saturated colours that HSL says are all at 50% lightness: red, yellow, green, cyan, blue and magenta. Below each, the grey with the same brightness to the eye, and a bar of its relative luminance. Yellow's grey is nearly white and its bar reaches 0.93; blue's grey is nearly black and its bar is 0.07.\"><rect x=\"170.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ff0000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#7f7f7f\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M176.0 248.7 h40.0 v21.3 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"196.0\" y=\"238.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.21</text><rect x=\"238.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ffff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"238.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#f7f7f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M244.0 177.2 h40.0 v92.8 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"264.0\" y=\"167.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.93</text><rect x=\"306.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#00ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#dcdcdc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M312.0 198.5 h40.0 v71.5 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"332.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.72</text><rect x=\"374.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#00ffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"374.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#e5e5e5\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M380.0 191.3 h40.0 v78.7 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"400.0\" y=\"181.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.79</text><rect x=\"442.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#0000ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"442.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#4c4c4c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M448.0 262.8 h40.0 v7.2 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"468.0\" y=\"252.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.07</text><rect x=\"510.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ff00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#919191\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M516.0 241.5 h40.0 v28.5 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"536.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.28</text><path d=\"M160.0 270.0 L580.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"156.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HSL lightness: 50% each</text><text x=\"156.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the grey the eye sees</text><text x=\"156.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">relative luminance</text></svg>", "caption": "HSL calls all six \"50% lightness\". The eye does not agree: yellow is thirteen times as bright as blue. A palette built on HSL lightness is uneven before it starts."}
```

All six colours at the top are fully saturated and have HSL lightness of exactly 50%. The row of greys
beneath shows how bright each one actually looks, and the bars measure it as **relative luminance**,
the weighted sum of the linear red, green and blue that standards such as WCAG use (lesson 14):

```localised
relative luminance = 0.2126 × red + 0.7152 × green + 0.0722 × blue
```

with each channel first converted from the screen's values to linear light. Green carries more than
70% of the weight and blue less than 8%.

So **yellow, at 0.93, is nearly as bright as white, and blue, at 0.07, is nearly as dark as black**,
while the colour picker reports the same 50% for both. The difference is about thirteen times.

## Why it matters for charts

- **A palette chosen by HSL is uneven.** Six categories picked at "the same lightness" will have one or
  two that shout and one or two that disappear. Yellow lines on a white page are the famous case.
- **A ramp built by HSL steps is uneven too.** Equal steps in HSL lightness look like large jumps in
  some places and tiny ones in others, so a sequential palette for a heatmap suggests boundaries the
  data does not have. The next section shows it.
- **Text on a colour needs the real brightness.** Whether white or black text reads on a coloured
  background depends on luminance, not on HSL lightness.

The fix is to choose colours in a space that was built to match perception.
