import re

from minilm import embed

CLOSE = 0.75
norm = lambda t: " ".join(t.split())


def claims(reply):
    """(sentence, source number or None) for every sentence of a reply."""
    out = []
    for sentence in re.split(r"(?<=[.!?\]])\s+(?=[A-Z])", reply.strip()):
        m = re.match(r"(.*?)\s*\[(\d+)\]$", sentence)
        out.append((m.group(1), int(m.group(2))) if m else (sentence, None))
    return out


def check(reply, sources):
    """A verdict for every sentence: quoted, close, unsupported, uncited, no such source, or quoted
    in another source than the one cited."""
    verdicts = []
    for sentence, n in claims(reply):
        if n is None:
            verdicts.append((sentence, n, "uncited"))
            continue
        if not 0 < n <= len(sources):
            verdicts.append((sentence, n, "no such source"))
            continue
        text = norm(sources[n - 1]["text"])
        if norm(sentence) in text:
            verdicts.append((sentence, n, "quoted"))
            continue
        elsewhere = [m for m, other in enumerate(sources, 1) if norm(sentence) in norm(other["text"])]
        if elsewhere:
            verdicts.append((sentence, n, f"in [{elsewhere[0]}], not [{n}]"))
            continue
        parts = [p for p in re.split(r"(?<=[.!?])\s+", text) if p]
        best = float((embed(parts) @ embed(sentence)[0]).max())
        verdicts.append((sentence, n, f"close ({best:.2f})" if best >= CLOSE else f"unsupported ({best:.2f})"))
    return verdicts
