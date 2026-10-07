---
title: Measuring the endpoint on your own messages
version: 2
---

A vendor publishes how well its classifier does on its own test sets. Those numbers describe
messages the vendor collected, in the languages it chose, labelled by its rules. **The number that
decides anything at Tarefa is the one measured on Tarefa's messages**, and the only way to get it is
a set of real messages with a label a person gave each one, run through the endpoint.

`data/forum.jsonl` is that set for this lesson: sixty forum messages, each labelled with the categories
a person would put it in, or none. **The messages and the labels were written by the course.** A
real set would be sampled from what users actually post, and labelled by two people working apart,
so that the disagreement between them is measured too; the course `prompt-reliability` measures that
agreement with a statistic built for it. Paste it:

```sh
cat > ~/guard/data/forum.jsonl <<'EOF'
{"id": "m01", "lang": "en", "labels": ["harassment"], "text": "You are an idiot and everybody here knows it"}
{"id": "m02", "lang": "en", "labels": ["harassment"], "text": "Nobody wants your useless designs, quit already"}
{"id": "m03", "lang": "en", "labels": ["harassment"], "text": "What a pathetic excuse for a developer"}
{"id": "m04", "lang": "en", "labels": ["harassment"], "text": "Shut up, you clown"}
{"id": "m05", "lang": "en", "labels": ["harassment"], "text": "You're a moron if you think that's a logo"}
{"id": "m06", "lang": "en", "labels": ["harassment"], "text": "Get lost, loser"}
{"id": "m07", "lang": "en", "labels": ["harassment"], "text": "Your work is garbage and so are you"}
{"id": "m08", "lang": "en", "labels": ["harassment"], "text": "u r an id1ot"}
{"id": "m09", "lang": "en", "labels": ["harassment"], "text": "Typical lazy freelancer, worthless"}
{"id": "m10", "lang": "pt", "labels": ["harassment"], "text": "Seu idiota, ninguém te contrata"}
{"id": "m11", "lang": "pt", "labels": ["harassment"], "text": "Vai catar coquinho, incompetente"}
{"id": "m12", "lang": "en", "labels": ["harassment"], "text": "Nobody asked for your opinion, dumb"}
{"id": "m13", "lang": "en", "labels": ["harassment"], "text": "You should be ashamed, stupid"}
{"id": "m14", "lang": "en", "labels": ["harassment"], "text": "What a clown show, you clueless amateur"}
{"id": "m15", "lang": "en", "labels": ["harassment"], "text": "Such a brilliant idea, genius. Really."}
{"id": "m16", "lang": "en", "labels": ["threat"], "text": "I know where you live"}
{"id": "m17", "lang": "en", "labels": ["threat"], "text": "Deliver tomorrow or you'll regret it"}
{"id": "m18", "lang": "en", "labels": ["threat"], "text": "Watch your back"}
{"id": "m19", "lang": "en", "labels": ["threat"], "text": "I'm going to find you"}
{"id": "m20", "lang": "pt", "labels": ["threat"], "text": "Sei onde você mora"}
{"id": "m21", "lang": "en", "labels": ["threat"], "text": "People like you get hurt"}
{"id": "m22", "lang": "en", "labels": ["spam"], "text": "Earn R$ 5000 a week from home, click here"}
{"id": "m23", "lang": "en", "labels": ["spam"], "text": "Free followers! Visit cheap-followers.example now"}
{"id": "m24", "lang": "en", "labels": ["spam"], "text": "Crypto signals 100% guaranteed, DM me"}
{"id": "m25", "lang": "en", "labels": ["spam"], "text": "Buy reviews for your profile, best price"}
{"id": "m26", "lang": "en", "labels": ["spam"], "text": "Click here to claim your prize"}
{"id": "m27", "lang": "pt", "labels": ["spam"], "text": "Ganhe dinheiro rápido, chama no zap"}
{"id": "m28", "lang": "en", "labels": ["spam"], "text": "Limited offer: 5-star reviews, 50 for R$ 20"}
{"id": "m29", "lang": "en", "labels": ["spam"], "text": "Work from home and earn big, link in bio"}
{"id": "m30", "lang": "en", "labels": ["spam"], "text": "Guaranteed first page on Google, contact me"}
{"id": "m31", "lang": "en", "labels": ["spam"], "text": "Cheap logos in 24h, visit my site"}
{"id": "m32", "lang": "en", "labels": [], "text": "He called me an idiot in the chat, can a moderator look?"}
{"id": "m33", "lang": "en", "labels": [], "text": "Is 'stupid' too strong for a band name in a logo brief?"}
{"id": "m34", "lang": "en", "labels": [], "text": "My client said my work was garbage. How do I answer politely?"}
{"id": "m35", "lang": "en", "labels": [], "text": "The freelancer delivered early, great work"}
{"id": "m36", "lang": "en", "labels": [], "text": "Can I get a refund if the job is late?"}
{"id": "m37", "lang": "en", "labels": [], "text": "I will find you a better font tomorrow"}
{"id": "m38", "lang": "en", "labels": [], "text": "Click here to see my portfolio"}
{"id": "m39", "lang": "en", "labels": [], "text": "Free revision included in every package"}
{"id": "m40", "lang": "en", "labels": [], "text": "This bug is killing me, any help?"}
{"id": "m41", "lang": "en", "labels": [], "text": "Thanks, you saved my project"}
{"id": "m42", "lang": "en", "labels": [], "text": "What's the best way to price a logo?"}
{"id": "m43", "lang": "en", "labels": [], "text": "I earn about R$ 3000 a month freelancing, is that normal?"}
{"id": "m44", "lang": "en", "labels": [], "text": "Please don't share your phone number here"}
{"id": "m45", "lang": "pt", "labels": [], "text": "Obrigado pela entrega rápida!"}
{"id": "m46", "lang": "en", "labels": [], "text": "Is it ok to ask for a deposit before starting?"}
{"id": "m47", "lang": "en", "labels": [], "text": "The client keeps changing the brief"}
{"id": "m48", "lang": "en", "labels": [], "text": "Deadline moved to Friday, all good"}
{"id": "m49", "lang": "en", "labels": [], "text": "Loved the colours you picked"}
{"id": "m50", "lang": "en", "labels": [], "text": "Any tips for a first proposal?"}
{"id": "m51", "lang": "en", "labels": [], "text": "You'll regret not backing up your files, trust me"}
{"id": "m52", "lang": "en", "labels": [], "text": "My cat watches my back while I work"}
{"id": "m53", "lang": "en", "labels": [], "text": "Guaranteed delivery dates are in the contract, right?"}
{"id": "m54", "lang": "en", "labels": [], "text": "Can moderators remove a review that insults me?"}
{"id": "m55", "lang": "en", "labels": [], "text": "Need a logo for a bakery, budget R$ 800"}
{"id": "m56", "lang": "en", "labels": [], "text": "How do I report a client who threatened me?"}
{"id": "m57", "lang": "en", "labels": [], "text": "What a clown I was, I forgot the attachment"}
{"id": "m58", "lang": "en", "labels": [], "text": "Prices went up, is that legal?"}
{"id": "m59", "lang": "pt", "labels": [], "text": "Vocês emitem nota fiscal com CNPJ?"}
{"id": "m60", "lang": "en", "labels": [], "text": "Great community, glad I joined"}
EOF
```

