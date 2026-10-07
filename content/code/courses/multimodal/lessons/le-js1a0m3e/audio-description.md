---
title: Audio description in the pauses
version: 2
---

Standard audio description, criterion 1.2.5, speaks in the pauses of the soundtrack without changing the video's length. So it is three questions: what to say, where the pauses are, and whether the words fit.

```schooling-example
{
  "language": "python",
  "file": "describe.py",
  "parts": [
    {
      "code": "\"\"\"Audio description: speak what is shown and not said, in the pauses of the narration, if it fits.\"\"\"\nimport subprocess\n\nimport mmlab\nimport soundfile\n\n"
    },
    {
      "code": "# Written by the course, as a describer would write them: short, and only what the narration leaves out.\nDESCRIPTIONS = [(11.64, \"Reasons: damaged, wrong book, changed my mind.\"),\n                (20.72, \"Code: RETURN30.\"),\n                (26.44, \"The label is valid for seven days.\")]\n\n",
      "note": "**The descriptions, written by a person** (here, by the course): when each thing appears on screen, and the fewest words that say it. Writing them is the describer's craft, and nothing below replaces it."
    },
    {
      "code": "speech = mmlab.speech_segments(mmlab.read_audio(\"media/returns.mp4\"))\ngaps = [(a[1], b[0]) for a, b in zip(speech, speech[1:])] + [(speech[-1][1], 32.6)]\ntts = mmlab.piper(\"en_US-lessac-medium\")\n\n",
      "note": "**Where the narration is silent**: lesson 5's speech detector over the video's sound, and the pauses between its segments, plus the tail after the last one."
    },
    {
      "code": "inputs, filters = [], []\nfor shown, text in DESCRIPTIONS:\n",
      "note": "**One voice for every description**, lesson 6's Piper voice, so they sound like one describer."
    },
    {
      "code": "    gap = next((g for g in gaps if g[1] > shown), None)            # the first pause that ends after it appears\n",
      "note": "**The pause that belongs to a description** is the first one that ends after the thing appears."
    },
    {
      "code": "    audio = tts.generate(text, sid=0, speed=1.0)\n    seconds = len(audio.samples) / audio.sample_rate\n    fits = gap[1] - gap[0] >= seconds + 0.2                      # a tenth of a second of air either side\n    print(\"%5.2f  %-48s %.2f s into a %.2f s pause at %.2f: %s\" % (shown, text, seconds, gap[1] - gap[0], gap[0],\n                                                                 \"fits\" if fits else \"does NOT fit\"))\n",
      "note": "**Speak it, measure it, and compare** with the pause, keeping a tenth of a second clear at each end so the description does not touch the narration."
    },
    {
      "code": "    if fits:\n        name = f\"ad{len(inputs)}.wav\"\n        soundfile.write(name, audio.samples, audio.sample_rate)\n        filters.append(f\"[{len(inputs) + 1}]adelay={int((gap[0] + 0.1) * 1000)}:all=1[d{len(inputs)}]\")\n        inputs.append(name)\n\n",
      "note": "**A description that fits is kept**, written to a file and given a delay that starts it a tenth of a second into its pause."
    },
    {
      "code": "mix = \";\".join(filters) + \";[0]\" + \"\".join(f\"[d{i}]\" for i in range(len(inputs))) + \\\n      f\"amix=inputs={len(inputs) + 1}:normalize=0\"\nsubprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-i\", \"media/returns.mp4\",\n                *sum(([\"-i\", n] for n in inputs), []), \"-filter_complex\", mix, \"-ac\", \"1\", \"described.wav\"], check=True)\nprint(\"described.wav:\", len(inputs), \"of\", len(DESCRIPTIONS), \"descriptions mixed in\")",
      "note": "**ffmpeg mixes the narration and the delayed descriptions** into one track. `normalize=0` keeps every input at its own volume; amix would otherwise lower each one."
    }
  ]
}
```

