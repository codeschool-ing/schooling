---
title: Your own lab
version: 2
---

Everything this course runs, it runs on your computer: Python, a language model served by **Ollama**, and the small shop the agents work for. Nothing is rented and nothing needs an account. This section builds that machine, and every lesson after it assumes it is there.

## Three ways to have the machine

| path | what it costs your computer | |
|---|---|---|
| **installed**, on the computer in front of you | about 5 GB of disk and 4 GB of free memory while a model answers | **recommended** |
| in a virtual machine, Ubuntu Server 24.04 LTS | the same, plus the guest's own: give it 8 GB of memory, 4 processors and 30 GB of disk | when you would rather keep your own system clean |
| online, a rented Linux machine with root | nothing locally; a machine with 8 GB of memory, billed by the hour | when your computer cannot run a model at all |

**Installed is the recommendation because a model is the one program here that wants the whole computer.** Ollama runs natively on Linux, macOS and Windows, and on the two that have one it uses the graphics chip. A virtual machine sees none of that: its model runs on the processors it was given, and slower. Every transcript in this course was recorded on Ubuntu 24.04, so on Linux your terminal will look most like the lessons; on macOS and Windows the commands are the same once Python and Ollama are in.

For a virtual machine, use the hypervisor your system already has: **Hyper-V** on Windows, **UTM** on macOS, and **KVM with virt-manager** on Linux. Install Ubuntu Server 24.04 LTS in it and follow the Linux steps below. For the online path, any provider that sells a small Linux machine by the hour will do; a free tier that happens to exist today may not exist when you reach lesson 18, so do not plan on one.

## Ollama and the models

On Linux, Ollama's own script installs it and starts it as a service; on macOS and Windows, the installer from `ollama.com/download` does the same.

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

One setting matters before anything runs. Ollama gives each conversation a **context of 4096 tokens** unless told otherwise, and an agent with a handful of tools and a few steps behind it passes that quickly. What does not fit is cut from the start of the conversation, without an error. This course uses 8192:

```sh
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '[Service]\nEnvironment="OLLAMA_CONTEXT_LENGTH=8192"\n' | sudo tee /etc/systemd/system/ollama.service.d/context.conf
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

On macOS and Windows, set `OLLAMA_CONTEXT_LENGTH` to `8192` as an environment variable of your account and restart Ollama. Then fetch the models:

```sh
ollama pull llama3.2:3b     # the model every lesson uses
ollama pull all-minilm      # the embedding model behind the help-centre search
ollama pull llama3.2:1b     # a smaller model: lesson 18 compares it, and a weaker computer can use it throughout
ollama pull qwen2.5:3b      # lesson 9 only, which says why
```

**`llama3.2:3b` is the course's model**, the same one every AI course on this platform recommends, so if you set it up for another course you already have it. It is small: three billion parameters, where the models behind paid APIs have hundreds of times more. It will call the wrong tool now and then, invent a detail, or stop early. The lessons show those runs as they happened, because a loop that only ever meets a perfect model teaches nothing about the loop.

## Python and the libraries

The libraries need Python 3.12 or newer. Ubuntu 24.04 comes with 3.12; on Ubuntu, the virtual-environment module is a package of its own.

```sh
sudo apt install python3-venv
mkdir ~/agents && cd ~/agents
python3 -m venv .venv
. .venv/bin/activate
pip install anthropic==1.11.0 openai==3.24.0 mcp==2.3.0 \
  openai-agents==0.23.1 claude-agent-sdk==0.2.163 google-adk==2.11.0 litellm==1.83.0 \
  jsonschema==4.26.0 pytest==9.1.1 uvicorn==0.54.0
```

These are the versions every transcript was made with. A newer one will mostly work, and where it does not, the error names the library.

**The providers' libraries talk to Ollama because Ollama speaks their languages.** It answers Anthropic's Messages API at `/v1/messages` and OpenAI's Chat Completions at `/v1/chat/completions`, tool calls included, so the `anthropic` and `openai` packages need only to be told where it is. Save this as `~/agents/ollama.env`:

```sh
# ollama.env: point the providers' SDKs at the Ollama on this machine.
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export OLLAMA_API_BASE=http://127.0.0.1:11434
```

and append it to the environment's activation script, so that `. .venv/bin/activate` sets all five from now on:

```sh
cat ollama.env >> .venv/bin/activate
. .venv/bin/activate
```

The keys are placeholders: Ollama checks none, and the libraries refuse to start without one.

**If you would rather use a provider's API**, with a key of your own and the bill that comes with it, the programs are the same. Leave the base URLs out, put your real keys in their place, and change `llama3.2:3b` in each program to a model that provider sells. The answers will be better worded than the ones in the lessons, and the loops around them will not change.

## The shop

The agents in this course work for **Marginalia**, an online bookshop that does not exist: the one `embeddings-vectors` searched by meaning and `rag` answered from. Its orders, its books on sale and fourteen articles of its help centre fit in one program. Save it as `~/agents/make_shop.py`:

```python
"""make_shop.py: writes Marginalia's data into ./data, from nothing.

Marginalia is an online bookshop that does not exist. Everything here was
written for the course: the people, the orders, the books on sale and the
help centre. Amounts are whole cents. Run it again to start over.
"""
import json
import sqlite3
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"

