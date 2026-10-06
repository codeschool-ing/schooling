---
title: Where it earns its place in a product
version: 1
---

The useful way to sort multimodal use cases is not by industry but by **direction**: what goes in, and what comes out. Each direction has a family of products, a thing that makes it worth the cost, and a characteristic way of failing.

| direction | products that use it | what makes it worth it | how it fails |
|---|---|---|---|
| image → text | reading invoices and receipts, checking a photo a customer sent, alt text for a catalogue | a person was typing what a picture says | a misread digit that looks plausible |
| audio → text | call transcripts, meeting notes, voice search, captions | nobody can search or skim a recording | a name or a number heard as something else |
| video → text | search inside videos, summaries, moderation | a person would have to watch the whole thing | what happened between two sampled pictures |
| text → image | illustration, banners, product mock-ups | a picture is needed faster than someone can draw it | text inside the image, hands, counting, likeness |
| text → audio | phone menus, read-aloud, audiobooks, voice agents | a person would otherwise have to be on the line | numbers and names read wrongly, delay before it speaks |
| audio → audio | live translation, voice assistants | the conversation has to keep its pace | everything above, with no transcript to check |

Two columns deserve a second look.

**"What makes it worth it" is always a person's time.** Every row replaces somebody looking, listening, typing or speaking. That is also the test for whether a use case is real: if nobody was going to do the work by hand, automating it is a cost with no saving behind it. A shop that receives four invoices a month does not need a vision model; one that receives four hundred might.

**"How it fails" is almost never a crash.** It is a wrong value that reads like a right one. That is why every lesson from here on puts a model's output next to the known truth and counts the difference. The lab can do that because its media was made from a script. A real product does it with a sample checked by hand, and the arithmetic is the same.

## The use cases this course leaves out

Some directions are left out on purpose. Medical images, faces used to identify people and anything that decides about a person from their voice or appearance carry legal and ethical weight beyond what an intermediate course can treat honestly, and in Brazil biometric data is sensitive personal data under the LGPD. Robotics and models that act on a screen by looking at it are left out too. What stays is the set of jobs a small product team builds every week.
