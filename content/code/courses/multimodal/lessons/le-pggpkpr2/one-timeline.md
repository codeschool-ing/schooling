---
title: Putting both streams on one timeline
version: 1
---

Frames and words are only useful together, and the clock they share is what joins them. The program below takes the scenes from the detector, reads the title of each one, and puts beside it whatever was said while it was on screen:

```schooling-example
{
  "language": "python",
  "file": "timeline.py",
  "parts": [
    {
      "code": "\"\"\"One timeline from both streams: what was on screen, and what was said while it was.\"\"\"\nimport json\nimport subprocess\n\nfrom frames import sample, title\n\n"
    },
    {
      "code": "VIDEO, LENGTH = \"media/returns.mp4\", 32.6\nsaid = json.load(open(\"said.json\"))\n",
      "note": "**The soundtrack's segments**, as `soundtrack.py` saved them: a start, an end and the words."
    },
    {
      "code": "cuts = sample(VIDEO, \"scene > 0.03\", \"/tmp/scenes\")\nsubprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-i\", VIDEO, \"-frames:v\", \"1\", \"/tmp/scenes/000.png\"])\nscenes = [(0.0, \"/tmp/scenes/000.png\")] + cuts\n\n",
      "note": "**The scenes**: the cuts the detector found at 0.03, plus the very first frame, which no cut precedes."
    },
    {
      "code": "timeline = []\nfor (start, png), end in zip(scenes, [t for t, _ in cuts] + [LENGTH]):\n",
      "note": "**One entry per scene**, from its cut to the next one, or to the end of the video."
    },
    {
      "code": "    words = \" \".join(s[\"text\"] for s in said if start <= (s[\"start\"] + s[\"end\"]) / 2 < end)\n",
      "note": "**A piece of speech belongs to the scene its middle falls in.** Speech runs across cuts, and some rule has to decide; this one is simple and says so."
    },
    {
      "code": "    timeline.append({\"from\": start, \"to\": end, \"shown\": title(png), \"said\": words})\n    print(f\"{start:6.2f}-{end:5.2f}  shown: {timeline[-1]['shown']}\")\n    print(f\"{'':12}  said:  {words or '(nothing)'}\")\njson.dump(timeline, open(\"timeline.json\", \"w\"), indent=1)",
      "note": "**What was shown, read by Tesseract from the scene's frame, and what was said**, side by side, printed and saved."
    }
  ]
}
```

```
ana@lab:~/mm$ python timeline.py
  0.00- 5.92  shown: Returning a book to Marginalia
              said:  Here is how to return a book you bought from Marginelia. It takes four steps and the label is free.
  5.92-11.64  shown: 1. Open the order
              said:  First, sign and end open the order the book came in. You will find it under account then orders.
 11.64-15.68  shown: 2. Choose a reason
              said:  Second, press return this item and choose a reason from the list.
 15.68-20.72  shown: 3. Print the label
              said:  Third, print the prepared label we send you by email and tape it over the old address.
 20.72-21.12  shown: Code: RETURN3O
              said:  (nothing)
 21.12-26.44  shown: 4. Drop it off
              said:  Drop the parcel at any post office and keep the receipt until your refund arrives.
 26.44-32.60  shown: Refunds
              said:  Refunds go back to the card you paid with, a damage to book as refunded and full, shipping included.
```

This is the most compact faithful version of the video: seven entries, each with what was shown and what was said. Two things in it are worth noticing.

**Each stream catches what the other misses.** The card at 20.72 has a title and no speech. The refund slide's speech says *refunds go back to the card you paid with*, which is on no slide. A summary built from either stream alone would lose something the shop wanted customers to know.

**Both models made mistakes, and the timeline keeps them.** OCR read the card as `Code: RETURN3O`, with a letter O where the slide has a zero; Whisper's *damage to book as refunded and full* is still there. A timeline does not correct its sources. What it does is keep each error next to the other stream's version of the same moment, where a person or a later model can see that the slide says *Damaged books: refunded in full* and the speech says something garbled.

That is also why the timeline keeps times rather than just text: an error found later can be checked by jumping to the second it happened at.
