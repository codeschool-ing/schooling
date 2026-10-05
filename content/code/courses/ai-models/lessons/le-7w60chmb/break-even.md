---
title: When it pays for itself
version: 1
---

A machine is paid for by the hour whether it is busy or not. An API is paid for by the token and
costs nothing when nobody calls it. So the comparison is not "which is cheaper" but **at what
volume do they cost the same**.

First, the size of ana's requests. Her program sends each of the forty cases to the stand-in and
reads the `usage` the API returns, which counts the tokens the request actually used:

```
ana@desk:~/desk$ python lab/volume.py
40 e-mails: 58.7 tokens in, 1.6 out, on average
```

About 59 tokens in (her three-line prompt plus an e-mail) and under two out, because a label is a
word or two. The stand-in's replies are written by the course; **the counts are real**, made with
the same tokenizer for every case.

`lab/breakeven.py` takes those numbers, rounded up to 59 in and 2 out, a model's prices from the
sheet, and the monthly cost of a machine. Lantern Books receives **about 400 e-mails a day**, and
the machine costs **$1,500 a month**: both are the course's assumptions, round enough to be read as
such.

```
ana@desk:~/desk$ python lab/breakeven.py claude-haiku-4-5 1500
claude-haiku-4-5: $69 per million requests
  ana's 400 a day: $0.83 a month
  a $1,500 machine pays for itself at 724,638 requests a day
```

**Eighty-three cents a month.** At 400 e-mails a day, Lantern Books' whole sorting load costs less
than a coffee on the cheapest model the sheet lists for Anthropic, and a machine would have to sort
**724,638 e-mails a day** to cost the same. Now Claude Opus 5.5, which the sheet prices at four times as much per token:

```
ana@desk:~/desk$ python lab/breakeven.py claude-opus-5-5 1500
claude-opus-5-5: $276 per million requests
  ana's 400 a day: $3.31 a month
  a $1,500 machine pays for itself at 181,159 requests a day
```

Four times the cost per request, and still **$3.31 a month**. The break-even volume falls to
181,159 a day, which is about 450 times what the shop receives.

## The shape of the answer

The arithmetic here is about a small task: few tokens in, almost none out. Change any of those and
the break-even moves:

- **long prompts or long replies** multiply the cost per request, and the break-even volume falls
  by the same factor;
- **steady, high volume** keeps the machine busy, which is the only way it is cheap per token
  (section 05);
- **a bursty load** needs a machine sized for the peak and paid for at the trough.

For ana, the money answer is not close. **Self-hosting can still be right for her**, but not for
cost, and section 08 lists the reasons that are not about money.
