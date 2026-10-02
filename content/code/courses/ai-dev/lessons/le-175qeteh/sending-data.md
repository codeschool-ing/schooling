---
title: What leaves with the request
version: 1
---

Lesson 10 asked where the data goes. This section is about what goes: **customers put things in
emails that the model does not need**, and a program that forwards the email forwards all of it.

```
Hi, the payment failed at checkout with code E1042. My card is 4111 1111 1111 1111
and my CPF is 123.456.789-09, in case you need them. Reply to marta@example.com.
```

## Sent as it came

```
ana@dev:~/shop$ python triage.py data/emails/3.txt
The checkout code E1042 means the payment timed out and no money was taken. The customer can try again in a minute.
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(json.load(sys.stdin)["request"]["messages"][0]["content"])'
Hi, the payment failed at checkout with code E1042. My card is 4111 1111 1111 1111
and my CPF is 123.456.789-09, in case you need them. Reply to marta@example.com.

```

The answer is right, and **the provider now holds a card number, a CPF and an email address** that
played no part in it. The second command prints the request as labllm received it, which is what
any provider receives.

## Removing what the model does not need

```python
"""Remove what the model does not need before a request leaves the shop."""
import re

PATTERNS = [
    ("EMAIL", re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")),
    ("CPF", re.compile(r"\b\d{3}\.\d{3}\.\d{3}-\d{2}\b")),
    ("CARD", re.compile(r"\b(?:\d[ -]?){13,19}\b")),
    ("SECRET", re.compile(r"(?i)\b(token|secret|password|api_key)\s*[=:]\s*\S{8,}")),
]


def redact(text):
    for label, pattern in PATTERNS:
        text = pattern.sub(f"[{label}]", text)
    return text
```

```
ana@dev:~/shop$ python triage.py data/emails/3.txt --redact
The checkout code E1042 means the payment timed out and no money was taken. The customer can try again in a minute.
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(json.load(sys.stdin)["request"]["messages"][0]["content"])'
Hi, the payment failed at checkout with code E1042. My card is [CARD]
and my CPF is [CPF], in case you need them. Reply to [EMAIL].
```

**Same answer, and none of the three left the shop.** The model needed the error code and the word
"payment"; it got both. The details are replaced by labels, so the model still knows a card was
mentioned and can say so in a reply, without the number.

## What a pattern can and cannot do

- **It catches formats, not meaning.** A card number written with dots, a CPF without punctuation,
  an address spelled out in words all get through. Test the patterns on real messages, and add the
  ones that slip.
- **It can take too much.** The card pattern also matches any run of 13 to 19 digits, such as a
  long tracking number. Decide which mistake is worse for the task, and test for that one.
- **Keep the real values on your side.** The reply still has to reach `[EMAIL]`. The program that
  sends it uses the address it already had; the model never needed it.
- **Secrets are personal data too.** The `SECRET` pattern is the one lesson 3's assistant used, for
  the same reason: a key pasted into a support message must not travel further.
