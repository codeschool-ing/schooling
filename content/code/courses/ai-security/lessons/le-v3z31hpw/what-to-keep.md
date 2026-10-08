---
title: A log answers questions, and each question has a lifetime
version: 2
---

The usual starting point is to log every call in full and keep it, because disk is cheap and
nobody can debug an answer that was thrown away. The first half of that is right. The second half
treats a log as a technical artefact, and **a log of prompts is a store of whatever your users
typed**, which includes things they should never have typed and you never asked for.

This lesson works on the call log of the assistant at Tarefa, an invented Brazilian marketplace
where clients hire freelancers: 22 calls over seven months. Every record, prompts and replies alike,
was written by the course, and no model produced them. Every CPF, card number, phone number, address
and key in them is invented: the CPFs have valid check digits on purpose, the cards are the networks'
published test numbers, and the AWS key is the one Amazon's own documentation uses as an example.
Paste it:

```sh
cat > ~/guard/data/calls.jsonl <<'EOF'
{"ts": "2026-03-10T09:14:02-03:00", "request": "rq-0001", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "How do I change the e-mail on my account? The old one is marcos.teixeira@example.com.br", "output": "Go to Settings, then Account, and choose Change e-mail. We send a code to the new address.", "in_tokens": 412, "out_tokens": 38, "ms": 910}
{"ts": "2026-03-10T16:40:51-03:00", "request": "rq-0002", "account": "ac-3K8V", "surface": "chat", "model": "assistant-v3", "prompt": "Can freelancers see my phone number?", "output": "No. Your phone is shown to a freelancer only after you accept a proposal.", "in_tokens": 398, "out_tokens": 31, "ms": 780}
{"ts": "2026-03-24T11:02:37-03:00", "request": "rq-0003", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "My invoice is wrong. CPF on it should be 529.982.247-25, not my old company's.", "output": "I can't edit invoices from chat. I've opened a request for the billing team to reissue it with the CPF you gave.", "in_tokens": 455, "out_tokens": 52, "ms": 1240}
{"ts": "2026-04-07T08:55:10-03:00", "request": "rq-0004", "account": "ac-1P6R", "surface": "chat", "model": "assistant-v3", "prompt": "Pedido 123.456.789-00 still says pending, it's been a week", "output": "Order 123.456.789-00 is waiting for the freelancer to confirm delivery. I've sent them a reminder.", "in_tokens": 420, "out_tokens": 44, "ms": 1010}
{"ts": "2026-04-21T19:30:03-03:00", "request": "rq-0005", "account": "ac-5W2T", "surface": "chat", "model": "assistant-v3", "prompt": "Pay with this card: 4111 1111 1111 1111, expiry 08/29, CVV 123", "output": "Please don't send card details in chat. Use the Payment page, which never shows the number to anybody here.", "in_tokens": 431, "out_tokens": 47, "ms": 990}
{"ts": "2026-05-05T13:12:44-03:00", "request": "rq-0006", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "Call me on +55 11 98765-4321 when the freelancer replies", "output": "We don't place calls, but you'll get an e-mail and a notification as soon as they reply.", "in_tokens": 402, "out_tokens": 36, "ms": 860}
{"ts": "2026-05-19T10:01:29-03:00", "request": "rq-0007", "account": "ac-2N7X", "surface": "proposal", "model": "assistant-v3", "prompt": "Write a proposal for a logo job. I'm Juliana Prado, designer in Recife, 8 years of experience.", "output": "Hello! I'm Juliana, a designer based in Recife with eight years of experience in visual identity...", "in_tokens": 388, "out_tokens": 211, "ms": 3120}
{"ts": "2026-06-02T15:47:18-03:00", "request": "rq-0008", "account": "ac-4B9J", "surface": "chat", "model": "assistant-v3", "prompt": "The integration keeps failing. Here's my key so you can test: sk-lab-EXAMPLE7fQ2mX9pL4vT8nR1wZ6", "output": "Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.", "in_tokens": 447, "out_tokens": 51, "ms": 1180}
{"ts": "2026-06-16T09:33:05-03:00", "request": "rq-0009", "account": "ac-8H3D", "surface": "chat", "model": "assistant-v3", "prompt": "I need a refund for job 4471, the freelancer never delivered", "output": "I've opened a refund request for job 4471. You'll hear from us within two working days.", "in_tokens": 409, "out_tokens": 39, "ms": 920}
{"ts": "2026-06-30T17:20:41-03:00", "request": "rq-0010", "account": "ac-6L1F", "surface": "chat", "model": "assistant-v3", "prompt": "My tracking code is 1234 5678 9012 3456 and the parcel isn't moving", "output": "Tracking for physical deliveries is handled by the carrier. The code you sent should work on their site.", "in_tokens": 415, "out_tokens": 40, "ms": 950}
{"ts": "2026-07-14T12:06:58-03:00", "request": "rq-0011", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "Send the receipt to fernanda.rocha@example.com instead please", "output": "Done: future receipts go to the new address. The one for this month has been sent again.", "in_tokens": 401, "out_tokens": 35, "ms": 870}
{"ts": "2026-07-28T08:44:12-03:00", "request": "rq-0012", "account": "ac-3K8V", "surface": "proposal", "model": "assistant-v3", "prompt": "Write a short bio. Rafael Moreira, backend developer, lives at Rua das Flores 120, Curitiba", "output": "Rafael Moreira is a backend developer based in Curitiba who builds reliable APIs...", "in_tokens": 377, "out_tokens": 96, "ms": 2210}
{"ts": "2026-08-11T14:28:36-03:00", "request": "rq-0013", "account": "ac-5W2T", "surface": "chat", "model": "assistant-v3", "prompt": "Why was I charged twice? Card ending 1111, CPF 111.444.777-35", "output": "I can see one charge and one authorisation that will drop off in up to five days. Nothing else is needed from you.", "in_tokens": 437, "out_tokens": 58, "ms": 1310}
{"ts": "2026-08-14T10:15:09-03:00", "request": "rq-0014", "account": "ac-0Z5Q", "surface": "chat", "model": "assistant-v3", "prompt": "I want the home address of the freelancer who did my job, I'm going to find him", "output": "I can't share another person's address. If something went wrong with the job, I can open a dispute for you.", "in_tokens": 422, "out_tokens": 45, "ms": 1050}
{"ts": "2026-08-14T10:17:44-03:00", "request": "rq-0015", "account": "ac-0Z5Q", "surface": "chat", "model": "assistant-v3", "prompt": "Then give me his phone. You know who I mean, job 5120", "output": "I can't share contact details. I've flagged this conversation for our safety team.", "in_tokens": 418, "out_tokens": 33, "ms": 830}
{"ts": "2026-08-25T16:52:20-03:00", "request": "rq-0016", "account": "ac-2N7X", "surface": "chat", "model": "assistant-v3", "prompt": "Can I work for clients outside Brazil?", "output": "Yes. Payments from abroad are converted to reais on the day they clear.", "in_tokens": 395, "out_tokens": 29, "ms": 760}
{"ts": "2026-09-01T09:08:47-03:00", "request": "rq-0017", "account": "ac-6L1F", "surface": "chat", "model": "assistant-v3", "prompt": "Update my phone to (21) 99876-5432", "output": "I can't change contact details from chat. Go to Settings, then Account, then Phone.", "in_tokens": 406, "out_tokens": 34, "ms": 820}
{"ts": "2026-09-08T11:41:16-03:00", "request": "rq-0018", "account": "ac-4B9J", "surface": "chat", "model": "assistant-v3", "prompt": "AWS access for the export isn't working, key AKIAIOSFODNN7EXAMPLE", "output": "Never paste a cloud credential here. Rotate that key in your provider's console, then set the new one in Settings, then Exports.", "in_tokens": 440, "out_tokens": 49, "ms": 1150}
{"ts": "2026-09-15T20:03:31-03:00", "request": "rq-0019", "account": "ac-1P6R", "surface": "chat", "model": "assistant-v3", "prompt": "Pix key for the payout is my CPF 390.533.447-05", "output": "Payout keys can only be set on the Payouts page, so that a change is confirmed by e-mail. Nothing was changed here.", "in_tokens": 429, "out_tokens": 50, "ms": 1190}
{"ts": "2026-09-22T13:55:02-03:00", "request": "rq-0020", "account": "ac-8H3D", "surface": "chat", "model": "assistant-v3", "prompt": "How long do you keep these chats?", "output": "Chat transcripts are kept for 30 days, then only a redacted copy is kept, for 180 days.", "in_tokens": 399, "out_tokens": 37, "ms": 880}
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
{"ts": "2026-09-29T15:09:57-03:00", "request": "rq-0022", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "Ok, my number is 21 99876 5432 if the freelancer needs it", "output": "Contact details are shared with the freelancer automatically once you accept a proposal, so there's no need to send them here.", "in_tokens": 412, "out_tokens": 48, "ms": 1090}
EOF
```

