---
title: Who spoke when
version: 1
---

**Speaker diarization** answers *who spoke when*, without knowing who anybody is. Its output is a list of time spans, each with a label like `speaker_0`; it is your job to decide that `speaker_0` is the shop's agent. It is three models in a row. First *segmentation*: pyannote's model finds where speech changes hands, frame by frame. Then *embedding*: 3D-Speaker's ERes2Net turns each piece of speech into a vector that describes the voice, the way a text embedding describes meaning. Last *clustering*: pieces whose vectors are close enough are put under one label.

The lab scores it the way it scores everything, against who really spoke:

```schooling-example
{
  "language": "python",
  "file": "who.py",
  "parts": [
    {
      "code": "\"\"\"Who spoke when, by pyannote and ERes2Net, scored against who really did.\"\"\"\nimport json\nimport sys\nfrom collections import Counter\n\nimport mmlab\n\n"
    },
    {
      "code": "path, threshold = sys.argv[1], float(sys.argv[2])\nknown = [int(a) for a in sys.argv[3:] if a.isdigit()]   # how many speakers, if somebody knows\nturns = json.load(open(\"media/truth/call-1042.json\"))[\"turns\"]\n",
      "note": "**The settings come from the command line**: the file, the clustering threshold, and, if somebody knows it, how many speakers there are."
    },
    {
      "code": "samples = mmlab.read_audio(path)\nfound = mmlab.diarizer(threshold=threshold, speakers=known[0] if known else -1).process(samples).sort_by_start_time()\nsegments = [(s.start, s.end, f\"speaker_{s.speaker}\") for s in found]\n",
      "note": "**The diarizer runs once over the whole call.** pyannote finds where speech changes hands; ERes2Net turns each piece into a voice embedding; clustering groups the embeddings, and each group gets a label."
    },
    {
      "code": "\n\ndef overlap(a, b, c, d):\n    return max(0.0, min(b, d) - max(a, c))\n\n\nvotes = Counter()  # seconds each found label spent over each real speaker\nfor s, e, label in segments:\n    for t in turns:\n        votes[label, t[\"who\"]] += overlap(s, e, t[\"start\"], t[\"end\"])\n",
      "note": "**How many seconds each label spent over each real speaker.** The labels are `speaker_0`, `speaker_1` and so on: the diarizer knows voices apart, not who they belong to."
    },
    {
      "code": "names = {label: max((\"caio\", \"bia\"), key=lambda w: votes[label, w]) for _, _, label in segments}\nright = sum(v for (label, who), v in votes.items() if names[label] == who)\nspeech = sum(t[\"end\"] - t[\"start\"] for t in turns)\n",
      "note": "**Each label is named after the person it overlaps most**, and the score is the share of all speech that ended up under the right name."
    },
    {
      "code": "print(f\"{path} at {threshold}: {len(names)} speakers found, {len(segments)} segments, \"\n      f\"{right / speech:.1%} of the speech given to the right person\")\n",
      "note": "**The verdict in one line**: how many labels, how many segments, how much speech went to the right person."
    },
    {
      "code": "if \"show\" in sys.argv:\n    for s, e, label in segments:\n        print(f\"  {s:6.2f} {e:6.2f}  {label} -> {names[label]}\")",
      "note": "**And, if asked, every segment** with its label and the name it was given."
    }
  ]
}
```

