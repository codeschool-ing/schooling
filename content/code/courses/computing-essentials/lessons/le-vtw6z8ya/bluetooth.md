---
title: Bluetooth, and why the same headphones sound worse on a call
version: 1
---

Bluetooth is built around a constraint Wi-Fi does not have: **it has to run for months on a
battery the size of a coin.** Everything odd about it follows from that.

It works in short hops, sleeps between them, and covers about ten metres. It also shares the
`2.4 GHz` band with Wi-Fi, and avoids it by hopping between 79 narrow channels 1 600 times a
second — so it steps around a busy Wi-Fi channel rather than fighting it.

## Profiles, which is the answer to the question in the title

A Bluetooth device does not have one connection. It has **profiles**, and each one is a separate
agreement about what is being sent. The two that matter for headphones:

- **`A2DP`** — one-way stereo audio, good quality. What you get when you are listening.
- **`HFP`** or **`HSP`** — two-way audio for a telephone call. One channel, and a fraction of the
  bandwidth, because the same radio now has to carry the microphone as well.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two bars of very different lengths. The upper one, labelled A2DP, fills most of the width and is described as stereo at 44 kilohertz. The lower one, labelled HFP, is about a fifth as long and is described as one channel at 8 or 16 kilohertz. A note says the headphones and the distance are the same and only the profile changed.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">What opening the microphone costs the music</text><text x=\"24\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the headphones are doing</text><text x=\"200\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">how much sound gets through</text><text x=\"24\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">just listening</text><rect x=\"200\" y=\"70\" width=\"480\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A2DP</text><text x=\"664\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">stereo, and the whole of the sound</text><text x=\"24\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">on a call</text><rect x=\"200\" y=\"150\" width=\"96\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HFP</text><text x=\"320\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one channel, and a fifth of the detail</text><text x=\"24\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The same headphones, at the same distance. Only the profile changed, and the music changed with it.</text></svg>", "caption": "Nothing is broken when this happens. The radio is carrying a microphone now, and the music is paying for it."}
```

So: music sounds excellent, a call starts, **and the music playing in the background of that call
instantly sounds like a telephone**. The headphones did not fail, and there is nothing to fix.
The only workaround is to keep the microphone somewhere else — a separate one, or the machine's
own.

## Codecs, honestly

`SBC` is the one every device supports and it is adequate. `AAC`, `aptX` and `LDAC` are better,
and each needs **both ends** to speak it. A phone with `LDAC` and headphones without it fall
back to `SBC` and nothing says so.

The difference is real and smaller than the marketing: it is audible on good headphones in a
quiet room and inaudible on a bus. None of it applies during a call, where the profile has
already taken the bandwidth away.

## Versions, and the one that split in two

`Bluetooth 4.0` introduced **Low Energy**, and it is a different protocol that shares a name. `LE`
carries almost no data and runs for years on a cell: fitness bands, sensors, tags, a keyboard.
Classic Bluetooth carries audio. Most devices do both.

Later versions — `5.0`, `5.2`, `5.3` — mostly extend LE. **`LE Audio` and the `LC3` codec finally
fix the call problem above**, by carrying good two-way audio at low bandwidth. It needs both ends
to support it and it is arriving slowly.

## What actually goes wrong

| symptom | what it usually is |
|---|---|
| it stutters near the computer | the Wi-Fi radio and the Bluetooth radio share one antenna |
| it will not pair | the device is already paired with something else that is on |
| the sound is delayed | normal: 150 to 250 ms, which is why lips do not match |
| it drops in one room | a person or a wall. Bluetooth has no power to spare |

The delay is worth naming because people treat it as a fault. Video players compensate for it
automatically; games generally do not, and that is the one use where a cable still wins outright.