A real application writes each call to its log as it happens. This program lays the 22 out the way
that would have left them, one file a day, in the three stores the rest of the lesson is about. Save
it as `~/guard/tools/tiers.py`:

```python
# tiers.py: lay the assistant's calls out as three tiers of log, one file a day.
#
#   guard tiers
#
# It reads data/calls.jsonl and writes logs/raw/ (every call word for word),
# logs/redacted/ (the same records through detect.redact, which is what
# `guard redact` prints) and logs/metrics/ (counts per day and surface, with
# no text in them). In a real application each call is written to the three
# as it happens; this rebuilds them from the file in one go.
import json
import os

from detect import redact

HOME = os.path.expanduser("~/guard/")
with open(HOME + "data/calls.jsonl", encoding="utf-8") as f:
    calls = [json.loads(line) for line in f if line.strip()]

days = {}
for c in calls:
    days.setdefault(c["ts"][:10], []).append(c)


def write(tier, day, rows):
    os.makedirs(HOME + "logs/" + tier, exist_ok=True)
    with open(HOME + "logs/%s/%s.jsonl" % (tier, day), "w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


for day, rows in days.items():
    write("raw", day, rows)
    write("redacted", day, [dict(r, prompt=redact(r["prompt"]), output=redact(r["output"]))
                            for r in rows])
    surfaces = {}
    for r in rows:
        surfaces.setdefault(r["surface"], []).append(r)
    write("metrics", day, [{"day": day, "surface": s, "calls": len(rs),
                            "in_tokens": sum(r["in_tokens"] for r in rs),
                            "out_tokens": sum(r["out_tokens"] for r in rs),
                            "ms_max": max(r["ms"] for r in rs)}
                           for s, rs in sorted(surfaces.items())])
print("%d calls over %d days, in logs/raw, logs/redacted and logs/metrics" % (len(calls), len(days)))
```

