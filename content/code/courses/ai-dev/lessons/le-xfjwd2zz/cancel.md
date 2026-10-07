---
title: Stopping a reply
version: 2
---

A person who sees the reply going the wrong way presses Stop. **In code, stopping is closing the
connection**: the provider notices it can no longer send and stops writing. `cancel.py` stands in
for that page and stops after forty characters.

```python
"""Stop reading after the first forty characters, as a page does when someone presses Stop."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
got = ""
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
```

`break` leaves the loop, and leaving the `with` block closes the response:

```
ana@dev:~/shop$ python cancel.py
'The practice of storing prices in cents in'
```

And this is what the terminal running `ollama serve` printed at that moment, its last three lines:

```
srv          stop: cancel task, id_task = 1421
slot      release: id  0 | task 1421 | stop processing: n_tokens = 47, truncated = 0
srv  update_slots: all slots are idle
```

**Ollama stopped too.** `cancel task` is the server noticing the closed connection, and
`n_tokens = 47` is how far it got: the 38 tokens of the question and its template, and 9 of reply,
about the forty characters the script kept. A provider behaves the same way from the outside.
Whether the tokens it wrote before noticing are billed is in its terms; plan as if they are.

## What Stop has to mean

- **Close the stream to the provider**, not only the one to the browser. A relay that keeps
  reading after the page has gone pays for a reply nobody will see. In lesson 9 section 04's relay,
  a closed browser connection makes the next write fail, which leaves the `with` block and closes
  the request upstream.
- **Keep what was shown, and mark it.** Forty characters of an answer are not an answer. If the
  conversation goes on, either drop the partial reply or send it marked as cut off, so the model
  does not read it as something it finished saying.
- **Do not count it as an error.** A stopped stream is a person's choice. Logging it with the
  failures makes the error rate say something about your users instead of your system.
