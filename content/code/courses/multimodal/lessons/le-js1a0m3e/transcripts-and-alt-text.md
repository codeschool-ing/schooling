---
title: Transcripts with speakers, and alt text a machine can check
version: 1
---

A recording with no video, such as a support call kept for training, needs a **transcript** under criterion 1.2.1. For a call, a transcript that does not say who is speaking is hard to follow, so this one joins lesson 5's diarization to Whisper's segments: each segment goes to the speaker who overlaps it most.

```python
"""A transcript of the call for someone who cannot hear it: who spoke, when, and what Whisper heard."""
from mmlab import diarizer, read_audio
from openai import OpenAI

turns = diarizer(speakers=2).process(read_audio("media/call-1042.wav")).sort_by_start_time()
with open("media/call-1042.wav", "rb") as f:
    heard = OpenAI().audio.transcriptions.create(model="lab-whisper-base", file=f, response_format="verbose_json")


def speaker(start, end):
    """The diarized speaker who overlaps this segment the most."""
    return max(turns, key=lambda t: min(end, t.end) - max(start, t.start)).speaker


last = None
for s in heard.segments:
    who = speaker(s.start, s.end)
    if who != last:
        print("\n[%d:%02d] Speaker %d:" % (s.start // 60, s.start % 60, who + 1), end="")
        last = who
    print(" " + s.text.strip(), end="")
print()
```

```
ana@lab:~/mm$ python transcript.py | cut -c1-110

[0:00] Speaker 1: Good morning, you're through to Marginalia Support. My name is Kyo. How can it help
[0:06] Speaker 2: Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado Desiss and it a
[0:15] Speaker 1: Let me pull that up. Yes, I can see it here. One copy of Dom Casmorrow delivered on the 24th
[0:25] Speaker 2: Cover is torn, and about 10 pages are folded at the corner. I'd like to send it back.
[0:29] Speaker 1: I'm sorry to hear that. You're well within the 30 day window so you can return it free of ch
[0:39] Speaker 2: Will I get the shipping back as well?
[0:41] Speaker 1: Yes, for a damaged book we refund the full 3480 shipping included as soon as the parcel reac
[0:50] Speaker 2: Perfect, thank you.
[0:52] Speaker 1: Thank you for calling Marginalia. Have a good day.
```

Nine turns, every one given to the right person, in line with lesson 5's 98% on the same call. The words are Whisper base's, "Kyo" and "Dom Kazmuro" included, so this is a **draft**: published as is, it tells a deaf reader that the agent was called Kyo. A person corrects it against the audio once, which takes far less time than typing it from nothing, and the speakers are named in the same pass.

The last criterion, 1.1.1, is the oldest: an image that carries meaning needs a text alternative. Whether an `alt` says the right thing is a judgement about the page. What a machine can check is the shape of the failures, and they are few:

```python
"""The alt text a machine can judge: present, not a file name, not 'image of', empty only when decorative."""
import re
import sys
from html.parser import HTMLParser


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.found = []

    def handle_starttag(self, tag, attrs):
        if tag == "img":
            self.found.append((self.getpos()[0], dict(attrs)))


page = Images()
page.feed(open(sys.argv[1]).read())
for line, a in page.found:
    alt, src = a.get("alt"), a.get("src", "")
    if alt is None:
        verdict = "MISSING: many screen readers fall back to the file name"
    elif alt == "":
        verdict = "empty: right only if the picture is decoration" + ("" if a.get("role") == "presentation" else "; is it?")
    elif re.fullmatch(r"[\w-]+\.(jpe?g|png|gif|webp)", alt, re.I):
        verdict = "a file name, not a description"
    elif re.match(r"(image|picture|photo) of", alt, re.I):
        verdict = "starts with 'image of': the reader already says it is an image"
    else:
        verdict = "ok to a machine; whether it says the right thing is a person's call"
    print("line %d  %-22s %s" % (line, src, verdict))
```

```python
<main>
  <h1>Dom Casmurro</h1>
  <img src="cover-b39.png" alt="Cover of Dom Casmurro: a moon over a dark house with two lit windows">
  <img src="back-cover.jpg" alt="IMG_2041.jpg">
  <img src="size-chart.png">
  <img src="divider.svg" alt="" role="presentation">
  <img src="author.jpg" alt="Image of Machado de Assis">
  <p>Machado de Assis's novel of 1899, in a new English translation.</p>
</main>
```

```
ana@lab:~/mm$ python alt_check.py product.html
line 3  cover-b39.png          ok to a machine; whether it says the right thing is a person's call
line 4  back-cover.jpg         a file name, not a description
line 5  size-chart.png         MISSING: many screen readers fall back to the file name
line 6  divider.svg            empty: right only if the picture is decoration
line 7  author.jpg             starts with 'image of': the reader already says it is an image
```

Four of five need a person to look. The size chart has no `alt`, so many screen readers fall back to announcing its file name. The back cover's `alt` is a file name. The author's starts with "Image of", which the screen reader has already said. The divider's empty `alt` is right, because it is decoration, and the check says so only because the page marked it with `role="presentation"`.

The cover's `alt` passes, and only a person can say whether it is good. It is built from lesson 8's course-written description, cut to what a shopper choosing an edition needs. A vision model's draft is a fair start for alt text; the full description it wrote would be far too long, and **the purpose of the image on that page** decides what to keep. This platform runs `axe` over every screen in both themes, and it finds the missing `alt`; whether an `alt` says the right thing is outside what it can decide. An automated check is where a review starts, not where it ends.
