---
title: Deciding, and combining the two
version: 1
---

The comparison collapses into one question asked of each thing you want the model to do: **is it
knowledge, or is it behaviour?** Knowledge changes, must be cited, may have to be deleted and is
different for different readers; it belongs in documents that a retrieval system puts in the prompt.
Behaviour is the same in every reply and is expensive to restate; it is a candidate for fine-tuning,
once a prompt has proved it is worth having.

| what you need | retrieval | fine-tuning |
| --- | --- | --- |
| answers about your documents | yes | no: facts are held weakly and cannot be traced |
| answers that change with the documents | yes, in minutes | only after a retraining run |
| a source for every answer | yes, the retrieved text | no: a citation would be learnt text |
| the ability to delete what it knows | yes, delete the rows | no: retrain from the base model |
| different answers for different readers | yes, filter what is retrieved | no: one model knows the same for everybody |
| a strict format or house style | partly, by instructions | yes |
| a short prompt at very high volume | no: context is paid per question | yes |
| a reply within a tight latency budget | it adds a search | yes, for a small stable set of facts |

## Prompt first, then retrieval, then fine-tuning

The order in which teams should try them follows from the cost of each.

**Start with the prompt.** Instructions and a few examples in the system prompt cost nothing to
change, and they establish whether the behaviour is achievable at all. `prompt-engineering` and
`prompt-reliability` are about doing this well.

**Add retrieval for knowledge.** As soon as the answers depend on documents the model has not seen,
which for a company is almost immediately, retrieval is the only approach that stays fresh, cites its
sources and can delete. Most of this course is about doing it well.

**Fine-tune last, for behaviour that prompts cannot hold.** When a prompt has proved a behaviour is
valuable and it still drifts, or costs too much to restate at your volume, a fine-tuning run on the
replies you want, with retrieval still supplying the facts, makes it the model's habit.

## Using both

The two are not alternatives, and the strongest systems use them together. A model fine-tuned on a
few hundred support replies learns to answer first, cite every claim with the source number, keep to
two sentences and refuse when the sources are silent. At query time, retrieval gives it the sources.
The fine-tuning taught it **how** to use a source; the retrieval decides **which** sources it has.

What must never cross the line is the knowledge. The second line of `ft.jsonl` is a reminder of how
easily it does: a training set built carelessly from documents teaches the documents, including the
ones that were wrong, and nothing afterwards can point at the line that caused it.
