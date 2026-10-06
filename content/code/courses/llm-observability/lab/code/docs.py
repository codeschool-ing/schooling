"""docs.py: the shop's documents as the evaluation set sees them: front matter, and the text under each heading."""
import glob
import os
import re


def load(folder="data/docs"):
    """{doc id: (front matter, {heading: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        _, front, body = open(path).read().split("---\n", 2)
        meta = dict(line.split(": ", 1) for line in front.strip().splitlines())
        sections, current = {}, None
        for line in body.splitlines():
            m = re.match(r"#{2,}\s+(.*)", line)
            if m:
                current = m.group(1).strip()
                sections[current] = ""
            elif current:
                sections[current] += line + "\n"
        docs[meta["id"]] = (meta, sections)
    return docs
