---
title: Reading a trace
version: 1
---

The tree says where the time went. The attributes say what each step was working with, and they are
where most questions about a single bad answer are settled.

```
ana@lab:~/obs$ python tree.py --attrs
trace 1a218c3902fa97519a4b28d0bd1f155f   start(ms) took(ms)
      0     785 ms  ask
                     app.feature = "help"
                     app.release = "2026.10.1"
                     gen_ai.request.model = "extract-1"
                     user.hash = "d89d2eeb16257c0f"
                     session.id = ""
                     app.question = "Above what order value is standard delivery free?"
                     app.outcome = "answered"
                     app.reply = "Express delivery is not free at any order value. [1]"
      0      56 ms    embed
                       gen_ai.operation.name = "embeddings"
                       gen_ai.request.model = "lab-minilm"
                       gen_ai.usage.input_tokens = 9
     56       4 ms    search
                       db.system.name = "postgresql"
                       app.search.k = 3
                       app.search.floor = 0.62
                       app.search.returned = 3
                       app.search.kept = 1
                       app.search.top_score = 0.637
                       app.search.chunks = ["shipping-and-delivery:ca3796df6832"]
     61     723 ms    generate
                       app.attempts = 1
     61     723 ms      chat extract-1
                         gen_ai.operation.name = "chat"
                         gen_ai.provider.name = "openai"
                         gen_ai.request.model = "extract-1"
                         gen_ai.request.max_tokens = 300
                         app.time_to_first_token_ms = 325
                         gen_ai.usage.input_tokens = 143
                         gen_ai.usage.output_tokens = 13
                         gen_ai.response.model = "extract-1"
                         gen_ai.response.finish_reasons = ["stop"]
    784       0 ms    check_citations
                       app.citations.count = 1
                       app.citations.dangling = 0
```

Go back to the reply: *Express delivery is not free at any order value.* The customer asked about
**standard** delivery, and the documents say it is free above 40. The reply is wrong, and the trace
shows why, one span at a time.

- **`search`**: three chunks came back (`app.search.returned`), and **one** cleared the floor
  (`app.search.kept`). The best scored 0.637 against a floor of 0.62. One chunk, from the shipping
  document.
- **`chat extract-1`**: 143 tokens in, 13 out. A prompt that small holds the instructions, one chunk
  and the question, and nothing else.
- **`ask`**: the release was `2026.10.1`, the one that raised the floor.

So the model was handed one chunk, and that chunk was about express delivery. extract-1 copied the
sentence nearest the question, as its rules say. The search found more than that, and the floor
threw it away. Whether a floor of 0.62 is a mistake cannot be decided from one trace; lesson 5 counts
what it did over a week.

Notice what had to be on the span for this to be readable. A trace with only names and durations
would have said "785 ms, nothing failed". **The attributes that explain a wrong answer are the ones
about the inputs**: how many chunks, which ones, how close, which settings. Recording only the
outputs, the tokens and the latency, makes a trace that can explain a slow answer and never a bad
one.

## A trace with a missing step

```
ana@lab:~/obs$ python assistant.py "Is there a student discount?"
I could not find that in our documents.
trace ce0b5661415f1a83fc75d4de2668184a
ana@lab:~/obs$ python tree.py
trace ce0b5661415f1a83fc75d4de2668184a   start(ms) took(ms)
      0      46 ms  ask
      0      40 ms    embed
     41       4 ms    search
     45       0 ms    check_citations
```

Four spans, not six. There is **no `generate`**: nothing cleared the floor, so the assistant returned
its refusal without calling the model, as `rag` lesson 7 designed it to. The trace took 46 ms
instead of 785, and cost no model tokens.

```
ana@lab:~/obs$ python tree.py --attrs | sed -n "/search/,/check_citations/p"
     41       4 ms    search
                       db.system.name = "postgresql"
                       app.search.k = 3
                       app.search.floor = 0.62
                       app.search.returned = 3
                       app.search.kept = 0
                       app.search.top_score = 0.354
                       app.search.chunks = []
     45       0 ms    check_citations
```

The best chunk scored 0.354, far below the floor, and the documents really do not mention a student
discount: the refusal is right.

Two refusals can look identical on the screen and be different in the trace. One has no `generate`
span, because the search found nothing close enough. The other has a `generate` span whose reply is
the refusal sentence, because the model read the sources and decided they did not answer. `ask`
records both as `app.outcome = refused`, and the presence of the child span says which kind it was.
It matters, because the first costs nothing and is fixed in the search, and the second costs a full
model call and is fixed in the prompt or the sources.

## What to put on a span

A short list, from the two traces above:

- **On the root**: what the request was for (feature, release, model), and who and which session,
  in a form lesson 2 will make safe. The outcome, once it is known.
- **On a model call**: the `gen_ai.*` attributes for the request and the response, the token counts,
  and the time to the first token if the reply is streamed.
- **On a retrieval step**: how many results, how many kept, the best score, and which ones. Ids,
  not texts: the chunk's id finds its text whenever it is needed.
- **Anything you would want to filter by**: if a question will be "show me every trace where X", X
  has to be an attribute.

The question and the reply are on the root already, passed through a function called `redact()` that
lesson 2 opens. What is on no span is the full prompt: the instructions and the sources as the model
received them. It would make every trace explain itself, and it is also where personal data goes to
live for as long as the traces do. Lesson 2 decides how much of it to keep.
