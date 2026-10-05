---
title: Three families side by side
version: 1
---

The three families of this lesson, and Llama from the last one, answer lesson 2's questions
differently. Side by side, from what this course could read:

| | maker | licence of the weights, as read here | maker's own API | names to know |
|---|---|---|---|---|
| Llama | Meta, USA | its own, with a user threshold and *Built with Llama* (lesson 2) | not covered here | `instruct`, `17Bx128E` |
| DeepSeek | DeepSeek, China | MIT for R1; a model licence with use restrictions for V3 (lesson 2) | yes, aliases retired July 2026 | `flash`, `pro`, `r1` |
| Qwen | Alibaba, China | Apache 2.0 for the open-weight models of Qwen 3 | yes, with Max not open | `235b-a22b`, `instruct`, `thinking` |
| Gemma | Google, USA | Google's own terms, not reachable from the lab | through hosts and Google's platforms | `-it`, `A4B`, `E4B` |

Three things this table says that a price list does not.

**"Open" is four different licences.** Each row needs its own reading, and the answer for one version
is not the answer for the next, as Qwen's change from Tongyi Qianwen to Apache shows.

**Where the maker is based is a fact about its API, not about the weights.** Using DeepSeek's or
Alibaba's own API sends Lantern Books' e-mail to a company in China, which some contracts and some
data rules treat differently. Running the same weights on a host in Brazil, or on ana's own machine,
does not. Lesson 2 section 07 drew that line for closed models; for open ones the choice of **host**
is where it is drawn.

**Mixture of experts is now the common shape.** Llama 4, Qwen 3's large models and Gemma 4's
`A4B` all hold far more than they compute. Lesson 10 section 03's two sizes, memory by the total and
speed by the active part, are the arithmetic for every one of them.
