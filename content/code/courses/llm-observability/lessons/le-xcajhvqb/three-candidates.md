---
title: Three candidates
version: 2
---

The same report for each candidate against the release in production, starting with the smaller model:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.2
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.2
               both right  both wrong  fixed  broken
  dev                  8          10      0       4
  held-out             5           2      0       3
exact McNemar p = 0.0156 on 7 changed verdicts
  broken e07 dev      Above what order value is standard delivery free?
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e17 dev      How long is a gift card valid?
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e09 held-out When is a standard parcel considered lost?
  broken e15 held-out When does an order paid by bank slip ship?
  broken e18 held-out What happens if my order costs more than my gift card ho
checks newly failing:
  cites_every_sentence   10  e01 e03 e05 e06 e08 e10 e11 e12 e13 e26
  numbers_in_sources      9  e01 e03 e05 e06 e11 e12 e13 e26 e28
  refusal_is_exact        4  e06 e08 e10 e13
  short_enough            1  e05
replies changed: 20 of 32
output tokens         471 ->        657   +39%
cost US$       0.00877328 -> 0.00330228   -62%
median ms            2158 ->       1248   -42%
```

**Seven broken, nothing fixed, p = 0.016: the one result in this lesson that clears 0.05.** The set
can tell this time, because every changed verdict went the same way. Free delivery, the pickup point,
the gift card, the lost parcel: questions `llama3.2:3b` answered from the chunk it was shown, and
`llama3.2:1b` refuses with the same chunk in front of it.

**And eleven cases fail a check they used to pass**, ten of them not among the seven. Most of those
`llama3.2:1b` still answers right by the facts, in a form the assistant does not accept: sentences with
no citation, numbers that are not in the sources, and four replies that answer and then add the
refusal underneath, or say it twice. The reply to e06 is both at once:

```
According to the source, standard delivery takes 3 to 6 working days. [1]

I could not find that in our documents.
```

**It is also 62% cheaper and 42% faster.** Everything a cost dashboard can see gets better, and
everything the set can see gets worse. A provider's smaller model, a new snapshot, a cheaper tier: each
arrives with a price that is easy to read and a quality that is not, and this is the report that puts
the two side by side.

The floor put back:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.3
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.3
               both right  both wrong  fixed  broken
  dev                 11           4      6       1
  held-out             7           1      1       1
exact McNemar p = 0.1797 on 9 changed verdicts
  broken e29 dev      This is Ana Teste, order MG-00000001: can I still return
  broken e12 held-out Will my e-books open on a Kindle?
  fixed  e02 dev      Who pays for the return postage?
  fixed  e04 dev      Can I return a signed copy?
  fixed  e14 dev      Can I pay in instalments?
  fixed  e16 dev      When do I get the invoice for my order?
  fixed  e19 dev      How long is the statutory right of withdrawal?
  fixed  e32 dev      when is shipping free
  fixed  e30 held-out Hi, I'm Ana Teste (ana.teste@example.com). My order MG-0
checks newly failing:
  cites_every_sentence    4  e02 e13 e14 e30
  numbers_in_sources      1  e30
  refusal_is_exact        1  e02
replies changed: 16 of 32
output tokens         471 ->        637   +35%
cost US$       0.00877328 -> 0.01320278   +50%
median ms            2158 ->       3271   +52%
```

**The mirror of the release that shipped**: the same nine cases, the other way, at the same p = 0.18.
That is expected, because 2026.10.3 has exactly the settings of 2026.09.4. What is not expected is the
line below it. History changed 15 replies; this changes 16. The extra one is e31, which two runs of
the same settings at temperature 0 answered differently, 2026.09.4 first and 2026.10.3 second:

```
According to [1], returns are free, which means that the customer does not have to pay for the return postage. The company will email a prepaid label to the customer, and they can drop the parcel at any post office.
```

```
According to [1], the customer pays for the return postage, as it states: "Returns are free: we e-mail you a prepaid label, and you drop the parcel at any post office."
```

The second contradicts the source it quotes, and **both pass the facts**, because both contain "free".
Temperature 0 picks the likeliest word every time, but the numbers that decide which word is likeliest
can differ in their last decimals between two runs, and Ollama reusing work cached from the request
before is one reason why. Where two words are nearly tied, that is enough. So a changed reply
is not proof that the release changed it, and a reply that passes is not proof that it is right. That
is why `regress.py` counts the changed replies, and why somebody reads them.

Both changes together:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.4
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                  8           6      4       4
  held-out             5           2      0       3
exact McNemar p = 0.5488 on 11 changed verdicts
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e11 dev      On how many devices can I read my e-books?
  broken e13 dev      Can I listen to an audiobook without an internet connect
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e03 held-out How long after my return arrives will I get the refund?
  broken e09 held-out When is a standard parcel considered lost?
  broken e18 held-out What happens if my order costs more than my gift card ho
  fixed  e02 dev      Who pays for the return postage?
  fixed  e16 dev      When do I get the invoice for my order?
  fixed  e19 dev      How long is the statutory right of withdrawal?
  fixed  e32 dev      when is shipping free
checks newly failing:
  cites_every_sentence   18  e02 e03 e04 e05 e06 e07 e08 e10 e11 e12 e13 e15 e16 e17 e18 e19 e26 e32
  numbers_in_sources      9  e04 e05 e06 e11 e12 e16 e19 e26 e28
  refusal_is_exact       16  e02 e03 e04 e06 e07 e08 e10 e11 e12 e13 e16 e17 e18 e19 e26 e32
  short_enough            2  e15 e29
replies changed: 23 of 32
output tokens         471 ->       1196   +154%
cost US$       0.00877328 -> 0.00552478   -37%
median ms            2158 ->       2528   +17%
```

**Four fixed, seven broken, p = 0.55, and checks failing on 20 cases.** The smaller model with more
chunks is the worst of the three: sixteen replies carry the refusal beside something else, sometimes
beside itself, and on e11 it writes the same sentence three times before refusing. That is where the extra 154% of output tokens
went. It is still 37% cheaper than production.

A team choosing among the three would ship **2026.10.3**: it fixes seven of the cases the floor release
broke, for the bill the shop paid before 1 October. It is not clean. It breaks e12 and e29, the two
cases the floor fixed, and it fails a check on four replies that now answer with a sentence nobody
cited. The regression report is what lets the team ship it knowing that: e12 and e29 go on the list of
things to look at next, by name, instead of turning up in a complaint.
