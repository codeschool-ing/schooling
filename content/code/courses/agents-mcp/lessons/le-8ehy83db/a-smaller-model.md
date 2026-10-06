---
title: A smaller model
version: 1
---

labllm has two models, and the second, `scripted-mini`, writes four times faster: 10 ms a token instead of 40. The same run, with nothing else changed:

```
ana@lab:~/agents$ python cost_run.py scripted-mini
step   input  c.write  c.read  output     ms  stop
   1    2359        0       0      10    335  tool_use
       tool get_order: 1 ms
   2    2520        0       0       8    330  tool_use
       tool search_help: 317 ms
   3    2561        0       0      75    957  end_turn
total    7440        0       0      93   1939
```

**1,939 ms instead of 4,768.** The tokens are identical, because the same text went in and the same answer, written by the course, came out; the difference is all in the writing. The answer request fell from 3,208 ms to 957.

With real providers the smaller model of a family is faster and cheaper per token, and less capable. Which tasks it can carry is a question to answer by testing, not by assumption. Lesson 2's routing pattern is where the answer pays: send the easy questions (*where is my order?*) to the small model and the hard ones to the large one, and decide which is which with something cheap. A router that sends ninety per cent of traffic to a model that is four times faster has made the agent faster for ninety per cent of customers.

What a smaller model does not change is the shape of the bill. It still reads 7,440 tokens to write 93. That part is the next section's subject.
