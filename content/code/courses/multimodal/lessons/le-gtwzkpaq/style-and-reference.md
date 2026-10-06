---
title: Style, references and keeping a look
version: 1
---

A newsletter that goes out every week needs pictures that look like they belong together. One good banner is a prompt; fifty banners that look like the same shop are a **style**, and keeping one is harder than finding one.

## Where a style comes from

**From words.** The medium, style and palette parts of the prompt, kept fixed across every banner, are the cheapest way to hold a look. Write them once, keep them in the program as a constant, and let only the subject change week to week. `axes.py` already has that shape.

**From a reference image.** Several APIs take an existing picture alongside the prompt and use it as a guide. Gemini's image model takes images in the same request as the text, and OpenAI's edits endpoint takes one or more input images (lesson 9). A reference holds colours, texture and composition far better than words do, and it is how a brand keeps a look across a year.

**From an artist's name.** This is the shortcut people reach for, and it should be avoided for a product. Prompting "in the style of" a living illustrator copies the identifiable work of a person who did not agree to it and is not paid for it. Several providers now refuse or soften prompts naming living artists. Describe the qualities you want instead (loose watercolour, visible paper texture, muted greens) and they are yours to keep.

## Editing, not regenerating

When a picture is nearly right, generating again throws away what was right along with what was wrong, because a new run starts from new noise. **Editing** keeps the picture and redraws only a region: you send the image, a **mask** marking the part to change, and a prompt describing what should be there. The rest of the picture is kept as it was. Lesson 9 does this through the API, mask and all.

## A style guide for pictures

Marginalia's text has a voice; its pictures should have a written guide too, short enough to paste into a prompt:

| fixed | free |
|---|---|
| medium: watercolour illustration | the subject |
| palette: warm ochre and deep green | the time of day, within reason |
| composition: wide, empty space on the right third | the number of objects |
| no text in the picture, no people's faces | |

The second line of the "fixed" column is a decision as much as a style: **no faces** avoids generating something that looks like a real person, which is the next section's subject.
