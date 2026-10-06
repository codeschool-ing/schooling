---
title: The 25 MB limit, and long recordings
version: 1
---

OpenAI documents a limit of **25 MB per uploaded file** for transcription, and accepts a list of formats: `flac`, `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `ogg`, `wav` and `webm`. labmm enforces both. Half an hour of the lab's call, made by joining 32 copies end to end, shows why the limit matters in practice:

```python
"""An hour-long recording is too big to upload whole; cut it at silences and send the pieces."""
import subprocess
import sys

from openai import OpenAI, APIStatusError

LIMIT = 25 * 1024 * 1024
src = sys.argv[1]
size = int(subprocess.run(["stat", "-c", "%s", src], capture_output=True, text=True).stdout)
print(f"{src}: {size:,} bytes, the limit is {LIMIT:,}")
client = OpenAI()
try:
    with open(src, "rb") as audio:
        client.audio.transcriptions.create(model="lab-whisper-tiny", file=audio)
except APIStatusError as e:
    print(f"whole file: {e.status_code} {e.body['message'] if isinstance(e.body, dict) else e.body}")
```

```
ana@lab:~/mm$ for i in $(seq 32); do echo "file '$PWD/media/call-1042.wav'"; done > /tmp/list.txt && ffmpeg -nostdin -loglevel error -y -f concat -safe 0 -i /tmp/list.txt -c copy long.wav && ffprobe -v error -show_entries format=duration -of csv=p=0 long.wav
1772.272000
ana@lab:~/mm$ python long.py long.wav
long.wav: 56,712,782 bytes, the limit is 26,214,400
whole file: 413 Maximum content size limit (26214400) exceeded (56713055 bytes read)
ana@lab:~/mm$ ffmpeg -nostdin -loglevel error -y -i long.wav -ac 1 -ar 16000 -b:a 32k long.mp3 && stat -c "%s %n" long.mp3
7089633 long.mp3
```

**29.5 minutes of 16 kHz WAV is 56.7 MB**, more than twice the limit, and the upload is refused with a 413 before any audio is heard. The same audio as MP3 at 32 kbit/s is 7.1 MB, under the limit with room to spare. So the first fix for a too-large file is the one lesson 6 measured: **send compressed audio, at the sample rate the model uses**. Speech at 16 kHz mono loses nothing a transcriber needs in a 32 kbit/s MP3 or Opus file.

The second fix covers recordings that are too long even compressed (a three-hour meeting), and it is better than a large single upload anyway: **cut at silences, send the pieces, and put the times back together**.

```schooling-example
{
  "language": "python",
  "file": "pieces.py",
  "parts": [
    {
      "code": "\"\"\"Transcribe a long recording in pieces cut at silences, and put the times back together.\"\"\"\nimport subprocess\nimport sys\n\nfrom openai import OpenAI\n\nimport mmlab\n\n"
    },
    {
      "code": "src, LIMIT = sys.argv[1], 600.0                    # pieces of at most ten minutes\nsamples = mmlab.read_audio(src)\ncuts, start, last = [], 0.0, 0.0\nfor s, e in mmlab.speech_segments(samples):\n    if e - start > LIMIT and last > start:\n        cuts.append((start, (last + s) / 2))\n        start = (last + s) / 2\n    last = e\ncuts.append((start, len(samples) / mmlab.RATE))\n\n",
      "note": "**Plan the cuts before sending anything**: pieces of at most ten minutes, each ending in the middle of a silence the speech detector found, as lesson 5's `chunks.py` did for 30 seconds."
    },
    {
      "code": "client = OpenAI()\nsegments = []\n",
      "note": "**One list for the whole file's segments.**"
    },
    {
      "code": "for i, (a, b) in enumerate(cuts):\n    piece = f\"/tmp/piece-{i}.mp3\"\n    subprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-ss\", str(a), \"-to\", str(b), \"-i\", src,\n                    \"-ac\", \"1\", \"-ar\", \"16000\", \"-b:a\", \"32k\", piece], check=True)\n    with open(piece, \"rb\") as audio:\n        r = client.audio.transcriptions.create(model=\"lab-whisper-tiny\", file=audio, language=\"en\",\n                                               response_format=\"verbose_json\")\n",
      "note": "**Each piece is cut by ffmpeg and compressed to MP3 at 32 kbit/s**, which is why a ten-minute piece weighs about 2.4 MB rather than 19, and sent on its own as `verbose_json`, so it comes back with segment times."
    },
    {
      "code": "    segments += [(a + s.start, a + s.end, s.text) for s in r.segments]   # the piece's times, moved to the file's\n",
      "note": "**The line that is easy to forget.** A piece's segments are timed from the start of the piece; adding the piece's own start puts them back on the file's clock."
    },
    {
      "code": "    size = subprocess.run([\"stat\", \"-c\", \"%s\", piece], capture_output=True, text=True).stdout.strip()\n    print(f\"piece {i}: {a:7.1f} to {b:7.1f} s, {int(size):,} bytes, {len(r.segments)} segments\")\nprint(f\"{len(segments)} segments; the last: {segments[-1][0]:.1f}-{segments[-1][1]:.1f} s {segments[-1][2]!r}\")",
      "note": "**What was sent and what came back**, piece by piece, and the last segment of all as a check that the times reach the end of the file."
    }
  ]
}
```

```
ana@lab:~/mm$ python pieces.py long.wav
piece 0:     0.0 to   595.5 s, 2,382,417 bytes, 120 segments
piece 1:   595.5 to  1192.7 s, 2,389,329 bytes, 122 segments
piece 2:  1192.7 to  1772.3 s, 2,319,057 bytes, 116 segments
358 segments; the last: 1769.1-1772.2 s 'Thank you for calling marginalia. Have a good day.'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A 1,772-second recording drawn as a long bar, cut at silences into three pieces: 0 to 595.5 seconds, 595.5 to 1192.7, and 1192.7 to 1772.3. Each piece is sent alone and its segments come back timed from zero. An arrow shows a segment at 3.0 seconds in piece 2 being moved to 1195.7 seconds in the file, by adding the piece&#x27;s start.\"><defs><marker id=\"l10pcs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">long.wav, 56.7 MB: over the 25 MB limit</text><rect x=\"30.0\" y=\"34\" width=\"217.76268126163743\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140.88134063081873\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">piece 0</text><text x=\"30.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"251.76268126163743\" y=\"34\" width=\"218.39575692602833\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362.9605597246516\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">piece 1</text><text x=\"251.76268126163743\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">595.5</text><rect x=\"474.15843818766575\" y=\"34\" width=\"211.84156181233425\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"582.0792190938329\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">piece 2</text><text x=\"474.15843818766575\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1192.7</text><text x=\"690.0\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1772.3</text><rect x=\"474.15843818766575\" y=\"120\" width=\"200\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"482.15843818766575\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">piece 2, timed from 0</text><text x=\"466.15843818766575\" y=\"135\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3.0 s</text><line x1=\"434.15843818766575\" y1=\"120\" x2=\"475.2756305365909\" y2=\"68\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l10pcs-ah-amber)\"></line><text x=\"30\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A segment's time in the file = the piece's start + its time in the piece: 1192.7 + 3.0 = 1195.7 s.</text></svg>", "caption": "Cut where nobody is speaking, send each piece alone, and move every time back onto the file's clock."}
```

Three pieces of about ten minutes, each around 2.4 MB, 358 segments in all, and the last segment ends at 1,772.2 seconds, the length of the file. **The offset line is the one that is easy to forget**, and forgetting it produces captions that all start in the first ten minutes.

Pieces also make a pipeline more robust: a failed request costs one piece, not the whole recording, and the pieces can be sent at the same time. What they lose is context across a cut, which is what the `prompt` field's "previous piece" use exists to recover, on an endpoint that honours it.
