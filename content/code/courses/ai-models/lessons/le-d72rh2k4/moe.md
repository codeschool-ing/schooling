---
title: Experts, and two sizes per model
version: 1
---

Llama 4's card gives each model two parameter counts:

```
ana@desk:~/desk$ LLAMA=https://raw.githubusercontent.com/meta-llama/llama-models/0e0b8c519242d5833d8c11bffc1232b77ad7f301
ana@desk:~/desk$ curl -s $LLAMA/models/llama4/MODEL_CARD.md | sed -n 23,42p | grep -E "Llama 4|Activated|Total|>[0-9]+M<"
    <td>Llama 4 Scout (17Bx16E) </td>
    <td>17B (Activated)
        109B (Total)
    <td>10M</td>
    <td>Llama 4 Maverick (17Bx128E)</td>
    <td>17B (Activated)
        400B (Total)
    <td>1M</td>
```

**Scout: 17 billion activated, 109 billion in total. Maverick: 17 billion activated, 400 billion in
total.** That is a **mixture of experts**. Instead of one large feed-forward block per layer, the
model has many smaller ones, the experts (16 in Scout, 128 in Maverick), and a small router that
sends each token through only a few of them. Every expert has to be held in memory, because any
token might need any of them; only the chosen ones are computed for each token.

So a mixture-of-experts model has **two sizes that answer two of lesson 3's questions**:

- **the total decides whether it fits**: memory has to hold every expert;
- **the active part decides how fast it generates**: section 05 of lesson 3 said speed is bandwidth
  divided by the bytes read per token, and only the active experts are read.

`moe.py` applies lesson 3's arithmetic to both, at 4 bits and with the same assumed 1,000 GB/s:

```python
# Llama 4's two models, from the card: billions of parameters in all, and the
# billions each token is actually computed with.
MODELS = {"Llama 4 Scout": (109, 17), "Llama 4 Maverick": (400, 17)}
BANDWIDTH = 1000  # GB/s, the same assumption as lesson 3

for name, (total, active) in MODELS.items():
    held, read = total / 2, active / 2  # gigabytes at 4 bits: half a byte per parameter
    print(f"{name:17} holds {held:5.1f} GB, reads {read:4.1f} GB a token, "
          f"ceiling about {BANDWIDTH / read:3.0f} tokens a second")
```

```
ana@desk:~/desk$ python moe.py
Llama 4 Scout     holds  54.5 GB, reads  8.5 GB a token, ceiling about 118 tokens a second
Llama 4 Maverick  holds 200.0 GB, reads  8.5 GB a token, ceiling about 118 tokens a second
```

The same speed ceiling for both, about 118 tokens a second, because both compute with 17 billion
parameters per token, and **almost four times the memory** for Maverick, because it holds 400
billion. Compare lesson 3's dense Llama 3.1 70B: 35 GB at 4 bits and a ceiling of 28 tokens a
second. Scout holds more and runs faster.

That is the trade experts make: more memory for more knowledge, and the speed of a much smaller
model. It is why parameter counts stopped being one number, and why "a 17B model" in a headline
can mean something that needs 200 GB to load.