SCHEMA = """
CREATE TABLE customers (id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, city TEXT NOT NULL);
CREATE TABLE prices (book_id TEXT PRIMARY KEY, cents INTEGER NOT NULL, stock INTEGER NOT NULL);
CREATE TABLE orders (
  id TEXT PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers(id), placed_on TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('received', 'packed', 'shipped', 'delivered', 'cancelled')),
  delivered_on TEXT, shipping INTEGER NOT NULL, tracking TEXT);
CREATE TABLE order_lines (order_id TEXT NOT NULL REFERENCES orders(id), book_id TEXT NOT NULL,
  quantity INTEGER NOT NULL, cents INTEGER NOT NULL);
CREATE TABLE refunds (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL REFERENCES orders(id),
  cents INTEGER NOT NULL, reason TEXT NOT NULL, approved_by TEXT NOT NULL, at TEXT NOT NULL);
"""

CUSTOMERS = [
    ("c-101", "Bia Moreira", "bia@example.com", "Recife"),
    ("c-102", "Caio Fontes", "caio@example.com", "Curitiba"),
    ("c-103", "Davi Rocha", "davi@example.com", "Belém"),
    ("c-104", "Elisa Prado", "elisa@example.com", "Porto Alegre"),
    ("c-105", "Fábio Lins", "fabio@example.com", "Salvador"),
    ("c-106", "Gabi Teles", "gabi@example.com", "Campinas"),
]
# id, customer, placed on, status, delivered on, shipping in cents, tracking code
ORDERS = [
    ("M-1041", "c-101", "2026-09-02", "delivered", "2026-09-05", 0, "BR5512340001"),
    ("M-1042", "c-101", "2026-09-20", "delivered", "2026-09-24", 490, "BR5512340002"),
    ("M-1043", "c-102", "2026-09-28", "shipped", None, 0, "BR5512340003"),
    ("M-1044", "c-103", "2026-08-11", "delivered", "2026-08-14", 0, "BR5512340004"),
    ("M-1045", "c-104", "2026-10-01", "packed", None, 490, None),
    ("M-1046", "c-105", "2026-10-02", "received", None, 0, None),
    ("M-1047", "c-106", "2026-09-15", "delivered", "2026-09-18", 0, "BR5512340007"),
    ("M-1048", "c-102", "2026-09-30", "cancelled", None, 490, None),
]
LINES = [
    ("M-1041", "b01", 1, 3490), ("M-1041", "b06", 1, 2990), ("M-1042", "b39", 1, 2990),
    ("M-1043", "b13", 1, 2490), ("M-1043", "b14", 1, 2590), ("M-1043", "b26", 1, 5990),
    ("M-1044", "b36", 1, 4590), ("M-1045", "b41", 1, 2290), ("M-1046", "b31", 1, 4990),
    ("M-1046", "b33", 1, 5490), ("M-1047", "b19", 2, 3890), ("M-1048", "b40", 1, 3290),
]
# id, title, author, year, price in cents, copies in stock
BOOKS = [
    ("b01", "Pride and Prejudice", "Jane Austen", 1813, 3490, 12),
    ("b03", "Jane Eyre", "Charlotte Brontë", 1847, 3990, 4),
    ("b06", "Persuasion", "Jane Austen", 1817, 2990, 7),
    ("b07", "The Hound of the Baskervilles", "Arthur Conan Doyle", 1902, 2790, 0),
    ("b11", "The Mysterious Affair at Styles", "Agatha Christie", 1920, 3190, 9),
    ("b13", "The Time Machine", "H. G. Wells", 1895, 2490, 15),
    ("b14", "The War of the Worlds", "H. G. Wells", 1898, 2590, 3),
    ("b19", "Dracula", "Bram Stoker", 1897, 3890, 6),
    ("b26", "The Count of Monte Cristo", "Alexandre Dumas", 1844, 5990, 2),
    ("b31", "Moby-Dick", "Herman Melville", 1851, 4990, 5),
    ("b33", "Middlemarch", "George Eliot", 1871, 5490, 1),
    ("b36", "Crime and Punishment", "Fyodor Dostoevsky", 1866, 4590, 8),
    ("b39", "Dom Casmurro", "Machado de Assis", 1899, 2990, 20),
    ("b40", "The Posthumous Memoirs of Brás Cubas", "Machado de Assis", 1881, 3290, 11),
    ("b41", "Alice's Adventures in Wonderland", "Lewis Carroll", 1865, 2290, 14),
    ("b55", "The Adventures of Sherlock Holmes", "Arthur Conan Doyle", 1892, 3590, 0),
    ("b59", "Sense and Sensibility", "Jane Austen", 1811, 2990, 6),
]
# id, title, body
HELP = [
    ("h01", "Changing an order after you have placed it",
     "You can change the delivery address or remove an item while the order still says Received. Once it says Packed, the parcel has left the shelf and the order can no longer be edited. Cancel it instead and place a new one."),
    ("h02", "Cancelling an order",
     "Open the order in your account and choose Cancel order. If the order has already shipped, the button is gone and you will need to send the parcel back when it arrives. A cancelled order is refunded to the card it was paid with."),
    ("h05", "Orders for schools and libraries",
     "Institutions buying twenty or more copies of one title receive 15% off the cover price and can pay by invoice within 30 days. Send the list of titles and quantities from an institutional email address to schools@marginalia.example."),
    ("h07", "Delivery times and costs",
     "Standard delivery takes three to five working days and is free on orders over 40. Below that it costs 4.90. Express delivery arrives the next working day if you order before 2 pm and costs 9.90."),
    ("h08", "Tracking a parcel",
     "When the parcel leaves our warehouse we email you a tracking link from the carrier. The link may show nothing for the first twelve hours, until the carrier scans the parcel at its depot. After that it updates at each step of the journey."),
    ("h09", "A parcel marked as delivered that never arrived",
     "Check with neighbours and around the building first, because carriers often leave parcels in a safe place. If it has not turned up after 48 hours, tell us and we will open a claim with the carrier and send a replacement or a refund, whichever you prefer."),
    ("h12", "Damaged books on arrival",
     "If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days. We replace damaged books at no cost and you do not need to send the damaged copy back."),
    ("h14", "How to return a book",
     "You have 30 days from delivery to return a printed book in the condition you received it. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free."),
    ("h15", "When your refund arrives",
     "We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. Gift cards are refunded as store credit."),
    ("h17", "Items that cannot be returned",
     "Personalised and signed copies, opened jigsaw puzzles and anything bought in the clearance section cannot be returned unless they arrive damaged. E-books follow their own rules, described in the e-books section."),
    ("h20", "Payment methods we accept",
     "We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery."),
    ("h22", "Charged twice for one order",
     "When a payment fails and you try again, the bank sometimes holds both amounts for a few days. Only one is collected and the other disappears without action from you within seven days. If both are still there after that, send us the order number and a bank statement."),
    ("h24", "Using a gift card",
     "Enter the sixteen-digit code at checkout. A gift card can pay for part of an order and the rest can go on a card. Gift cards are valid for two years from purchase and cannot be exchanged for cash."),
    ("h33", "Refunds for e-books",
     "An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. Once it has been downloaded, the sale is final, as the law allows for digital content delivered with your consent."),
]

