---
title: Where the time goes
version: 2
---

The same run, read for time. Of 19,242 ms:

- **Request 1 took 10,447 ms** to write 16 tokens. Most of that was reading: 994 tokens of tools, policies and question, which a CPU works through before it writes anything.
- **Request 2 took 8,629 ms**, and it read only 65 new tokens. Most of this one was writing the 67-token answer, one token at a time, so a long answer is a slow answer.
- **`search_help` took 166 ms**, the `all-minilm` model in Ollama encoding the query; the `get_order` of a later run took 1 ms.

The second run of section 05 asked the same question right after, and its first request took **3,955 ms instead of 10,447**: it read 162 tokens and reused 847. Reading a long prompt is not free, and on a machine without a large GPU it is the biggest part of the wait. A hosted provider reads faster, but the shape is the same: the first token arrives later as the prompt grows.

The arithmetic gives three rules for a faster agent, in order of effect:

1. **Fewer steps.** Each request pays the time to first token, and each one resends the whole conversation. A plan that needs two tool calls should not take five turns (lesson 5).
2. **Shorter output where output is not the product.** A tool call is short; an internal summary for another agent need not be prose.
3. **A smaller model where it is enough**, the next section.

Streaming does not shorten the work, but it changes what a person waits for: the first words appear after the time to first token instead of after the whole answer. For a support chat, that is the difference between ten seconds of silence and an answer that starts as soon as the reading is done.
