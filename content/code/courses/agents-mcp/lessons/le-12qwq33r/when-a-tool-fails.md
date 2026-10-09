---
title: When a tool fails
version: 2
---

## By default, the run ends

`get_order` raises `LookupError` for an order that does not exist. With the ADK's defaults:

```
ana@lab:~/agents$ python adk_run.py default "Where is my order M-9999?" 2> stderr.txt; wc -l < stderr.txt; tail -1 stderr.txt
support  call    get_order {"order_id": "M-9999"}
raised   LookupError: no order M-9999
174
LookupError: no order M-9999
```

**The exception ended the run.** The model had asked for the order, the tool raised, and the ADK did not send anything back to the model: the error came out of `run_async`, where `adk_run.py` caught it, and the ADK logged a traceback of 174 lines to standard error on its way out (`stderr.txt`). Compare lesson 8, where the SDK sent the model a generic sentence and the run went on. Here a missing order and a crashed program look the same to the customer, unless the code around the run decides otherwise.

## A callback turns the error into a result

`on_tool_error_callback` is called when a tool raises, with the tool, its arguments and the exception. Whatever it returns becomes the tool's result:

```schooling-example
{
  "language": "python",
  "file": "adk_run.py",
  "parts": [
    {
      "code": "def say_what_failed(tool, args, tool_context, error):\n",
      "note": "**The callback**: the tool, its arguments, the context and the error."
    },
    {
      "code": "    return {\"error\": f\"{type(error).__name__}: {error}\"}",
      "note": "**A result with the error's type and message**, which is lesson 4's rule once more."
    }
  ]
}
```

```
ana@lab:~/agents$ python adk_run.py caught "Where is my order M-9999?"
support  call    get_order {"order_id": "M-9999"}
support  result  get_order {"error": "LookupError: no order M-9999"}
support  text    I'm sorry, but I'm unable to find order M-9999. Can I look up the order by order ID or customer name instead?
```

Now the model read `{"error": "LookupError: no order M-9999"}` and could answer the customer. One callback on the agent covers every tool, which is a better place for the rule than a `try` in each function.

## The limit on model calls

```
ana@lab:~/agents$ python adk_run.py one-call "Where is my order M-1043?" 2> stderr.txt; wc -l < stderr.txt
support  call    get_order {"order_id": "M-1043"}
support  result  get_order {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "s
raised   LlmCallsLimitExceededError: Max number of llm calls limit of `1` exceeded
98
```

`RunConfig(max_llm_calls=1)` let one model call happen, ran the tool it asked for, and raised `LlmCallsLimitExceededError` before the second call; the ADK logged 98 lines on the way. Like lesson 8's limit, it is an exception, so the program decides what the customer sees. The default is 500 calls per run, which is a ceiling against a runaway loop rather than a budget; a support agent that needs more than a handful of calls for one message has a problem that a higher limit will not solve.
