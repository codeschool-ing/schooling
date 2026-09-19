---
title: Watts, headroom, and the number people get wrong in both directions
version: 1
---

A power supply is rated in watts: `550 W`, `750 W`, `1000 W`. That is the most it can deliver,
not what it draws. A 750 W supply in a machine asking for 200 W draws about 200 W.

Which means the question is not "how big" but "big enough for what".

## Adding it up, roughly

You do not need a spreadsheet. Two numbers dominate and everything else is rounding:

| | typical draw under load |
|---|---|
| processor | 65 W to 125 W |
| graphics card | 75 W to 350 W |
| everything else together | about 50 W |

A machine with no graphics card lands near 150 W. The same machine with a mid-range card lands
near 400 W. **The card is the decision**, exactly as the last section said.

## Headroom, and why more is not safer

Add about 30% and round up. 400 W of components wants a 550 W supply. There are two reasons for
the margin and neither is fear:

- components draw brief spikes far above their average, and a supply at its limit shuts down
  rather than sag;
- a supply is most efficient near half its rating, so sitting at about 70% under load is close
  to the sweet spot.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"A curve of a power supply's efficiency against how much the machine asks of it. It rises steeply from idle, peaks around half the supply's rating, marked most efficient here, and falls away gently towards the full 750 watt rating at the right. A note says a supply is most efficient near half its rating and that a machine spends most of its life near idle.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">How efficient a 750 W supply is, against how much the machine asks of it.</text><path d=\"M60 206 L700 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M60 40 L60 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"380\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">what the machine asks</text><path d=\"M60 206 L124 148 L188 122 L252 106 L316 94 L380 88 L444 90 L508 96 L572 106 L636 120 L700 136\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></path><path d=\"M380 206 L380 88\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><circle cx=\"380\" cy=\"88\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"392\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">most efficient here</text><text x=\"92\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">idle</text><text x=\"600\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">under load</text><text x=\"700\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">its 750 W rating</text><text x=\"60\" y=\"32\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">efficiency</text><text x=\"14\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A supply is most efficient near half its rating, and a machine spends most of its life near idle.</text></svg>", "caption": "Buying twice the wattage you need does not make the machine safer. It moves it to the left of this curve, where the supply is least efficient."}
```

Past that, more watts buy nothing. A 1000 W supply in a 200 W machine is not safer — it spends
its life at 20% load, where it is least efficient, and costs more to buy. **Headroom is a band,
not a direction.**

## And the number to check before any of it

A graphics card manufacturer states a **recommended supply wattage** for exactly this reason,
and it accounts for the spikes. If a card says 650 W, that is the number, and no arithmetic of
yours overrides it.