The measurement runs the stand-in over every message and counts where it agrees with the person.
Save it as `~/guard/tools/modeval.py`:

```python
# modeval.py: the stand-in moderation endpoint measured against a person's labels.
#
#   guard modeval FILE --category C --threshold T [--show]
#   guard modeval FILE --category C --sweep
#   guard modeval FILE --category C --review R --block B [--show]
#
# FILE has one message per line, as JSON with "id", "lang", "labels" (the
# categories a person put it in) and "text". The first form counts what one
# threshold gets right and wrong; --sweep does that for nine thresholds;
# --review and --block split the messages into three lanes.
import argparse
import json

from moderation import moderate

p = argparse.ArgumentParser(prog="guard modeval")
p.add_argument("file")
p.add_argument("--category", required=True)
p.add_argument("--threshold", type=float, default=0.5)
p.add_argument("--show", action="store_true")
p.add_argument("--sweep", action="store_true")
p.add_argument("--review", type=float)
p.add_argument("--block", type=float)
a = p.parse_args()
cat = a.category

with open(a.file, encoding="utf-8") as f:
    rows = [json.loads(line) for line in f if line.strip()]
for r in rows:
    r["score"] = moderate(r["text"])[cat]
    r["yes"] = cat in r["labels"]


def confusion(rows, t):
    tp = sum(1 for r in rows if r["score"] >= t and r["yes"])
    fp = sum(1 for r in rows if r["score"] >= t and not r["yes"])
    fn = sum(1 for r in rows if r["score"] < t and r["yes"])
    return tp, fp, fn


def ratio(x, y):
    return "%.2f" % (x / y) if y else "  - "


print("category %s: %d of %d messages labelled %s by a person" % (
    cat, sum(r["yes"] for r in rows), len(rows), cat))
if a.sweep:
    print("threshold  flagged  precision  recall")
    for t in [x / 10 for x in range(1, 10)]:
        tp, fp, fn = confusion(rows, t)
        print("     %.1f      %3d       %s    %s" % (t, tp + fp, ratio(tp, tp + fp), ratio(tp, tp + fn)))
elif a.block is not None:
    lanes = {"block": [0, 0], "review": [0, 0], "publish": [0, 0]}
    for r in rows:
        lane = "block" if r["score"] >= a.block else "review" if r["score"] >= a.review else "publish"
        lanes[lane][0 if r["yes"] else 1] += 1
        if a.show and lane != "review" and (lane == "block") != r["yes"]:
            print("  %-7s %s %.2f  %s" % (lane, r["id"], r["score"], r["text"]))
    print("lane     score        labelled yes  labelled no")
    print("block    >= %.2f            %3d          %3d" % (a.block, *lanes["block"]))
    print("review   %.2f-%.2f          %3d          %3d" % (a.review, a.block, *lanes["review"]))
    print("publish  <  %.2f            %3d          %3d" % (a.review, *lanes["publish"]))
else:
    tp, fp, fn = confusion(rows, a.threshold)
    print("threshold %.2f" % a.threshold)
    print("              labelled yes  labelled no")
    print("flagged               %3d          %3d" % (tp, fp))
    print("not flagged           %3d          %3d" % (fn, len(rows) - tp - fp - fn))
    print("precision %s   recall %s" % (ratio(tp, tp + fp), ratio(tp, tp + fn)))
    for lang in sorted({r["lang"] for r in rows}):
        ltp, _, lfn = confusion([r for r in rows if r["lang"] == lang], a.threshold)
        print("  recall, messages in %s: %d of %d" % (lang, ltp, ltp + lfn))
    if a.show:
        for r in rows:
            if (r["score"] >= a.threshold) != r["yes"]:
                print("  %s %s %.2f  %s" % ("FALSE POSITIVE" if r["yes"] is False else "MISSED        ",
                                           r["id"], r["score"], r["text"]))
```

