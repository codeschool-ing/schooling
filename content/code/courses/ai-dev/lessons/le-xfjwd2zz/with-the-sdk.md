---
title: Streaming with the SDK
version: 1
---

Nobody parses those events by hand in application code. The SDK reads them, joins the pieces and
hands back text, and at the end it builds the same message object a plain request returns.

## Pieces, as they arrive

```python
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        print(text, end="|", flush=True)
    final = stream.get_final_message()
print()
print(final.stop_reason, final.usage.input_tokens, "in,", final.usage.output_tokens, "out")
```

```
ana@dev:~/shop$ python pieces.py
The| cart| stores| prices| as| integer| cents| because| a| float| cannot| hold| most| decimal| amounts| exactly|.| In| binary| floating| point|,| |0|.|1| plus| |0|.|2| is| not| |0|.|3|,| and| a| total| built| from| many| such| sums| dr|ifts| by| a| cent| here| and| there|.| Inte|gers| add| exactly|,| so| the| cart| adds| cents| and| formats| them| only| at| the| edge|,| when| it| prints| a| price| for| a| person|.|
end_turn 15 in, 82 out
```

The bars are where one piece ended and the next began. **A piece is roughly a token**, so it
splits where the tokenizer does: `dr|ifts` and `Inte|gers` are two pieces each, and `0.1` is three.
The last line comes from `get_final_message()`, built after the stream ended, with the
`stop_reason` and the token counts a plain request would have given.

Two consequences for whoever displays the pieces:

- **Never assume a piece is a word.** A program that adds a space between pieces, or capitalises
  the first letter of each, produces `dr ifts`.
- **Append, do not replace.** Each piece is new text to add to what is on the screen; nothing in
  it repeats what came before.

## The same in OpenAI's API

```python
"""The same, through OpenAI's chat completions: chunks with a delta, then a finish_reason."""
import openai

client = openai.OpenAI()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
for chunk in client.chat.completions.create(model="scripted-1", messages=ASK, stream=True):
    choice = chunk.choices[0]
    if choice.delta.content:
        print(choice.delta.content, end="|", flush=True)
    if choice.finish_reason:
        print("\nfinish_reason:", choice.finish_reason)
```

```
ana@dev:~/shop$ python openai_pieces.py
The| cart| stores| prices| as| integer| cents| because| a| float| cannot| hold| most| decimal| amounts| exactly|.| In| binary| floating| point|,| |0|.|1| plus| |0|.|2| is| not| |0|.|3|,| and| a| total| built| from| many| such| sums| dr|ifts| by| a| cent| here| and| there|.| Inte|gers| add| exactly|,| so| the| cart| adds| cents| and| formats| them| only| at| the| edge|,| when| it| prints| a| price| for| a| person|.|
finish_reason: stop
```

Same pieces, different wrapping. **Each chunk carries a `delta`** with the new text, and the last
one carries a `finish_reason` and no text. Underneath, it is the same server-sent events format
with no `event:` names, ending in a line that says `data: [DONE]`.