```
ana@lab:~/mm$ python who.py media/call-1042.wav 0.5 show
media/call-1042.wav at 0.5: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
    0.03   5.33  speaker_0 -> caio
    6.02  11.98  speaker_1 -> bia
   11.98  14.34  speaker_3 -> bia
   14.98  23.93  speaker_0 -> caio
   24.89  29.21  speaker_1 -> bia
   29.98  38.30  speaker_0 -> caio
   39.11  41.34  speaker_1 -> bia
   41.88  49.56  speaker_0 -> caio
   50.30  51.47  speaker_1 -> bia
   52.09  55.25  speaker_0 -> caio
ana@lab:~/mm$ python who.py media/call-1042-noisy.wav 0.5
media/call-1042-noisy.wav at 0.5: 6 speakers found, 10 segments, 98.6% of the speech given to the right person
ana@lab:~/mm$ python who.py call-gtcrn.wav 0.5
call-gtcrn.wav at 0.5: 6 speakers found, 9 segments, 97.6% of the speech given to the right person
ana@lab:~/mm$ python who.py media/call-1042-phone.wav 0.5
media/call-1042-phone.wav at 0.5: 4 speakers found, 9 segments, 97.6% of the speech given to the right person
ana@lab:~/mm$ python who.py media/call-1042-noisy.wav 0.5 2
media/call-1042-noisy.wav at 0.5: 2 speakers found, 9 segments, 98.6% of the speech given to the right person
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three lanes over the 55 seconds of the call. Top, the truth: nine turns alternating between Caio and Bia. Middle, the diarizer on the clean call: ten segments that follow the turns, labelled speaker 0 for every turn of Caio&#x27;s and speaker 1 for Bia&#x27;s, except that the end of her first turn, from 11.98 to 14.34 seconds, is given a third label, speaker 3. Bottom, the speech detector on the noisy call: five long stretches, each running across two or more turns.\"><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">truth</text><rect x=\"150.0\" y=\"24\" width=\"52.756317689530675\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"176.37815884476532\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"209.7057761732852\" y=\"24\" width=\"83.99909747292423\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"251.7053249097473\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"298.6687725631769\" y=\"24\" width=\"89.32039711191334\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.3289711191336\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"396.9241877256318\" y=\"24\" width=\"44.704873646209364\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"419.27662454873644\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"447.58574007220216\" y=\"24\" width=\"82.86732851985573\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"489.01940433213\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"538.3953068592057\" y=\"24\" width=\"23.399819494585017\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550.0952166064982\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"565.7662454873646\" y=\"24\" width=\"76.99007220216617\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"604.2612815884477\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"649.7057761732852\" y=\"24\" width=\"13.025270758122701\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"656.2184115523467\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"667.6949458483755\" y=\"24\" width=\"32.13628158844767\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"683.7630866425993\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">diarizer, clean</text><rect x=\"150.29783393501805\" y=\"74\" width=\"52.61732851985559\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"176.60649819494586\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"209.76534296028882\" y=\"74\" width=\"59.169675090252724\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"239.35018050541518\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"268.93501805054154\" y=\"74\" width=\"23.429602888086606\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"280.64981949458485\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"298.71841155234654\" y=\"74\" width=\"88.85379061371845\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.1453068592058\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"397.10288808664257\" y=\"74\" width=\"42.88808664259932\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"418.5469314079422\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"447.63537906137185\" y=\"74\" width=\"82.59927797833939\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"488.93501805054154\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"538.2761732851986\" y=\"74\" width=\"22.138989169675142\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"549.3456678700362\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"565.7761732851986\" y=\"74\" width=\"76.24548736462089\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"603.8989169675091\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"649.3682310469314\" y=\"74\" width=\"11.615523465703973\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"655.1759927797834\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"667.1389891696751\" y=\"74\" width=\"31.37184115523462\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"682.8249097472924\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"281.0469314079422\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">speaker 3</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VAD, noisy</text><rect x=\"153.27617328519855\" y=\"134\" width=\"141.9675090252708\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"299.0162454873646\" y=\"134\" width=\"207.39169675090255\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"509.3862815884477\" y=\"134\" width=\"26.70577617328513\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"538.8718411552347\" y=\"134\" width=\"108.41155234657037\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"650.0631768953069\" y=\"134\" width=\"49.53971119133564\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"150.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"249.27797833935017\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><text x=\"348.55595667870034\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><text x=\"447.83393501805057\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><text x=\"547.1119133574007\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40 s</text><text x=\"646.389891696751\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 s</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C is Caio and B is Bia; a number is the label the diarizer gave.</text></svg>", "caption": "On the clean call the diarizer's boundaries are within a tenth of a second of the truth; on the noisy one the speech detector cannot find the gaps at all."}
```

On the clean call **98.1% of the speech went to the right person**, and every boundary is within about a tenth of a second of the truth. But the diarizer found **three speakers in a two-person call**: the end of Bia's first turn, from 11.98 to 14.34 seconds, became `speaker_3`. The voice did not change; the pyannote model cut her turn in two and the embedding of the second half landed just far enough from the first. That is the most common failure of diarization: **too many speakers**, each extra one a fragment of a real one.

Noise made it worse at counting and no worse at timing. On the noisy call it found six speakers, after GTCRN six, on the phone line four, and in every case 97.6% or more of the speech still went to the right person, because the extra labels covered short fragments. The last command tells the diarizer there are two speakers, and it finds exactly two.

## The threshold, and the number you may already know

```
ana@lab:~/mm$ for t in 0.3 0.5 0.7 0.9; do python who.py media/call-1042.wav $t; done
media/call-1042.wav at 0.3: 6 speakers found, 11 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.5: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.7: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.9: 2 speakers found, 9 segments, 98.1% of the speech given to the right person
```

The clustering **threshold** is how far apart two voice vectors may be and still count as one person. Raising it merges more: at 0.3 six speakers, at 0.9 the correct two. The score barely moves, because the extra speakers in this call are short fragments, but a transcript labelled with six people for a two-person call is wrong in a way every reader notices.

**When the number of speakers is known, give it to the model.** A support call has two people; a meeting has the attendees on the invitation. With `speakers=2` the clustering no longer guesses how many groups there are, it only decides which piece goes where, and that is the easier half of the problem. On the noisy call it found exactly two, with 98.6% of the speech correctly given.

And remember the cheapest diarization of all from section 02: **two channels, one per person**. A call recorded that way needs none of this.