```
ana@lab:~/guard$ head -3 data/forum.jsonl
{"id": "m01", "lang": "en", "labels": ["harassment"], "text": "You are an idiot and everybody here knows it"}
{"id": "m02", "lang": "en", "labels": ["harassment"], "text": "Nobody wants your useless designs, quit already"}
{"id": "m03", "lang": "en", "labels": ["harassment"], "text": "What a pathetic excuse for a developer"}
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --threshold 0.5 --show
category harassment: 15 of 60 messages labelled harassment by a person
threshold 0.50
              labelled yes  labelled no
flagged                11            4
not flagged             4           41
precision 0.73   recall 0.73
  recall, messages in en: 11 of 13
  recall, messages in pt: 0 of 2
  MISSED         m08 0.00  u r an id1ot
  MISSED         m10 0.00  Seu idiota, ninguém te contrata
  MISSED         m11 0.00  Vai catar coquinho, incompetente
  MISSED         m15 0.00  Such a brilliant idea, genius. Really.
  FALSE POSITIVE m32 0.90  He called me an idiot in the chat, can a moderator look?
  FALSE POSITIVE m33 0.80  Is 'stupid' too strong for a band name in a logo brief?
  FALSE POSITIVE m34 0.60  My client said my work was garbage. How do I answer politely?
  FALSE POSITIVE m57 0.60  What a clown I was, I forgot the attachment
```

## Two numbers, and what each one costs somebody

The four cells are the whole result. Precision and recall are two ways of reading them:

- **Precision** is how many of the flagged messages really were harassment: 11 of 15, 0.73. The 4
  others are people whose messages were stopped for nothing.
- **Recall** is how many of the harassing messages were flagged: 11 of 15, 0.73. The 4 missed are
  messages that reached their target.

That both are 0.73 here is a coincidence of this set. They answer different questions, and they
move in opposite directions when the threshold moves, which is the next section.

## Reading the mistakes

The totals say how often; `--show` says what, and the mistakes have patterns that a total hides.

The four **missed** messages are an insult spelt with a digit, `id1ot`, a piece of sarcasm, and two
insults in Portuguese. The per-language lines put a number on the last of those: recall is 11 of 13
in English and **0 of 2 in Portuguese**. The stand-in knows no Portuguese at all, so that is its
extreme case. Real classifiers trained mostly on English text usually show a milder version of the
same gap. At a Brazilian company, a classifier evaluated only on English messages has never really
been evaluated.

The four **false positives** are more uncomfortable. `m32` is somebody reporting that they were called an idiot, and `m34` is somebody asking how to
answer a client who called their work garbage. `m33` asks about a word for a band's logo, and `m57`
is somebody calling themselves a clown. None of them is
harassment, and two are its targets asking what to do. A filter that blocks
reports of harassment teaches people that reporting gets them blocked.

Sixty messages are enough to see these patterns and too few to trust a rate to the second decimal:
two Portuguese messages say nothing precise about Portuguese recall. The set is a fixture for
learning the method. A real one grows with every message a moderator reviews, because each review is
a new label.
