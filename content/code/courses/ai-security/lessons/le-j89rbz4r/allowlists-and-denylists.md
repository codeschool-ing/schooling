---
title: Name what is allowed, rather than what is not
version: 2
---

Two kinds of list run through this course. A **denylist** names what is refused: the moderation word
list of lesson 6, the phrase list of lesson 8. An **allowlist** names what is accepted and refuses
everything else: the categories and fields of lesson 9, the hosts, the registry snapshot of lesson 2.
They fail in opposite directions. The denylist side is `guard moderate`, which prints the stand-in's
scores for one text. Save it as `~/guard/tools/moderate.py`; lesson 6 uses it too:

```python
# moderate.py: the stand-in moderation endpoint's scores for one text.
#
#   guard moderate TEXT
import json
import sys

from moderation import moderate

print(json.dumps(moderate(sys.argv[1])))
```

```
ana@lab:~/guard$ guard moderate 'Shut up, you clown'
{"harassment": 0.84, "threat": 0.0, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Shut up, you cl0wn'
{"harassment": 0.6, "threat": 0.0, "spam": 0.0}
```

The denylist lost most of a word to a zero: *clown* stopped counting and the score fell from 0.84 to
0.60. **A denylist fails open**: whatever it has not thought of goes through. The host allowlist in
the chain did the opposite with `r5`: it refused `pay-tarefa.example`, which nobody wrote down as
forbidden, only because it is not one of the two hosts that are allowed. **An allowlist fails closed**:
whatever it has not thought of is stopped, and the cost is a legitimate value refused until somebody
adds it.

That asymmetry gives the rule of thumb:

- **Where the set of good values is small and known, use an allowlist.** Categories, fields, hosts,
  packages, tools. Each refusal is visible, says what is allowed, and is fixed by adding one entry.
- **Where the good values are open-ended, a denylist is the only option**, and it is treated as a
  signal rather than a guarantee. Free text is the case: nobody can list every acceptable sentence, so
  moderation scores it and a person reviews the doubtful band, as in lesson 6.

The mistake to avoid is a denylist where an allowlist was possible. A link filter that blocks known
bad hosts has to know about every bad host before it appears; one that allows Tarefa's own hosts only
has to know Tarefa.
