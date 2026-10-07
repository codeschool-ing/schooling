---
title: What changes when the model can see and hear
version: 2
---

**A multimodal model is not a different kind of intelligence. It is a model whose inputs and outputs are not only text.** That is the whole definition, and it is worth holding on to, because most of what goes wrong in multimodal products comes from forgetting it. The model still predicts; it still has a window; it still charges by what it reads and writes. What changes is the size and the shape of what goes in.

A **modality** is a kind of data: text, image, audio, video. A model is described by which modalities it takes in and which it gives back. Whisper takes audio and gives text. An image generator takes text and gives an image. A vision model takes text and images and gives text. A native audio model takes audio and gives audio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four kinds of input on the left, text, image, audio and video, each with an arrow into one box in the middle labelled model. Three kinds of output on the right, text, image and audio. Under each arrow on the left is what the input becomes before the model reads it: tokens, tiles or patches, frames of sound, and sampled pictures plus a soundtrack.\"><defs><marker id=\"l01dir-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01dir-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"29.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text</text><text x=\"30\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tokens</text><line x1=\"192\" y1=\"37\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"72\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">image</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tiles or patches</text><line x1=\"192\" y1=\"95\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"130\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">audio</text><text x=\"30\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frames of sound</text><line x1=\"192\" y1=\"153\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"188\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">video</text><text x=\"30\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pictures + soundtrack</text><line x1=\"192\" y1=\"211\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"302\" y=\"95\" width=\"116\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">model</text><text x=\"312\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one call</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"65\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"45\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"105\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">image</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"165\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">audio</text></svg>", "caption": "Every modality is turned into something the model counts before it reads it, and the cost follows the count."}
```

## Everything becomes something counted

A language model reads tokens. Before an image reaches a vision model it is resized and cut into tiles or small square patches, and each one costs tokens. In lesson 8 you will count them: one rule charges 765 tokens for the cover of a paperback, and the same rule charges 85 if you ask for the low-detail version. Audio is cut into short frames of sound; Whisper listens in windows of 30 seconds. A video is pictures sampled from it plus its soundtrack, and how many pictures you sample is a decision you make, with a cost attached (lesson 4).

So the first thing that changes is **the size of an input**. Here is the course's media, the files every lesson works on, listed by a short program. You build the machine and the media in sections 07 and 08 of this lesson; until then, read the transcripts, and run them afterwards.

`inventory.py`:

```python
"""What is in ~/mm/media: one line per file, and what a model would be handed."""
import json
import os
import subprocess

for name in sorted(os.listdir("media")):
    path = os.path.join("media", name)
    if not os.path.isfile(path):
        continue
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", path],
                           capture_output=True, text=True, check=True)
    info = json.loads(probe.stdout)
    kinds, timed = [], False
    for s in info["streams"]:
        if s["codec_type"] == "video" and s["codec_name"] in ("png", "mjpeg"):
            kinds.append(f"image {s['width']}x{s['height']}")
        elif s["codec_type"] == "video":
            kinds.append(f"video {s['width']}x{s['height']} {s['codec_name']}")
            timed = True
        elif s["codec_type"] == "audio":
            kinds.append(f"audio {s['sample_rate']} Hz {s['codec_name']}")
            timed = True
    seconds = f"{float(info['format']['duration']):6.1f} s" if timed else "       -"
    print(f"{name:22} {os.path.getsize(path):>10,} B {seconds}  " + " + ".join(kinds))
```

```
ana@lab:~/mm$ python inventory.py
call-1042-noisy.wav     1,772,316 B   55.4 s  audio 16000 Hz pcm_s16le
call-1042-phone.wav       443,126 B   55.4 s  audio 8000 Hz pcm_mulaw
call-1042.wav           1,772,316 B   55.4 s  audio 16000 Hz pcm_s16le
cat_and_dog.jpg            69,041 B        -  image 640x416
cover-b39.png              19,605 B        -  image 600x900
invoice-0931-scan.jpg      95,891 B        -  image 827x1170
invoice-0931.png           87,530 B        -  image 1240x1754
returns.mp4               495,585 B   32.6 s  video 1280x720 h264 + audio 44100 Hz aac
voicemail-pt.wav          399,120 B   12.5 s  audio 16000 Hz pcm_s16le
```

Fifty-five seconds of a phone call is 1,772,316 bytes as it was recorded, and the same call through a telephone line, at 8000 samples a second, is a quarter of that. A whole page of invoice is under 100 kilobytes. None of these is large for a disk, and all of them are large for a model. A page of plain text is a few hundred tokens.

## Three other things change with it

**The answer is harder to check.** When a model summarises a text, you can read the text. When it says what an invoice says, or what a caller said, the truth is in a picture or a recording, and checking it means looking or listening yourself. Most of this course is about measuring a model against a known truth, and the lab was built so that the truth is known: every recording was spoken from a script, and every picture was drawn from a specification.

**Errors look like content.** A transcript with a wrong word reads as fluently as one without. Whisper hears the name *Caio* in the lab's call and writes *Kau*, with no mark of doubt beside it.

**The data is more personal.** A photograph has faces in it, a recording has a voice, and a document has a name and an address. Lesson 8 strips the metadata out of a picture before it leaves the machine, and the reasons are in the section on when not to use any of this.
