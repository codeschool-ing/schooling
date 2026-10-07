---
title: Streaming with the SDK
version: 2
---

Nobody parses those events by hand in application code. The SDK reads them, joins the pieces and
hands back text, and at the end it builds the same message object a plain request returns.

## Pieces, as they arrive

```python
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        print(text, end="|", flush=True)
    final = stream.get_final_message()
print()
print(final.stop_reason, final.usage.input_tokens, "in,", final.usage.output_tokens, "out")
```

```
ana@dev:~/shop$ python pieces.py
The| use| of| cents| to| store| prices| in| cart| stores| is| a| historical| convention| that| originated| from| the| United| States|.| In| the| |197|0|s|,| the| US| government| mandated| that| prices| be| displayed| in| cents| and| fractions| of| a| cent|,| as| part| of| the| Uniform| Pricing| Act|.| This| law| required| retailers| to| display| prices| in| a| way| that| was| easy| to| understand| and| compare|.| C|ents| made| it| simple| to| express| prices| and| discounts| in| a| way| that| was| intuitive| to| consumers|,| as| it| provided| a| clear| and| consistent| unit| of| measurement|.| Additionally|,| using| cents| allowed| for| more| precise| price| displays|,| making| it| easier| for| consumers| to| make| informed| purchasing| decisions|.| Over| time|,| this| convention| was| adopted| by| other| countries| and| has| since| become| a| standard| practice| in| retail| pricing|.|
end_turn 18 in, 144 out
```

The bars are where one piece ended and the next began. **A piece is roughly a token**, so it
splits where the tokenizer does: `C|ents` is two pieces, and `1970s` is four, a space, `197`, `0`
and `s`. The last line comes from `get_final_message()`, built after the stream ended, with the
`stop_reason` and the token counts a plain request would have given.

The reply is also wrong about the world: it credits the habit to a "Uniform Pricing Act" of the
1970s. The question says nothing about ana's code, so the model answered about shops in general
(lesson 1 section 10), and it answered with confidence (lesson 1 section 11). Streaming changes
when you see a reply, not what it is worth.

Two consequences for whoever displays the pieces:

- **Never assume a piece is a word.** A program that adds a space between pieces, or capitalises
  the first letter of each, produces `C ents`.
- **Append, do not replace.** Each piece is new text to add to what is on the screen; nothing in
  it repeats what came before.

## The same in OpenAI's API

```python
"""The same, through OpenAI's chat completions: chunks with a delta, then a finish_reason."""
import openai

client = openai.OpenAI()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
for chunk in client.chat.completions.create(model="llama3.2:3b", messages=ASK, stream=True):
    choice = chunk.choices[0]
    if choice.delta.content:
        print(choice.delta.content, end="|", flush=True)
    if choice.finish_reason:
        print("\nfinish_reason:", choice.finish_reason)
```

```
ana@dev:~/shop$ python openai_pieces.py
The| practice| of| storing| prices| in| cents| in| shopping| carts| is| a| long|-standing| convention| in| the| United| States|.| This| tradition| originated| in| the| |196|0|s|,| when| prices| on| merchandise| were| typically| displayed| in| cents|,| as| a| way| to| make| calculations| easier| for| cash|iers|.| When| a| customer| entered| the| store|,| the| cashier| would| scan| the| items|,| calculate| the| total| cost| in| penn|ies|,| and| then| make| change| in| dollars|.| This| system| allowed| the| cashier| to| quickly| and| accurately| process| transactions|,| as| well| as| to| break| down| change| into| smaller| denomin|ations|.| Over| time|,| the| use| of| cents| has| become| ingr|ained| in| shopping| culture|,| despite| the| widespread| adoption| of| digital| payment| systems| and| electronic| cash| registers|.| Today|,| customers| often| take| the| presence| of| cents| in| shopping| carts| as| a| given|,| without| questioning| the| decision| to| use| this| system| as| the| default|.|
finish_reason: stop
```

Different pieces, because it is a second draw, and the same wrapping underneath: `cash|iers`,
`penn|ies`, `denomin|ations`. **Each chunk carries a `delta`** with the new text, and the last one
carries a `finish_reason` and no text. Underneath, it is the same server-sent events format with no
`event:` names, ending in a line that says `data: [DONE]`.
