import glob
import re

import numpy as np
from minilm import embed


def load():
    """{id: (metadata, body)} for every document, the front matter read into a dict."""
    docs = {}
    for path in sorted(glob.glob("data/docs/*.md")):
        head, body = open(path).read().split("\n---\n", 1)
        meta = dict(line.split(": ", 1) for line in head.splitlines()[1:])
        docs[meta["id"]] = (meta, body.strip())
    return docs


def fixed(text, size, overlap=0):
    """Every SIZE words, starting again OVERLAP words before the last cut."""
    words = text.split()
    step = size - overlap
    return [" ".join(words[i:i + size]) for i in range(0, max(len(words) - overlap, 1), step)]


def sections(text):
    """(heading path, body) for every '## ' section, the document's title first."""
    title = re.search(r"^# (.+)$", text, re.M).group(1)
    out = []
    for part in re.split(r"\n(?=## )", text)[1:]:
        heading, _, body = part.partition("\n")
        out.append((f"{title} > {heading[3:]}", body.strip()))
    return out


def structured(text, size):
    """Inside each section, whole paragraphs packed together up to SIZE words."""
    chunks = []
    for path, body in sections(text):
        pack = []
        for para in re.split(r"\n\s*\n", body):
            if pack and len(" ".join(pack + [para]).split()) > size:
                chunks.append((path, "\n\n".join(pack)))
                pack = []
            pack.append(para)
        if pack:
            chunks.append((path, "\n\n".join(pack)))
    return chunks


def sentences(text):
    flat = " ".join(line for line in text.splitlines() if not line.startswith("#"))
    return [s for s in re.split(r"(?<=[.!?])(?<!\b\d\.)\s+(?=[A-Z0-9])", " ".join(flat.split())) if s]


def semantic(text, quantile=0.25):
    """Cut between two sentences wherever their similarity is in the lowest QUANTILE."""
    sents = sentences(text)
    v = embed(sents)
    sim = (v[:-1] * v[1:]).sum(axis=1)
    cut = np.quantile(sim, quantile)
    chunks, start = [], 0
    for i, s in enumerate(sim):
        if s <= cut:
            chunks.append(" ".join(sents[start:i + 1]))
            start = i + 1
    chunks.append(" ".join(sents[start:]))
    return chunks
