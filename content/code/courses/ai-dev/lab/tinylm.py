"""tinylm: the smallest language model that is still one.

It counts which token followed which in a corpus, and predicts the next token
from the last ORDER-1 tokens it was given. When it has never seen those, it
backs off to fewer, down to how often each token occurs at all. That is the
whole model: no layers, no weights, a table of counts. It is here because
everything a large model does at the moment of generation, this does too:
read a context, produce a probability for every token, pick one, append it,
repeat.
"""
import json
import math
from collections import Counter, defaultdict

import numpy as np
import tiktoken

ENC = tiktoken.get_encoding("o200k_base")


class TinyLM:
    def __init__(self, order=3):
        self.order = order
        self.counts = defaultdict(Counter)  # context tuple -> Counter of next token

    @classmethod
    def train(cls, text, order=3):
        m = cls(order)
        toks = ENC.encode(text)
        for i in range(len(toks)):
            for n in range(order):  # contexts of length 0 .. order-1
                if i - n < 0:
                    break
                m.counts[tuple(toks[i - n:i])][toks[i]] += 1
        return m

    def save(self, path):
        data = {"order": self.order,
                "counts": [[list(c), list(map(list, n.items()))] for c, n in self.counts.items()]}
        with open(path, "w") as f:
            json.dump(data, f)

    @classmethod
    def load(cls, path):
        with open(path) as f:
            data = json.load(f)
        m = cls(data["order"])
        for c, items in data["counts"]:
            m.counts[tuple(c)] = Counter({t: n for t, n in items})
        return m

    def distribution(self, tokens):
        """The next-token distribution after `tokens`, and how much context it used."""
        for n in range(self.order - 1, -1, -1):
            ctx = tuple(tokens[len(tokens) - n:]) if n else ()
            if n <= len(tokens) and ctx in self.counts:
                c = self.counts[ctx]
                total = sum(c.values())
                return {t: k / total for t, k in c.items()}, n
        raise ValueError("empty model")

    def top(self, text, k=5):
        dist, used = self.distribution(ENC.encode(text))
        best = sorted(dist.items(), key=lambda kv: (-kv[1], kv[0]))[:k]
        return [(ENC.decode([t]), p) for t, p in best], used

    def sample(self, dist, temperature, top_p, rng):
        toks = sorted(dist, key=lambda t: (-dist[t], t))
        p = np.array([dist[t] for t in toks])
        if temperature == 0:
            return toks[0]
        logits = np.log(p) / temperature
        p = np.exp(logits - logits.max())
        p /= p.sum()
        if top_p < 1:
            keep = np.searchsorted(np.cumsum(p), top_p) + 1
            p = p[:keep] / p[:keep].sum()
            toks = toks[:keep]
        return toks[rng.choice(len(toks), p=p)]

    def generate(self, prompt, max_tokens=30, temperature=1.0, top_p=1.0, seed=0, stop=()):
        """Yield one generated token's text at a time."""
        rng = np.random.default_rng(seed)
        toks = ENC.encode(prompt)
        out = ""
        for _ in range(max_tokens):
            dist, _ = self.distribution(toks)
            t = self.sample(dist, temperature, top_p, rng)
            toks.append(t)
            piece = ENC.decode([t])
            out += piece
            yield piece
            if any(s in out for s in stop):
                return
