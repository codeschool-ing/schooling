"""traffic: writes data/traffic.jsonl, a week of people using Marginalia's help assistant.

THE TRAFFIC IS GENERATED, NOT RECORDED, and nothing about it is measured from a
real shop. It is drawn with a fixed seed from the phrasings below, which were
written by the course: rag's twelve topics (lab/querylog.py there), the facts
rag's eval.jsonl says a right answer to each contains, four questions the
documents do not answer, messages about an order that carry a name, an e-mail
address or a telephone number, and requests from the support team to
summarise a conversation. The names, addresses and numbers are invented, the
domains are reserved for examples, and the telephone numbers are not in use.

Each line is one request as it ARRIVES: when, who, in which session, through
which feature, and the words. What the assistant answered, and what the
person did next, are not in this file: replay.py produces them by running
the assistant, and the simulated person's reaction is decided there.

    python traffic.py data/traffic.jsonl

It also writes data/topics.json beside it: each topic's phrasings and facts,
which replay.py reads to decide whether a reply was right.
"""
import json
import os
import random
import sys
from datetime import datetime, timedelta

# (phrasings, facts): a right answer contains one of the facts; [] means the
# documents do not answer it, and the right answer is the refusal.
TOPICS = [
    (["How many days do I have to return a printed book?", "how long do I have to return a book",
      "return window for books", "Can I still return a book I got 3 weeks ago?"], ["30 days from delivery"]),
    (["How much is express delivery?", "express shipping price", "what does next day delivery cost"],
     ["9.90"]),
    (["How long after my return arrives will I get the refund?", "when do I get my refund",
      "how long does a refund take"], ["within three working days"]),
    (["Above what order value is standard delivery free?", "free delivery threshold", "when is shipping free"],
     ["free on orders over 40"]),
    (["On how many devices can I read my e-books?", "how many devices for ebooks", "ebook device limit"],
     ["up to six devices"]),
    (["How long is a gift card valid?", "gift card expiry", "do gift cards expire"], ["valid for two years"]),
    (["Will my e-books open on a Kindle?", "kindle ebooks", "can I read on kindle"],
     ["Kindle readers cannot open"]),
    (["Can I pay in instalments?", "pay in instalments", "split payment in three"], ["up to three instalments"]),
    (["When is a standard parcel considered lost?", "my parcel is lost", "parcel not arrived after two weeks"],
     ["10 working days"]),
    (["Who pays for the return postage?", "is returning free", "return shipping cost"], ["Returns are free"]),
    (["How long is the statutory right of withdrawal?", "right of withdrawal days"],
     ["seven days from delivery", "seven days of delivery"]),
    (["How long does a pickup point keep my parcel?", "pickup point how many days"], ["waits there for ten days"]),
    (["Can I place an order by phone?", "order by telephone"], []),
    (["Is there a student discount?", "student discount"], []),
    (["Which carrier do you use in Portugal?", "carrier portugal"], []),
    (["Do you have a shop in Porto Alegre where I can pick up books?", "physical shop porto alegre"], []),
]

PEOPLE = [("Joana Prado", "joana.prado@example.com", "+55 11 5550-0142"),
          ("Rafael Lima", "rafael.lima@example.org", "+55 21 5550-0187"),
          ("Beatriz Costa", "bia.costa@example.net", "+55 51 5550-0119"),
          ("Tiago Moura", "tiago.moura@example.com", "+55 31 5550-0163"),
          ("Marta Seixas", "marta.s@example.org", "+351 21 555 0174")]
ORDER = [
    "Hi, I'm {name} ({email}). My order {order} has not arrived after 12 working days. Is it lost?",
    "My parcel {order} still hasn't arrived, two weeks now. You can call me on {phone}. When is it considered lost?",
    "This is {name}, order {order}: can I still return a book I got 3 weeks ago? My email is {email}.",
    "Order {order} - I want to return it. Who pays for the return postage? {name}, {phone}",
]
ORDER_TOPIC = [8, 8, 0, 9]

CONVERSATIONS = [
    ["Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.",
     "The order had two books. Persuasion arrived with water damage on the cover.",
     "The other one, Middlemarch, is fine and I want to keep it.",
     "Can you send a new copy of Persuasion instead of a refund?"],
    ["Hello, this is Rafael Lima. My order MG-31770254 has not arrived.",
     "It was sent by standard delivery and the tracking has not changed for twelve working days.",
     "I would prefer a refund rather than waiting for a new parcel."],
]

# How many requests arrive in each hour of the day, relative to the busiest.
HOURLY = [1, 1, 1, 1, 1, 2, 3, 6, 9, 10, 10, 9, 8, 9, 10, 10, 9, 8, 8, 9, 9, 7, 4, 2]


def main(out, seed=21):
    rng = random.Random(seed)
    users = [f"u{i:03d}" for i in range(1, 121)]
    start = datetime(2026, 9, 28, 0, 0)
    rows = []
    for day in range(7):
        weekend = day >= 5
        for hour in range(24):
            n = HOURLY[hour] * (4 if weekend else 6) // 5 + rng.randrange(0, 2)
            for _ in range(n):
                at = start + timedelta(days=day, hours=hour, seconds=rng.randrange(0, 3600))
                rows.append(at)
    rows.sort()
    with open(os.path.join(os.path.dirname(out), "topics.json"), "w") as f:
        json.dump([{"topic": i + 1, "phrasings": p, "facts": facts} for i, (p, facts) in enumerate(TOPICS)],
                  f, indent=1)
    sessions = 0
    with open(out, "w") as f:
        for i, at in enumerate(rows, 1):
            sessions += 1
            r = rng.random()
            row = {"id": f"r{i:04d}", "at": at.strftime("%Y-%m-%dT%H:%M:%S"), "user": rng.choice(users),
                   "session": f"s{sessions:04d}"}
            if r < 0.72:
                weights = [1 / (k + 1) ** 0.8 for k in range(len(TOPICS))]
                t = rng.choices(range(len(TOPICS)), weights)[0]
                row.update(feature="help", topic=t + 1, text=rng.choice(TOPICS[t][0]))
            elif r < 0.90:
                k = rng.randrange(len(ORDER))
                name, email, phone = rng.choice(PEOPLE)
                order = f"MG-{rng.randrange(10000000, 99999999)}"
                row.update(feature="order", topic=ORDER_TOPIC[k] + 1,
                           text=ORDER[k].format(name=name, email=email, phone=phone, order=order))
            else:
                c = rng.choice(CONVERSATIONS)
                row.update(feature="summary", topic=None, user="staff-" + rng.choice(["ana", "caio", "lia"]),
                           text="Summarise this conversation in at most 40 words.\n" + "\n".join(c))
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main(sys.argv[1])