DATA.mkdir(exist_ok=True)
(DATA / "shop.db").unlink(missing_ok=True)
db = sqlite3.connect(DATA / "shop.db")
db.executescript(SCHEMA)
db.executemany("INSERT INTO customers VALUES (?, ?, ?, ?)", CUSTOMERS)
db.executemany("INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?)", ORDERS)
db.executemany("INSERT INTO order_lines VALUES (?, ?, ?, ?)", LINES)
db.executemany("INSERT INTO prices VALUES (?, ?, ?)", [(b[0], b[4], b[5]) for b in BOOKS])
db.commit()
with open(DATA / "books.jsonl", "w") as f:
    for id, title, author, year, *_ in BOOKS:
        f.write(json.dumps({"id": id, "title": title, "author": author, "year": year}, ensure_ascii=False) + "\n")
with open(DATA / "help.jsonl", "w") as f:
    for id, title, body in HELP:
        f.write(json.dumps({"id": id, "title": title, "body": body}) + "\n")
(DATA / "help.vectors.json").unlink(missing_ok=True)
print(f"{len(ORDERS)} orders, {len(BOOKS)} books and {len(HELP)} help articles in {DATA}")
```

And the functions the agents will be given to call, as `~/agents/shop.py`. They know nothing about models: each lesson wraps them in whatever a model needs, a schema, a decorator or an MCP server, and they stay the same underneath. The search is the one from `embeddings-vectors`, by meaning, with `all-minilm` turning text into vectors.

```python
"""shop.py: Marginalia's data as plain functions, which every lesson wraps as tools.

Nothing here knows about models, tools or MCP. The help-centre search asks
Ollama for embeddings from all-minilm, the model embeddings-vectors uses.
"""
import json
import math
import sqlite3
import urllib.request
from datetime import date
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"
TODAY = date(2026, 10, 6)   # the shop's calendar stops here, so every date in the lessons holds


