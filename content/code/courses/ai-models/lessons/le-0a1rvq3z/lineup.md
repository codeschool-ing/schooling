---
title: The line-up
version: 1
---

**This lesson and the next five are a directory.** Each one describes a family of models as it
stood on the day the course was recorded, read from the provider's own pages where the machine
could reach them and from LiteLLM's sheet where it could not. Every name, price and date below will
change. What should not change is how to read them, which lessons 2 to 5 taught and these lessons
apply.

Anthropic publishes a comparison table of its current models. `card.py` reads it from the page,
says the date it read it on, and prints one block per model:

```python
import datetime
import html
import re
import sys
import urllib.request

URL = "https://platform.claude.com/docs/en/about-claude/models/overview"
raw = urllib.request.urlopen(urllib.request.Request(URL, headers={"User-Agent": "curl/8.5.0"})).read().decode()
raw = re.sub(r"<script.*?</script>|<style.*?</style>", "", raw, flags=re.S)
# one line per piece of visible text, the way a reader meets it on the page
lines = [t.strip() for t in html.unescape(re.sub(r"<[^>]+>", "\n", raw)).splitlines() if t.strip()]
print(f"# {URL}, read {datetime.date.today()}")
table = lines.index("Feature")  # the comparison table starts here
names = [lines[table + 1 + 2 * k] for k in range(4)]


def row(label):
    """The cells that follow a row's label in the table: one per model, two for prices."""
    i = lines.index(label, table)
    cells = lines[i + 1:i + 1 + (8 if label == "Pricing" else 4)]
    return [" ".join(cells[k:k + 2]) for k in range(0, 8, 2)] if label == "Pricing" else cells


wanted = sys.argv[2:] if len(sys.argv) > 2 else ["Claude API ID", "Context window", "Max output"]
for k, name in enumerate(names):
    if sys.argv[1] in ("all", name):
        print(name)
        for label in wanted:
            print(f"  {label:27} {row(label)[k]}")
```

```
ana@desk:~/desk$ python card.py all "Claude API ID" "Comparative latency" Pricing
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-07
Claude Fable 5.1
  Claude API ID               claude-fable-5-1
  Comparative latency         Slower
  Pricing                     $10 / input MTok $50 / output MTok
Claude Opus 5.5
  Claude API ID               claude-opus-5-5
  Comparative latency         Moderate
  Pricing                     $4 / input MTok $20 / output MTok
Claude Sonnet 5.5
  Claude API ID               claude-sonnet-5-5
  Comparative latency         Fast
  Pricing                     $2 / input MTok $10 / output MTok
Claude Haiku 4.5
  Claude API ID               claude-haiku-4-5-20251001
  Comparative latency         Fastest
  Pricing                     $1 / input MTok $5 / output MTok
```

**Four tiers, one name each**, and the shape every large provider shares: a smallest, fastest,
cheapest model (**Haiku**), a middle one (**Sonnet**), a large one (**Opus**), and, above those,
**Fable**, the dearest and slowest. Each step up costs two to two and a half times the one below it,
on both input and output.

The sheet sees more than the page shows:

```
ana@desk:~/desk$ python sheet.py provider anthropic | grep -v -- "-20[0-9]*  "
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-fable-5                                1,000,000   128000       10       50  VFSCRP
claude-fable-5-1                              1,000,000   128000       10       50  VFSCRP
claude-haiku-4-5                                200,000    64000        1        5  VFSCRP
claude-mythos-5                               1,000,000   128000       10       50  VFSCRP
claude-mythos-5-1                             1,000,000   128000       10       50  VFSCRP
claude-mythos-preview                         1,000,000   128000       10       50  VFSCRP
claude-opus-4-5                                 200,000    64000        5       25  VFSCRP
claude-opus-4-6                               1,000,000   128000        5       25  VFSCRP
claude-opus-4-7                               1,000,000   128000        5       25  VFSCRP
claude-opus-4-8                               1,000,000   128000        5       25  VFSCRP
claude-opus-5                                 1,000,000   128000        5       25  VFSCRP
claude-opus-5-5                               1,000,000   128000        4       20  VFSCRP
claude-sonnet-4-5                             1,000,000    64000        3       15  VFSCRP
claude-sonnet-4-6                             1,000,000   128000        3       15  VFSCRP
claude-sonnet-5                               1,000,000   128000        2       10  VFSCRP
claude-sonnet-5-5                             1,000,000   128000        2       10  VFSCRP
```

(the `grep` hides the dated duplicates.) Older Opus and Sonnet versions still listed, at their old
prices, and entries the comparison table does not mention at all. **The page lists what Anthropic
recommends now; the sheet lists what can still be called.** Those differ, and a project that pinned
`claude-opus-4-6` a year ago is still on the second list and off the first.

Read the two together for ana's short list. Haiku 4.5 is the tier lesson 4 priced for drafting at
$18.72 a month cached; Sonnet 5.5 is twice that. Both answered every structured-output and window
threshold she set. What separates them for Lantern Books is lesson 5's cases, and one date, which
section 03 reads.
