---
title: Stopping a reply
version: 1
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
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
```

`break` leaves the loop, and leaving the `with` block closes the response:

```
ana@dev:~/shop$ python cancel.py
'The cart stores prices as integer cents because'
ana@dev:~/shop$ sleep 1; tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["status"], "| planned:", r["usage"]["output_tokens"], "tokens | sent before the close:", r["sent"])'
client went away | planned: 82 tokens | sent before the close: 9
```

**labllm stopped too.** It had 82 tokens planned and sent 9 before the next write found the
connection closed; its log says `client went away`. A real provider behaves the same way from the
outside. Whether the tokens it wrote before noticing are billed is in its terms; plan as if they
are.

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
