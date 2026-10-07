---
title: Editing with a mask
version: 1
---

Lesson 3 argued that a nearly-right picture should be **edited, not regenerated**. In the Images API an edit is the original picture, a **mask**, and a prompt for what goes in the masked part. The mask is a PNG the same size as the picture, with an alpha channel: **transparent pixels mark where the model may draw, and opaque ones are kept**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three rectangles of the same 3 by 2 shape. The banner, with a stack of books sketched on the left. The mask, solid on the left two thirds and transparent on the right third. The edited banner, with the left two thirds unchanged and only the right third repainted.\"><defs><marker id=\"l09msk-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">banner.png</text><rect x=\"20\" y=\"34\" width=\"180\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"34\" y=\"120\" width=\"70\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"104\" width=\"64\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"88\" width=\"58\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"72\" width=\"52\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"210\" y1=\"94\" x2=\"260\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l09msk-ah-phosphor)\"></line><text x=\"270\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mask.png</text><rect x=\"270\" y=\"34\" width=\"120.0\" height=\"120\" rx=\"0\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></rect><rect x=\"390.0\" y=\"34\" width=\"60.0\" height=\"120\" rx=\"0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"420.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">clear</text><text x=\"330.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--ink)\">opaque</text><line x1=\"460\" y1=\"94\" x2=\"510\" y2=\"94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l09msk-ah-phosphor)\"></line><text x=\"520\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the edit</text><rect x=\"520\" y=\"34\" width=\"180\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"534\" y=\"120\" width=\"70\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"104\" width=\"64\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"88\" width=\"58\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"534\" y=\"72\" width=\"52\" height=\"14\" rx=\"1\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"640.0\" y=\"34\" width=\"60.0\" height=\"120\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"670.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Transparent pixels in the mask say where the model may draw; everything opaque is kept.</text></svg>", "caption": "An edit keeps what was right and redraws only the masked region, which a new generation cannot do."}
```

```python
"""A mask for the edits endpoint: opaque where the picture stays, transparent where it may change."""
from PIL import Image, ImageDraw

banner = Image.open("banner.png")
w, h = banner.size
mask = Image.new("RGBA", (w, h), (0, 0, 0, 255))
ImageDraw.Draw(mask).rectangle([w * 2 // 3, 0, w, h], fill=(0, 0, 0, 0))
mask.save("mask.png")
wrong = Image.new("RGBA", (1024, 1024), (0, 0, 0, 255))
wrong.save("mask-wrong-size.png")
print("mask.png", mask.size, mask.mode, "| mask-wrong-size.png", wrong.size)
```

```python
"""Repaint only the masked part of the banner."""
import base64
import sys

from openai import OpenAI

client = OpenAI(base_url="http://localhost:8800/v1")   # lesson 3's images_server.py
try:
    result = client.images.edit(model="gpt-image-1", image=open("banner.png", "rb"), mask=open(sys.argv[1], "rb"),
                                prompt="the same café table, with a small pot of basil on the right")
except Exception as e:
    print(type(e).__name__, e)
else:
    open("banner-edited.png", "wb").write(base64.b64decode(result.data[0].b64_json))
    print("banner-edited.png written")
```

```
@@edit@@
```

The first edit went through: the stand-in returned the banner with its right third greyed out, which is its way of showing where a real model would have painted. The next two were refused, and both refusals are the commonest ways to get a mask wrong:

- **A mask of a different size.** The picture is 1536 by 1024 and the mask 1024 by 1024, so the transparent region has no defined place on the picture.
- **A mask with no alpha channel.** Passing the banner itself as its own mask means nothing is transparent, and the stand-in refused it as having no alpha. A mask drawn in an editor and saved as JPEG, which has no alpha at all, fails the same way.

These two messages are the stand-in's, written to say what is wrong; a real API's wording differs, and its refusal is what you should expect. The check worth writing is your own, before the call: same size, mode `RGBA`, and at least one transparent pixel.

**How exactly the model respects the mask is the provider's business.** OpenAI's documentation describes the mask as guidance: the model may change pixels just outside it to make the edit blend in. So the check after an edit is the one from lesson 3: look at it, against the list, before it is published.