```
ana@lab:~/mm$ python describe.py
11.64  Reasons: damaged, wrong book, changed my mind.   2.82 s into a 1.15 s pause at 10.89: does NOT fit
20.72  Code: RETURN30.                                  1.45 s into a 1.82 s pause at 20.01: fits
26.44  The label is valid for seven days.               1.99 s into a 1.18 s pause at 25.70: does NOT fit
described.wav: 1 of 3 descriptions mixed in
ana@lab:~/mm$ python -c "from openai import OpenAI; print(OpenAI(base_url=\"http://localhost:8700/v1\").audio.transcriptions.create(model=\"whisper-base\", file=open(\"described.wav\", \"rb\"), response_format=\"text\"))" | cut -c1-400
Here is how to return a book you bought from Marginelia. It takes four steps and the label is free. First, sign and end open the order the book came in. You will find it under account then orders. Second, press return this item and choose a reason from the list. 3. Print the prepared label we send you by email and tape it over the old address. Code, return 30, 4. Drop the parcel at any post office
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of the 32.6-second returns video. The top row is its seven slides; the fifth, the RETURN30 card, is 0.4 seconds wide. The middle row is the narration: six stretches of speech with pauses of about 1.2 seconds between them, and one of 1.8 seconds around the card. The bottom row is the three descriptions, each drawn at its pause with its own length: 2.82 seconds for the reasons, which overflows a 1.15-second pause; 1.45 seconds for the code, which fits the 1.82-second pause; and 1.99 seconds for the label&#x27;s validity, which overflows a 1.18-second pause.\"><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">slides</text><rect x=\"41\" y=\"30\" width=\"116.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"159.4\" y=\"30\" width=\"112.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164.4\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"273.8\" y=\"30\" width=\"78.80000000000001\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"278.8\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"354.6\" y=\"30\" width=\"98.79999999999995\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"359.6\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"455.4\" y=\"30\" width=\"6.000000000000057\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"463.40000000000003\" y=\"30\" width=\"104.40000000000003\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468.40000000000003\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"569.8000000000001\" y=\"30\" width=\"121.19999999999993\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574.8000000000001\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"40\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">narration</text><rect x=\"48.4\" y=\"90\" width=\"95.4\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"166.8\" y=\"90\" width=\"91.0\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"280.79999999999995\" y=\"90\" width=\"58.80000000000007\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"362.0\" y=\"90\" width=\"78.20000000000005\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"476.59999999999997\" y=\"90\" width=\"77.40000000000003\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"577.8\" y=\"90\" width=\"100.40000000000009\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">descriptions, drawn at their pause</text><rect x=\"259.8\" y=\"154\" width=\"56.4\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"259.8\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2.82 s</text><rect x=\"442.20000000000005\" y=\"154\" width=\"29.0\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.20000000000005\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1.45 s</text><rect x=\"556.0\" y=\"154\" width=\"39.8\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"556.0\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1.99 s</text><text x=\"40\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"656.0\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32.6 s</text></svg>", "caption": "One description fits a pause; the other two are longer than the silence the narration leaves."}
```

**One of the three fits.** The narration leaves pauses of about 1.2 seconds between its sentences, and the reasons need 2.82 seconds even in seven words. The card is the exception: its pause is 1.82 seconds, because the card itself sits in a gap of the narration, and "Code: RETURN30" takes 1.45. The last line of the capture is Whisper listening to the described track: "Code, return 30" is now part of what the video says.

The other two have three ways out, and each is a decision rather than a computation:

- **Say less.** "Seven-day label" might fit 1.18 seconds where "The label is valid for seven days" does not; the describer decides whether it still says enough.
- **Extended description**, criterion 1.2.7 at AAA: the player pauses the video while the description is spoken. On a web player that is a feature to build, not a file to mix.
- **Change the video.** The cheapest fix is upstream: a narration that reads the reasons and the deadline aloud needs no description for them. For a video the shop makes itself, that is the fix to prefer, and it is the same reasoning as the last section's: **the script is where the words belong**.

Nothing in WCAG asks for a human voice, and a synthetic one changes on every edit at no cost. What it cannot do is decide what to describe, which is why `DESCRIPTIONS` is written by a person at the top of the program.
