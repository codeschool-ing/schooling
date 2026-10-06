"""querylog: writes data/querylog.jsonl, a week of questions asked of the help assistant.

THE LOG IS GENERATED, NOT RECORDED, and nothing about it is measured from a
real shop. It is drawn with a fixed seed from PHRASINGS below, which were
written by the course: each topic has a few ways people say it, and topics
are drawn with Zipf-like weights (the first is asked most), because that is
the shape a support queue has. Lesson 17 measures caches against it, and
what it measures is the cache, not Marginalia's customers.
"""
import json
import random
import sys
from datetime import datetime, timedelta

PHRASINGS = [
    ["How many days do I have to return a printed book?", "how many days do I have to return a printed book?",
     "how long do I have to return a book", "return window for books", "Can I still return a book I got 3 weeks ago?"],
    ["How much is express delivery?", "how much is express delivery", "express shipping price", "what does next day delivery cost"],
    ["How long after my return arrives will I get the refund?", "when do I get my refund",
     "how long does a refund take", "refund timing after return"],
    ["Above what order value is standard delivery free?", "free delivery threshold", "when is shipping free"],
    ["On how many devices can I read my e-books?", "how many devices for ebooks", "ebook device limit"],
    ["Can I cancel my order?", "how do I cancel an order", "cancel order"],
    ["Can I cancel a pre-order?", "how do I cancel a pre-order", "cancel preorder"],
    ["How long is a gift card valid?", "gift card expiry", "do gift cards expire"],
    ["Will my e-books open on a Kindle?", "kindle ebooks", "can I read on kindle"],
    ["Can I pay in instalments?", "pay in instalments", "split payment in three"],
    ["When is a standard parcel considered lost?", "my parcel is lost", "parcel not arrived after two weeks"],
    ["Who pays for the return postage?", "is returning free", "return shipping cost"],
]


def main(out, n=500, seed=11):
    rng = random.Random(seed)
    weights = [1 / (k + 1) for k in range(len(PHRASINGS))]
    users = [f"u{i:03d}" for i in range(1, 61)]
    start = datetime(2026, 9, 21, 8, 0)
    with open(out, "w") as f:
        for i in range(n):
            topic = rng.choices(range(len(PHRASINGS)), weights)[0]
            text = rng.choice(PHRASINGS[topic])
            at = start + timedelta(minutes=int(i * 7 * 24 * 60 / n) + rng.randrange(0, 15))
            f.write(json.dumps({"at": at.strftime("%Y-%m-%dT%H:%M"), "user": rng.choice(users),
                                "topic": topic + 1, "text": text}) + "\n")


if __name__ == "__main__":
    main(sys.argv[1])
