---
title: "Choosing the next token: temperature, top-p and seeds"
version: 2
---

Section 06 used greedy decoding, always taking the top token. By default a model does not do that:
it **draws one at random, weighted by the probabilities**. A token with 5% is picked about one time
in twenty. Three settings change that draw. Whether you are allowed to touch them depends on the
provider, as the end of this section shows.

## Temperature

**Temperature reshapes the distribution before the draw.** Below 1 it sharpens it, so the likely
tokens become likelier still. Above 1 it flattens it, giving rare tokens more of a chance. At 0 the
draw disappears and the top token always wins, which is greedy decoding again. The same prompt
and the same random seed at three temperatures:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0 --seed 8
The default value is 0.0. The value of the parameter is used to scale the output
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 8
The default value is 0. The default value is 0.
The default value is 0
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 1.5 --seed 8
The default value is 8 red selectors would affect physically exactly abc downwards]
 (*) Output Fully duality
```

At 0 the text is the most predictable continuation, and plausible. At 0.7 this draw **fell into
a loop**: once `The default value is 0.` had been written twice, writing it a third time was the
likeliest thing to do, and nothing in the loop of section 06 notices repetition. At 1.5, tokens
the model thought very unlikely are chosen so often that the text stops making sentences: English
words in an order no sentence has, a stray bracket, and a capitalised word or two.

Ollama's own default is 0.8. Every reply in this course that does not set a temperature, from
`ollama run` or through an SDK, is drawn at that setting, which is why **your replies will be
worded differently from the lesson's**, and sometimes reach a different conclusion. Where that
matters, the lesson says what to look for rather than what the words were.

## The seed

The random draw needs a source of randomness. Fix it, and the same distribution gives the same
draws. Change it, and the same prompt at the same temperature gives a different text:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 1
The default value is inherited from the superclass, so you don't need to specify it in the subclass
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 2
The default value is 24 hours. It is possible to set the duration of the poll to a
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 3
The default value is 16, which is a good starting point for most users. You can adjust
```

Three seeds, three confident statements about three different things. **Do not expect the same
three on your machine**, and do not expect even a fixed seed to hold for long: on the recording
machine, all three of these seeds gave different continuations before Ollama was reinstalled. A
difference in the last digit of a probability is enough to change a draw, and from then on every
token follows from a different text.

**This is why the same question to a hosted model gives a different answer each time.** Some
provider APIs do not let you fix the seed at all, and the ones that accept one describe the result
as best effort. Even at temperature 0, the providers do not promise identical output for identical
requests: their hardware is not guaranteed to do the arithmetic bit for bit the same from one
request to the next. Section 06's probabilities moving by a few points between
runs is a sign of the same thing. **Do not build anything that relies on a model repeating
itself exactly.** If a test needs a fixed answer, the test should not be calling a model; lesson
4 comes back to that.

## Top-p

**Top-p cuts the tail off before the draw.** It keeps the most likely tokens until their
probabilities add up to *p*, and draws only among those. With *p* at 0.5, the draw is among the
handful of tokens that make up the likeliest half of the distribution, however flat the
temperature has made it. Here is the 1.5 run again with that cut:

```
ana@dev:~/shop$ python scratch/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 8
The default value is 0. If the specified range is a fraction of the total size of the
```

A sentence again, and almost a sensible one: the cut removed the improbable words and left the
draw free to wander only between likely ones. **Change one of the two settings, not both**: they act on the same
thing, and moving both makes it impossible to tell which one changed the output. Some providers
also offer **top-k**, which keeps a fixed number of tokens rather than a share of the probability;
`generate.py` sets it to 0, which in Ollama means no limit, so that only the two settings above
are at work.

## Which APIs let you set them

These are settings of the draw, and the draw happens on the provider's side, so the provider
decides which of them you may change. Asking each of the three SDKs you installed what its
generation call accepts gives three different answers. `~/shop/scratch/knobs.py` reads the
parameters of each call, without sending anything:

```python
import inspect

import anthropic
import openai
from google.genai import types

calls = {
    "anthropic messages.create": inspect.signature(anthropic.Anthropic().messages.create).parameters,
    "openai chat.completions.create": inspect.signature(openai.OpenAI().chat.completions.create).parameters,
    "google GenerateContentConfig": types.GenerateContentConfig.model_fields,
}
for name, params in calls.items():
    have = [k for k in ("temperature", "top_p", "top_k", "seed") if k in params]
    print(f"{name:32} {' '.join(have) or '(none of them)'}")
```

```
ana@dev:~/shop$ python scratch/knobs.py
anthropic messages.create        (none of them)
openai chat.completions.create   temperature top_p seed
google GenerateContentConfig     temperature top_p top_k seed
```

**Anthropic's current API takes none of the four.** The `anthropic` SDK has no such argument, and
its API reference, read on 2 October 2026, does not mention one: how Claude models draw their
tokens is Anthropic's decision. OpenAI's Chat Completions accepts temperature, top-p and a seed,
and Google's adds top-k. Lesson 10 lays the three APIs side by side. Most of this course calls
Ollama through the `anthropic` SDK, so most of its programs cannot set a temperature either, and
their replies are drawn at Ollama's default.

## What to set for programming work, where you can

- **Code, extraction, classification: a low temperature**, 0 to 0.3. There is a correct answer and
  variety only adds ways to be wrong.
- **Names, alternatives, test ideas: around the provider's default**, often 1. Here variety is
  the point, and you can ask for several and keep the best.
- **Leave the rest at their defaults** until you have a measured reason to move them. A setting
  copied from a blog post is a setting nobody on your team can explain later.

Where the API offers no temperature, the same goals are reached in the request instead: ask for one
answer in a fixed format when you want consistency, and for several alternatives when you want
variety. Lesson 5 is about writing those requests.
