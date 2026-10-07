---
title: Cutting documents into passages
version: 1
---

Retrieval returns passages, not documents, and the size of a passage is the first decision. Too
large, and a passage about returns brings three paragraphs about refunds with it, filling the prompt
with text that does not answer the question. Too small, and a sentence arrives without the sentence
before it that said what "it" was. **A passage should be the smallest piece that makes sense on its
own.**

## One paragraph, with its title

The handbook is written in short paragraphs, each about one thing, so a paragraph is a natural
passage. Each one carries its document's title, so a paragraph that says "after 30 days" still says
what it is about when it arrives alone. Each gets an id made of the file and the paragraph's
position, which is what an answer will cite:

```python
def chunks(folder="docs/handbook"):
    """One chunk per paragraph, carrying its document's title, with an id that says where it is."""
    out = []
    for path in sorted(Path(folder).glob("*.md")):
        title, *paragraphs = path.read_text().split("\n\n")
        for n, p in enumerate(paragraphs, 1):
            out.append({"id": f"{path.name}#{n}", "text": title.lstrip("# ") + ". " + " ".join(p.split())})
    return out
```

```
ana@dev:~/shop$ PYTHONPATH=scratch python -c 'import rag; cs = rag.chunks(); n = [len(rag.ENC.encode(c["text"])) for c in cs]; print(len(cs), "chunks, from", min(n), "to", max(n), "tokens"); [print(c["id"], "|", c["text"][:70]) for c in cs[:4]]'
26 chunks, from 23 to 56 tokens
account.md#1 | Accounts and passwords. A customer can check out without an account, b
account.md#2 | Accounts and passwords. To reset a password, the customer chooses "For
account.md#3 | Accounts and passwords. To close an account, the customer writes to su
contact.md#1 | Contacting support. Support answers by email and chat from 9:00 to 18:
```

Twenty-six passages, from 23 to 56 tokens each. `account.md#2` is the second paragraph of
`account.md`, and it begins with `Accounts and passwords.`, the title it was cut from.

## Choices that change the results

- **Size.** Paragraphs suit this handbook. Long documents with long sections are usually cut to a
  fixed number of tokens, a few hundred, with an **overlap** between neighbours so a sentence on the
  boundary is in both.
- **Structure first.** Cut at headings and paragraphs before cutting at a token count. A cut in the
  middle of a table or a list produces two passages that each make no sense.
- **Context in every passage.** The title here; in a longer document, the chain of headings above
  the paragraph. It costs a few tokens per passage and saves a passage that cannot be understood.
- **Ids that survive edits.** A position is a weak id: insert a paragraph and every id after it
  moves, so a citation stored last week points at a different paragraph today. Real systems give a
  passage an id that does not depend on its position, or store the text the citation pointed at.

The ids here are positions because the handbook does not change during the lesson. The last point
is the one to fix first when it does.
