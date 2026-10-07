---
title: When the reply does not fit
version: 2
---

The second email is the one that goes wrong:

```
Hi. My lamp from order 1043 shipped on 30 September and the tracking has had
no update since. I need it for Saturday. Can you check? João
```

The first reply to it is not JSON at all.

## One more try, with the reason

```
ana@dev:~/shop$ python extract.py data/emails/2.txt
attempt 1: not JSON: Expecting ',' delimiter
{"order_id": "1043", "category": "delivery", "summary": "No update on lamp tracking since 30 September", "urgent": true}
```

The first line is the program talking to itself on `stderr`: **attempt 1 failed, for a named
reason**: the text is not JSON, and the parser says what it expected where it gave up. `extract` then appended the bad reply and a message quoting those reasons to the
conversation, and asked again. The second reply passed. That is the whole repair loop:

```python
def extract(email, attempts=2):
    messages = [{"role": "user", "content": email}]
    for attempt in range(1, attempts + 1):
        r = model.messages.create(model="llama3.2:3b", max_tokens=300, system=SYSTEM, messages=messages, extra_body={"temperature": 0})
        text = r.content[0].text
        ticket, found = problems(text)
        if not found:
            return ticket
        print(f"attempt {attempt}: {'; '.join(found)}", file=sys.stderr)
        messages += [
            {"role": "assistant", "content": text},
            {"role": "user", "content": "That reply is not valid: " + "; ".join(found)
                                        + ". Reply again with the corrected JSON only."},
        ]
    return None
```

## Why the reason goes back

**A retry without the reason is a second sample from the same distribution.** It might pass; it
might fail the same way. The reason changes the request: the model now sees its own reply, the
rule it broke and the values the schema allows, which is the information it lacked the first time.

The same idea ran in lesson 8 section 04, where the host sent the schema errors back as a tool
result. Here there is no tool, so the error goes back as an ordinary user message.

## Knowing when to stop

`attempts=2` is the limit, and when it runs out `extract` returns `None` and the program says
**"this email goes to a person"**. That last line matters more than the loop:

- **A third and fourth try cost money and rarely fix** what the second did not.
- **A ticket that never passed must not be filed half-right.** An email filed with a guessed
  category is worse than one in a person's queue, because nobody looks at it again.
- **Count the failures.** A schema that fails often is telling you about the prompt or the
  schema, and that is a fix in your code, not in the retry count.

## Checking what a schema cannot

The repaired ticket says `"urgent": true`, a fair reading of *I need it for Saturday*, and its
summary leaves Saturday out, a fair choice in under 120 characters. **Neither is something a schema can check**. Lesson 8 section 02
had the same gap: the $21,000 in the answer was the model's conversion, and wrong by a hundred. When a value matters, compute
it from the source in code, as the shop does with cents, and use the model's field only to route.
