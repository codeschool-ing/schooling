---
title: Which tool for which picture
version: 2
---

The three tools in this lesson are not rungs on one ladder, where the VLM is simply better. Each answers a different question at a different cost, and the right choice is usually the cheapest one that answers yours.

| the picture, and the question | the tool | why |
|---|---|---|
| a PDF with a text layer: *what does it say?* | no model; read the text layer | exact and free (lesson 1) |
| a printed scan with a known layout: *what are the fields?* | OCR, then rules, then checks | 0.4% CER on this course's scan, in milliseconds, on the machine |
| a photo: *is there a person, a car, a dog, and where?* | a detector | geometry, speed and no per-call cost, if the class is in its list |
| a photo or a page with an open question: *what is this, is anything wrong?* | a vision-language model | open vocabulary, layout, reasoning |
| handwriting, a crumpled receipt, a layout that changes every time | a vision-language model, checked | OCR's row assumption no longer holds |
| anything that ends in money or a decision about a person | any of the above **and a check that is not a model** | the misread digit looks exactly like a right one |

Two patterns from this lesson combine the rows.

**Cheap first, expensive on doubt.** Run OCR; if the arithmetic checks pass, the job is done; if they fail, send the same page to a VLM or to a person. On a supplier that sends clean PDFs, the expensive path almost never runs.

**A model for meaning, a cheaper tool for proof.** A VLM can read a crumpled receipt that OCR cannot, and the total it returns can still be checked against the line items it also returns. The checking does not need a model at all.

The question this lesson set out with is the one to keep asking: *what is the cheapest tool that reads this picture well enough, and how will I know when it did not?*
