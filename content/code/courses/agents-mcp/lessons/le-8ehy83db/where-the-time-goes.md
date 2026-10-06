---
title: Where the time goes
version: 1
---

The same run, read for time. Of 4,768 ms:

- **Request 3 took 3,208 ms**, because it wrote the 75-token answer. In labllm that is 200 ms plus 75 × 40 ms, and the measurement matches to a few milliseconds. With a real provider the shape is the same: output is produced one token at a time, so a long answer is a slow answer.
- **Requests 1 and 2 took about 600 ms each**, for 10 and 8 tokens of output: mostly the time before the first token.
- **`search_help` took 348 ms**, the embedding model of `embeddings-vectors` encoding the query; `get_order` took 1 ms.

Input tokens cost no time in labllm, which only counts them. A real provider spends time reading a long prompt too, so its first token arrives later as the prompt grows, and that is one of the places where labllm is simpler than what it stands for.

The arithmetic gives three rules for a faster agent, in order of effect:

1. **Fewer steps.** Each request pays the time to first token, and each one resends the whole conversation. A plan that needs two tool calls should not take five turns (lesson 5).
2. **Shorter output where output is not the product.** A tool call is short; an internal summary for another agent need not be prose.
3. **A smaller model where it is enough**, the next section.

Streaming does not shorten the work, but it changes what a person waits for: the first words appear after the time to first token instead of after the whole answer. For a support chat, that is the difference between three seconds of silence and an answer that starts at once.
