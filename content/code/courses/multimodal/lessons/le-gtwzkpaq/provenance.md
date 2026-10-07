---
title: Saying that a picture was generated
version: 1
---

A generated picture published without saying so can mislead the people who see it, and in more and more places the law asks for a label. The European Union's AI Act requires providers of generative systems to mark their output in a machine-readable way, and to disclose deepfakes. Two technical mechanisms do the marking, and a product team should know what each one survives.

**Metadata.** The C2PA standard, behind *Content Credentials*, attaches a signed record to the file saying what made it and how it was edited. OpenAI adds C2PA credentials to the pictures its image models produce. The record travels inside the file, so whatever keeps the file intact keeps the record.

**Watermarks in the pixels.** Google's SynthID changes the picture itself in a way people do not see and a detector can find, and Google applies it to the pictures its image models generate. Because it lives in the pixels, it is meant to survive the edits that strip metadata, such as a screenshot, a crop or a new compression.

Metadata is easy to lose without meaning to. Here a note is written into a PNG the ordinary way, and then the picture is resized and saved again, as any image pipeline does:

```python
"""A note written into a PNG, and what happens to it when the picture is edited."""
from PIL import Image, PngImagePlugin

card = Image.open("grid/00-0.png")
info = PngImagePlugin.PngInfo()
info.add_text("Source", "images_server stand-in, gpt-image-1, 2026-10-07")
card.save("stamped.png", pnginfo=info)
print("saved:  ", Image.open("stamped.png").text)

edited = Image.open("stamped.png").resize((768, 512))
edited.save("edited.png")
print("edited: ", Image.open("edited.png").text)
```

```
ana@lab:~/mm$ python stamp.py
saved:   {'Source': 'images_server stand-in, gpt-image-1, 2026-10-07'}
edited:  {}
```

**The note is gone after one resize.** Pillow saved the edited picture without copying the text chunk, because nothing asked it to. The same happens in most thumbnail generators, CMS uploads and social networks. A C2PA record is more than a text chunk (it is signed, and a C2PA-aware tool can carry it forward through an edit), but a tool that knows nothing about it drops it just the same.

## What Marginalia does

1. **Keeps the record outside the picture**: the log from section 04, with the model, the prompt and who approved it. That is the provenance the shop controls.
2. **Says so where people see it**: a line under the banner, "Illustration generated with AI", costs nothing and does not depend on any file surviving.
3. **Does not strip what the provider added.** If the image pipeline resizes pictures, it copies the metadata across, and that is checked by reading the published file, not assumed.
