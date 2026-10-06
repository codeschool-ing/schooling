"""Making a long conversation short: pin what must survive word for word, summarise the rest, keep the
latest turns as they were."""
import re

import tiktoken
from memory import ORDER
from openai import OpenAI

client = OpenAI()
enc = tiktoken.get_encoding("cl100k_base")
# A sentence is pinned when it carries something a later turn may need exactly: an identifier, or a
# choice the customer made. The patterns are the team's, written down and tested like any code.
PIN = re.compile(rf"{ORDER.pattern}|\b(only|please|would like|want|instead|should go to)\b", re.I)
KEEP = 3


def tokens(text):
    return len(enc.encode(text))


def sentences(text):
    return [s for s in re.split(r"(?<=[.!?])\s+(?=[A-Z])", text.strip()) if s]


def summarise(turns, words):
    """extract-1's summary of the turns, in at most WORDS words."""
    reply = client.chat.completions.create(model="extract-1", messages=[
        {"role": "system", "content": f"Summarise the conversation in at most {words} words."},
        *({"role": "user", "content": t} for t in turns)])
    return reply.choices[0].message.content


def pinned(turns):
    return [s for t in turns for s in sentences(t) if PIN.search(s)]


def compact(turns, words=30, keep=KEEP):
    """The pinned sentences of the older turns, a summary of what is left of them, and the last KEEP
    turns as they were."""
    older, recent = turns[:-keep], turns[-keep:]
    pins = pinned(older)
    rest = [s for t in older for s in sentences(t) if s not in pins]
    return {"pinned": pins, "summary": summarise(rest, words) if rest else "", "recent": recent}


def text_of(compacted):
    return "\n".join(compacted["pinned"] + [compacted["summary"]] + compacted["recent"])