def _db(readonly=True):
    mode = "ro" if readonly else "rw"
    db = sqlite3.connect(f"file:{DATA / 'shop.db'}?mode={mode}", uri=True)
    db.row_factory = sqlite3.Row
    return db


def get_order(order_id):
    """The order, its lines and its refunds, as a dict. Amounts are in cents."""
    with _db() as db:
        o = db.execute("SELECT * FROM orders WHERE id = ?", (order_id,)).fetchone()
        if o is None:
            raise LookupError(f"no order {order_id}")
        lines = db.execute("SELECT book_id, quantity, cents FROM order_lines WHERE order_id = ?",
                           (order_id,)).fetchall()
        refunded = db.execute("SELECT coalesce(sum(cents), 0) FROM refunds WHERE order_id = ?",
                              (order_id,)).fetchone()[0]
    out = dict(o)
    out["lines"] = [dict(r) for r in lines]
    out["total"] = sum(r["quantity"] * r["cents"] for r in lines) + o["shipping"]
    out["refunded"] = refunded
    return out


def get_customer(customer_id):
    with _db() as db:
        c = db.execute("SELECT * FROM customers WHERE id = ?", (customer_id,)).fetchone()
    if c is None:
        raise LookupError(f"no customer {customer_id}")
    return dict(c)


def get_book(book_id):
    """A book from the catalogue, with its price and stock."""
    for line in open(DATA / "books.jsonl"):
        b = json.loads(line)
        if b["id"] == book_id:
            with _db() as db:
                p = db.execute("SELECT cents, stock FROM prices WHERE book_id = ?", (book_id,)).fetchone()
            b.update(dict(p))
            return b
    raise LookupError(f"no book {book_id}")


def _embed(texts):
    req = urllib.request.Request("http://127.0.0.1:11434/api/embed",
                                 json.dumps({"model": "all-minilm", "input": texts}).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["embeddings"]   # each one already has length 1


def search_help(query, k=3):
    """The k help-centre articles closest in meaning to QUERY, by cosine similarity."""
    arts = [json.loads(line) for line in open(DATA / "help.jsonl")]
    cache = DATA / "help.vectors.json"
    if not cache.exists():
        cache.write_text(json.dumps(_embed([a["title"] + ". " + a["body"] for a in arts])))
    vecs = json.loads(cache.read_text())
    q = _embed([query])[0]
    scores = [math.sumprod(v, q) for v in vecs]
    best = sorted(range(len(arts)), key=lambda i: -scores[i])[:k]
    return [{"id": arts[i]["id"], "title": arts[i]["title"], "body": arts[i]["body"],
             "score": round(scores[i], 3)} for i in best]


def refund(order_id, cents, reason, approved_by):
    """Record a refund. It refuses more than is left to refund on the order."""
    order = get_order(order_id)
    left = order["total"] - order["refunded"]
    if cents <= 0 or cents > left:
        raise ValueError(f"cannot refund {cents} cents on {order_id}: {left} left to refund")
    with _db(readonly=False) as db:
        db.execute("INSERT INTO refunds (order_id, cents, reason, approved_by, at) VALUES (?, ?, ?, ?, ?)",
                   (order_id, cents, reason, approved_by, TODAY.isoformat()))
    return {"order_id": order_id, "refunded": cents, "left": left - cents}
```

## Checking it

Run the shop's program once, then check each piece. The `ollama run` line asks the model one question with nothing around it; `ollama ps` straight after shows what the model costs while it is loaded.

```
@@CHECK@@
```

Read the sizes off your own screen rather than this one if your computer differs, but these are the numbers to plan for: `llama3.2:3b` is a 2.0 GB download and takes @@MEM@@ of memory while it answers, and the libraries take @@VENV@@. The model stays in memory for five minutes after its last answer and then leaves on its own. On a computer with less than 8 GB in total, use `llama3.2:1b` wherever a lesson says `llama3.2:3b`: it is 1.3 GB, and its mistakes are more frequent and of the same kinds.

**Every time you come back to the course**, open a terminal and type `cd ~/agents && . .venv/bin/activate`. Ollama keeps running as a service; the environment does not.
