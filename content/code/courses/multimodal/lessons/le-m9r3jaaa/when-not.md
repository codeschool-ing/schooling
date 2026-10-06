---
title: When a multimodal model is the wrong tool
version: 1
---

The most expensive mistake in this field is using a model to recover information that was available in a cheaper, exact form all along. Before reaching for any model in this course, look for these.

**The data already exists as data.** A PDF produced by accounting software has a text layer: the characters are in the file, and a library reads them exactly, for free, in milliseconds. Running it through OCR or a vision model re-reads a picture of text that was already text, and adds errors. The same goes for an invoice that arrives as an XML file (in Brazil the electronic invoice, the NF-e, is exactly that), a form whose fields are fields, and a barcode, which a scanner reads with no doubt at all.

**A rule would do.** If the job is "is this image larger than 5 MB" or "is this recording longer than ten minutes", ffprobe answers it. Lesson 1's inventory program did that for every file in the lab without a model.

**The answer must be exact and nobody will check it.** A model that reads invoice totals into an accounting system with nobody looking will one day write 2 where the page says 12 (lesson 2 shows that exact misreading). Where a wrong value is expensive, the model's output is a draft for a person, or it is checked against something else: the line amounts must add up to the total, the order number must exist.

**The data is somebody's body or identity.** A face, a voice and a fingerprint can identify a person. Under the LGPD, biometric data is sensitive personal data, with stricter grounds for processing it. Sending a customer's photograph to a third-party API is a transfer of their data, and the privacy policy has to say so. Lesson 8 shows the smallest step, stripping a photograph's metadata before it leaves.

**Every attempt costs money and the user will retry.** A text model's call costs fractions of a cent. Generating an image or listening to an hour of audio costs far more, and lesson 13 puts numbers on it. A feature that invites people to press "try again" multiplies that cost by the number of presses.

None of these is a reason to avoid the field. Each is a question to answer before writing the first line, and an honest answer will sometimes be "no model at all".
