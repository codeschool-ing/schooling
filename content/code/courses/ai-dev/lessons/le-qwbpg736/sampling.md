---
title: "Choosing the next token: temperature, top-p and seeds"
version: 1
---

Greedy decoding gets stuck in loops, as lesson 1 section 02 showed. So by default a model does
not take the most likely token: it **draws one at random, weighted by the probabilities**. A token
with 5% is picked about one time in twenty. Three settings change that draw. Whether you are
allowed to touch them depends on the provider, as the end of this section shows.

## Temperature

**Temperature reshapes the distribution before the draw.** Below 1 it sharpens it, so the likely
tokens become likelier still. Above 1 it flattens it, giving rare tokens more of a chance. At 0 the
draw disappears and the top token always wins, which is greedy decoding again. The same prompt
and the same random seed at three temperatures:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0 --seed 7
The default value is a string, and
  A binascii.Error is raised if
the C
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 7
The default value is treated as distinct calls with
a logging call was issued
                    (typically at
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 1.5 --seed 7
The default value is as follows: if the exit code of the format.  See documentation for details
```

None of the three means anything (this model has a two-token memory), but the character of each
is the one to expect from a large model at the same setting. At 0 the text is the most
predictable continuation. At 1.5 it drifts from subject to subject, because tokens the model
thought unlikely are being chosen often.

## The seed

The random draw needs a source of randomness. Fix it, and the same distribution gives the same
draws. Change it, and the same prompt at the same temperature gives a different text:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 1
The default value is not stored in the list, sorted by key.

To use a string containing all
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 2
The default value is the name.  The object is returned.

If a formatter is specified, it
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 3
The default value is a list of (n - 1)
    25: 70 years
```

**This is why the same question to a hosted model gives a different answer each time.** Some
provider APIs do not let you fix the seed at all, and the ones that accept one describe the result
as best effort. Even at temperature 0, the providers do not promise identical output for identical
requests: the arithmetic on their hardware is not guaranteed to come out bit for bit the same
from one request to the next. **Do not build anything that relies on a model repeating
itself exactly.** If a test needs a fixed answer, the test should not be calling a model; lesson
4 comes back to that.

## Top-p

**Top-p cuts the tail off before the draw.** It keeps the most likely tokens until their
probabilities add up to *p*, and draws only among those. With *p* at 0.5, the draw is among the
handful of tokens that make up the likeliest half of the distribution, however flat the
temperature has made it. Here is the 1.5 run again with that cut:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 7
The default value is not of a type.

Class to open, read it, and it is omitted
```

Still nonsense, but closer to the subject than the uncut run. **Change one of the two settings, not
both**: they act on the same thing, and moving both makes it impossible to tell which one
changed the output. Some providers also offer **top-k**, which keeps a fixed number of tokens
rather than a share of the probability.

## Which APIs let you set them

These are settings of the draw, and the draw happens on the provider's side, so the provider
decides which of them you may change. The lab has the three providers' current SDKs installed,
and asking each one what its generation call accepts gives three different answers:

```
ana@dev:~/shop$ python lab/knobs.py
anthropic messages.create        (none of them)
openai chat.completions.create   temperature top_p seed
google GenerateContentConfig     temperature top_p top_k seed
```

**Anthropic's current API takes none of the four.** The `anthropic` SDK has no such argument, and
its API reference, read on 2 October 2026, does not mention one: how Claude models draw their
tokens is Anthropic's decision. OpenAI's Chat Completions accepts temperature, top-p and a seed,
and Google's adds top-k. Lesson 10 lays the three APIs side by side.

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
