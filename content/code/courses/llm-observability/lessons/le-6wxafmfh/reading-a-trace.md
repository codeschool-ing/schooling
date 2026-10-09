---
title: Reading a trace
version: 2
---

The tree says where the time went. The attributes say what each step was working with, and they are
where most questions about a single bad answer are settled.

```
ana@dev:~/obs$ python tree.py --attrs
trace 5ea30205e6a9ef29c4b98b45d1595ab9   start(ms) took(ms)
      0   3,021 ms  ask
                     app.feature = "help"
                     app.release = "2026.10.1"
                     gen_ai.request.model = "llama3.2:3b"
                     user.hash = "ed56759c27bf4d29"
                     session.id = ""
                     app.question = "Who pays for the return postage?"
                     app.outcome = "answered"
                     app.reply = "According to [1], the customer pays for the return postage."
      0      25 ms    embed
                       gen_ai.operation.name = "embeddings"
                       gen_ai.request.model = "all-minilm"
                       gen_ai.usage.input_tokens = 9
     26       4 ms    search
                       app.search.k = 3
                       app.search.floor = 0.55
                       app.search.returned = 3
                       app.search.kept = 1
                       app.search.top_score = 0.563
                       app.search.chunks = ["returns-policy:how-to-start-a-return"]
     31   2,990 ms    generate
                       app.attempts = 1
     31   2,990 ms      chat llama3.2:3b
                         gen_ai.operation.name = "chat"
                         gen_ai.provider.name = "ollama"
                         gen_ai.request.model = "llama3.2:3b"
                         gen_ai.request.max_tokens = 300
                         gen_ai.request.temperature = 0
                         app.time_to_first_token_ms = 1663
                         gen_ai.usage.input_tokens = 165
                         gen_ai.usage.output_tokens = 14
                         gen_ai.response.model = "llama3.2:3b"
                         gen_ai.response.finish_reasons = ["stop"]
  3,021       0 ms    check_citations
                       app.citations.count = 1
                       app.citations.dangling = 0
```

Go back to the reply: *the customer pays for the return postage.* The documents say the opposite:
returns are free, and the shop e-mails a prepaid label. The reply is wrong, and the trace says
where the mistake was made, one span at a time.

- **`search`**: three chunks came back (`app.search.returned`), and **one** cleared the floor
  (`app.search.kept`), at 0.563 against a floor of 0.55. Its id is in `app.search.chunks`:
  `returns-policy:how-to-start-a-return`, the very section that says returns are free.
- **`chat llama3.2:3b`**: 165 tokens in, 14 out. A prompt that small holds the instructions, one
  chunk and the question, and nothing else.
- **`ask`**: the release was `2026.10.1`, the one that raised the floor.

So the search did its job: the one chunk the model was handed is the one that answers the question,
and it answers it in three plain words, *Returns are free*. **The mistake is the model's**, made
while reading a source that said the opposite, and that changes where to look for a fix: not in the
search or the floor, but in the prompt, the model, or how many sources it is given. Which of those
would help cannot be decided from one trace. Lessons 8 to 14 measure the model and the floor over
many questions, and lesson 5 counts what the raised floor did over a week.

Notice what had to be on the span for this to be readable. A trace with only names and durations
would have said "3,021 ms, nothing failed". **The attributes that explain a wrong answer are the ones
about the inputs**: how many chunks, which ones, how close, which settings. Recording only the
outputs, the tokens and the latency, makes a trace that can explain a slow answer and never a bad
one. And it took the chunk's id to send somebody to the right paragraph of the right document, where
the model's mistake could be seen.

## A trace with a missing step

```
ana@dev:~/obs$ python assistant.py "Is there a student discount?"
I could not find that in our documents.
trace b0f29bf4b40469cb859c35e290b1bcec
ana@dev:~/obs$ python tree.py
trace b0f29bf4b40469cb859c35e290b1bcec   start(ms) took(ms)
      0      44 ms  ask
      1      42 ms    embed
     43       0 ms    search
     44       0 ms    check_citations
```

Four spans, not six. There is **no `generate`**: nothing cleared the floor, so the assistant returned
its refusal without calling the model. The trace took 44 ms instead of 3,021, and cost no model
tokens.

```
ana@dev:~/obs$ python tree.py --attrs | sed -n "/search/,/check_citations/p"
     43       0 ms    search
                       app.search.k = 3
                       app.search.floor = 0.55
                       app.search.returned = 3
                       app.search.kept = 0
                       app.search.top_score = 0.244
                       app.search.chunks = []
     44       0 ms    check_citations
```

The best chunk scored 0.244, far below the floor, and the documents really do not mention a student
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
  not texts: the chunk's id finds its text whenever it is needed, as it did for the postage
  question.
- **Anything you would want to filter by**: if a question will be "show me every trace where X", X
  has to be an attribute.

The question and the reply are on the root already, passed through a function called `redact()` that
lesson 2 opens. What is on no span is the full prompt: the instructions and the sources as the model
received them. It would make every trace explain itself, and it is also where personal data goes to
live for as long as the traces do. Lesson 2 decides how much of it to keep.
