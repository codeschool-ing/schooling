---
title: The monitor, and the three numbers on the box
version: 1
---

A monitor is sold on one number — the diagonal, in inches — and judged on three others. The
diagonal is the one that tells you least.

## Resolution is how much fits, not how big it is

Resolution is a count of pixels: `1920 × 1080`, `2560 × 1440`, `3840 × 2160`. It says nothing
about the physical size of the panel and everything about how much can be on it at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three rectangles nested at the same top-left corner, drawn to scale against each other. The smallest is 1920 by 1080, the middle one 2560 by 1440, and the largest 3840 by 2160. A column on the right gives the pixel count of each: 2.1 million, 3.7 million and 8.3 million. A note says 4K holds four 1080p screens, not two, and a line at the foot says none of this says how big the screen is.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Three common resolutions, drawn to scale against each other</text><rect x=\"24\" y=\"40\" width=\"384\" height=\"216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"40\" width=\"256\" height=\"144\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"40\" width=\"192\" height=\"108\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1080p</text><text x=\"272\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1440p</text><text x=\"400\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4K</text><text x=\"440\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">how much fits on it</text><text x=\"440\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1920 x 1080</text><text x=\"700\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2.1 million pixels</text><text x=\"440\" y=\"126\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2560 x 1440</text><text x=\"700\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">3.7 million pixels</text><text x=\"440\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3840 x 2160</text><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8.3 million pixels</text><path d=\"M440 188 L700 188\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"440\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4K holds four 1080p screens,</text><text x=\"440\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">not two.</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">None of this says how big the screen is. Size and resolution are two different numbers.</text></svg>", "caption": "Doubling both sides quadruples the pixels, which is why a 4K panel costs a graphics card four times the work of a 1080p one for the same picture."}
```

**Doubling the name doubles each side and so quadruples the work.** That is the sentence to carry
out of the diagram, and it is why the previous lesson's graphics section matters here: the same
game at 4K asks four times as much of the card as it does at 1080p.

## Size and resolution together are the number that actually matters

Divide the pixels by the inches and you get **pixel density**, in pixels per inch. That is what
decides whether text looks sharp.

| panel | resolution | roughly |
|---|---|---|
| 24-inch | `1920 × 1080` | 92 ppi — the ordinary desktop |
| 27-inch | `1920 × 1080` | 82 ppi — visibly coarser, same pixels spread wider |
| 27-inch | `2560 × 1440` | 109 ppi — the sweet spot most people land on |
| 27-inch | `3840 × 2160` | 163 ppi — sharp, and needs scaling to be usable |

The third row of that table is the honest recommendation for a desk, and the fourth is the trap:
at 163 ppi the operating system's menus are physically tiny, so you turn on scaling at 150%, and
you are back to about the working area of the 1440p panel — having paid for 4K and asked four
times as much of the graphics card to display it.

**4K earns its keep on a television across a room and on a laptop held close.** On a 27-inch
monitor at arm's length it is mostly a number.

## Refresh rate, and who it is for

The refresh rate is how many times a second the panel redraws: `60 Hz`, `120 Hz`, `144 Hz`,
`240 Hz`. Above 60 Hz, motion is smoother and the mouse pointer feels attached to your hand.

Be honest about who that is for. It is a real, immediately visible difference for **games and
fast motion**, and close to nothing for reading, writing, spreadsheets and video — a film is 24
frames a second and always has been. If the machine cannot produce more than 60 frames a second
anyway, a 144 Hz panel shows 60 of them.

## Panel type, in one line each

- **IPS** — accurate colour, and the picture does not change when you look from the side. The
  default for almost everybody.
- **VA** — deeper blacks and better contrast, slightly slower to change a pixel. Good for film in
  a dark room.
- **TN** — fast and cheap, colours shift as soon as your head moves. Bought for competitive games
  and regretted for everything else.

## Two words that are not about the panel at all

**Contrast ratio** on a box is usually a "dynamic" figure measured with the backlight turned up
and down between the two measurements, which is not a thing that happens in one picture. Ignore
anything over about 3000:1.

**Response time** in milliseconds is measured differently by every manufacturer, sometimes
between two shades of grey chosen to flatter. It is the least comparable number on the box.
