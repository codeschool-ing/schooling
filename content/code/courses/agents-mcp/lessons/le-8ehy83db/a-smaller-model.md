---
title: A smaller model
version: 2
---

Lesson 1 pulled a second model, `llama3.2:1b`: the same family with a third of the parameters, 1.3 GB on disk instead of 2.0. The same run, with nothing else changed:

```
ana@lab:~/agents$ python cost_run.py llama3.2:1b
step   input  c.write  c.read  output     ms  stop
   1     994        0      15      34   5588  tool_use
       tool get_order {"function": "get_order", "parameters": {"properties": {"order_id": "M-1043"}, "required": ["order_id"], "type": "object"}, "type": "function"}Traceback (most recent call last):
  File "/home/ana/agents/cost_run.py", line 57, in <module>
    out = json.dumps(RUN[call.name](call.input))
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/agents/cost_run.py", line 29, in <lambda>
    RUN = {"get_order": lambda a: shop.get_order(a["order_id"]),
                                                 ~^^^^^^^^^^^^
KeyError: 'order_id'
```

The first request **took 5,588 ms instead of 10,447**, for the same 994 tokens read: a smaller model reads and writes faster. And then the program crashed. The model asked for `get_order`, and for arguments it sent the tool's own description back, `{"function": "get_order", "parameters": {...}}`, with the order id buried one level down where `order_id` should have been. `cost_run.py` trusted the arguments, which lesson 4 warned against, and `a["order_id"]` raised `KeyError`.

That is what a smaller model trades. It is faster and, from a provider, cheaper per token, and it is less able to do what the larger one did on this very request. **Which tasks it can carry is a question to answer by testing**, not by assumption, and the test is runs like this one, many of them, read for the call as well as the time. Lesson 2's routing pattern is where the answer pays: send the easy questions to the small model and the hard ones to the large one, decide which is which with something cheap, and check the small model's tool calls before running them, because a schema check would have turned this crash into an error result the loop could handle.

What a smaller model does not change is the shape of the bill. It still reads the whole prompt on every request. That part is the next section's subject.