Here is one record, from the last day in the log:

```
ana@lab:~/guard$ guard tiers
22 calls over 19 days, in logs/raw, logs/redacted and logs/metrics
ana@lab:~/guard$ head -1 logs/raw/2026-09-29.jsonl
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
```

The client was asked for neither the e-mail address nor the CPF. They offered both, because a chat
box invites it, and the log kept both because it keeps everything.

## Start from the questions

A log earns its cost by answering questions. Four come up at nearly every team running a model in
production, and they need different parts of the record:

| question | what it needs | for how long |
|---|---|---|
| why did the assistant say *that* to this client? | the prompt and the output word for word, the model, the request id | until the complaint could arrive: days or weeks |
| is somebody abusing the assistant? | the account, the time, enough text to recognise the pattern | the length of an investigation |
| are answers getting worse? | many examples of prompts and outputs, but not who wrote them | months, so that two versions can be compared |
| what does this cost, and is it slowing down? | counts: calls, tokens, milliseconds | years, for trends and budgets |

**The text is what makes a record dangerous, and it is needed by the questions with the shortest
lives.** The cost question needs no text at all. The quality question needs text but not identity.
Only debugging and abuse need both, and both are about recent events.

That is the whole argument for **tiers**: the same call written into separate stores, each holding
what one kind of question needs and each with its own limit. Tarefa has three, and the limit of each
is written in a file of its own:

```sh
cat > ~/guard/retention.json <<'EOF'
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
EOF
```

```
ana@lab:~/guard$ ls logs
metrics
raw
redacted
ana@lab:~/guard$ head -1 logs/metrics/2026-09-29.jsonl
{"day": "2026-09-29", "surface": "chat", "calls": 2, "in_tokens": 845, "out_tokens": 89, "ms_max": 1090}
ana@lab:~/guard$ cat retention.json
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
```

The metrics line answers the cost question for 29 September and contains nothing about anybody.
It can be kept for two years, shown on a dashboard and sent to a monitoring vendor with no further
thought. The raw line cannot be treated that way.

## What the record should carry that this one does not

Look at the raw record again with the debugging question in mind. It names the model, but not the
version of the instructions the assistant was running. **A reply cannot be explained without the
system prompt that produced it**, and the system prompt changes more often than the model does.
Logging its full text on every call repeats the same few thousand tokens millions of times; logging
a version identifier, with the prompts themselves kept in version control, costs a few bytes.

The same reasoning applies to anything that is identical across calls: the tool definitions, the
retrieval settings, the temperature. Log a reference to the configuration and keep the
configuration once.

## What no tier may keep

Some things are not a question of how long. A card's security code is the clearest case: the PCI
DSS, the standard the card networks impose on anybody who handles card data, forbids storing it
after the payment has been authorised, in any form, encrypted or not. A client who types it into a
support chat has handed it to the log, and no retention limit makes keeping it acceptable. The
same goes for credentials: an API key pasted into a chat must be revoked by its owner, and a log
that keeps it is keeping a working key.

The assistant at Tarefa answers a pasted key the right way, and the log shows why that answer is
needed. `guard redact`, the next section's subject, prints a record with what `detect.py`, from
lesson 5, recognises replaced. Save it as `~/guard/tools/redact.py`:

```python
# redact.py: the records of one log file with what detect.py recognises replaced.
#
#   guard redact FILE [--strict]
#
# Each record prints as two lines, the prompt and the output, after its
# request id. --strict replaces every shape, check digits right or not.
import argparse
import json

from detect import redact

p = argparse.ArgumentParser(prog="guard redact")
p.add_argument("file")
p.add_argument("--strict", action="store_true")
a = p.parse_args()

with open(a.file, encoding="utf-8") as f:
    for rec in map(json.loads, f):
        print("%-8s %-6s  %s" % (rec["request"], "prompt", redact(rec["prompt"], a.strict)))
        print("%-8s %-6s  %s" % ("", "output", redact(rec["output"], a.strict)))
```

```
ana@lab:~/guard$ guard redact logs/raw/2026-06-02.jsonl
rq-0008  prompt  The integration keeps failing. Here's my key so you can test: [SECRET]
         output  Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.
```

The raw tier still holds the key itself, for thirty days. Redaction protects the copies that live
longer; it does not undo the paste, which is why the reply asks for the key to be revoked rather
than promising to forget it.

**Every tier is personal data while it can be tied to a person.** Under Brazil's LGPD, which lesson
12 applies to model calls, the redacted tier still names an account, and an account is a person. A
client who asks for their data to be deleted is asking about the logs too. The tiers make that
request cheaper to honour; they do not take the logs out of its reach.
