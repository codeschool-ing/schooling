---
title: What patterns miss, and what they catch by mistake
version: 2
---

A regular expression finds text with a shape. Personal data mostly has one, and sometimes does not,
and sometimes other text has the same shape. `misses.py` puts six sentences through `redact()`:

```python
"""misses.py: what the patterns catch, what they miss, and what they catch by mistake."""
import redact

for text in ["Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.",
             "my email is joana dot prado at example dot com",
             "call me on 11 5550-0142",
             "card 4111 1111 1111 1111, expires 09/28",
             "Is ISBN 978-0-14-143951-8 in stock?",
             "My CPF is 123.456.789-09"]:
    print(f"{text}\n  -> {redact.redact(text)}")
```

```
ana@dev:~/obs$ python misses.py
Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.
  -> Hi, I'm Joana Prado ([email]), order [order].
my email is joana dot prado at example dot com
  -> my email is joana dot prado at example dot com
call me on 11 5550-0142
  -> call me on 11 5550-0142
card 4111 1111 1111 1111, expires 09/28
  -> card [card], expires 09/28
Is ISBN 978-0-14-143951-8 in stock?
  -> Is ISBN [card]in stock?
My CPF is 123.456.789-09
  -> My CPF is 123.456.789-09
```

Six lines, four kinds of result.

**Caught as intended**: the address and the order in the first line, the card in the fourth. The
expiry date is still there, which is harmless on its own.

**Missed because the shape changed.** An address spelt out in words, the way people write it to keep
it from spam robots, has no `@`. A telephone number without the country code does not match a
pattern that starts with `+`. Both are what customers really type, and both go straight through.

**Missed because nobody wrote the pattern.** A CPF, the Brazilian taxpayer number, is personal data
that identifies somebody directly, and `redact.py` has no pattern for it. For a shop in Brazil that is
a gap to close today. The general lesson is that the list of patterns is a list of the things
somebody thought of, and it needs the same review as any other list of rules.

**Caught by mistake.** An ISBN is thirteen digits with hyphens, which is exactly the shape of a card
number, so the question about a book in stock lost the book. In a bookshop that is not a rare case:
it is the most common number customers type. The pattern also ate the space after it. A false
positive does not leak anything, but it removes evidence from every trace it touches, and a debugger
looking at `Is ISBN [card]in stock?` will spend a while working out what happened. A card pattern can
be made stricter by checking the Luhn digit that every card number carries and no ISBN-13 is
required to; that was not added here.

## Names, and a model to find them

Not one of the six lines lost a name, and neither did any span in this lesson. A name has no shape a
pattern can find without also finding every capitalised word. Finding names takes **named-entity
recognition**: a model that reads the sentence and marks which words are a person, a place, a date.
Microsoft's **Presidio** is the usual open-source tool for it. It combines a spaCy language model with
patterns of its own, and gives every finding a score. It is two packages, and the language model is
a third, downloaded from spaCy's own releases on GitHub:

```sh
pip install presidio-analyzer==2.2.364 presidio-anonymizer==2.2.364
pip install https://github.com/explosion/spacy-models/releases/download/en_core_web_lg-3.8.0/en_core_web_lg-3.8.0-py3-none-any.whl
```

The language model is most of it, a few hundred megabytes on its own.

`presidio_try.py` runs the same six sentences through it:

```python
"""presidio_try.py: the same sentences through Presidio, which finds entities with a language model as well as patterns."""
import logging
import sys

from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 0.0
analyzer, anonymizer = AnalyzerEngine(), AnonymizerEngine()
for text in ["Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.",
             "my email is joana dot prado at example dot com",
             "call me on 11 5550-0142",
             "card 4111 1111 1111 1111, expires 09/28",
             "Is ISBN 978-0-14-143951-8 in stock?",
             "My CPF is 123.456.789-09"]:
    found = analyzer.analyze(text=text, language="en", score_threshold=threshold)
    print(f"{anonymizer.anonymize(text=text, analyzer_results=found).text}")
    print("    " + (", ".join(f"{r.entity_type} {r.score:.2f}" for r in sorted(found, key=lambda r: r.start))
                     or "nothing found"))
```

```
ana@dev:~/obs$ python presidio_try.py
Hi, I'm <PERSON> (<EMAIL_ADDRESS>), order <DATE_TIME>.
    PERSON 0.85, EMAIL_ADDRESS 1.00, URL 0.50, URL 0.50, DATE_TIME 0.85, US_BANK_NUMBER 0.05, US_DRIVER_LICENSE 0.01
my email is <PERSON> at example dot com
    PERSON 0.85
call me on <PHONE_NUMBER>
    PHONE_NUMBER 0.40
card <CREDIT_CARD>, expires <DATE_TIME>
    CREDIT_CARD 1.00, DATE_TIME 0.10
Is ISBN 978-0-14-<US_DRIVER_LICENSE>-8 in stock?
    US_DRIVER_LICENSE 0.01
My CPF is <DATE_TIME>
    DATE_TIME 0.85, PHONE_NUMBER 0.40
```

**The names are found**: Joana Prado in the first line, and in the second the spelt-out address lost
its first half because the model read *joana dot prado* as a person. The telephone number without a
country code is found too, and so is the CPF.

Read the labels before celebrating. The order number was removed as a **date**, at 0.85. The CPF was
removed as a date as well, and as a telephone number. The ISBN lost six digits to a **US driver's
licence** recogniser at a score of 0.01. Presidio is tuned for American documents in English, and a
Brazilian shop's identifiers are not what its patterns were written for. Things that should go
mostly went, sometimes for the wrong reason, which is luck rather than a guarantee.

Every finding has a score, and by default every finding is used, down to 0.01. A threshold changes the
trade:

```
ana@dev:~/obs$ python presidio_try.py 0.5
Hi, I'm <PERSON> (<EMAIL_ADDRESS>), order <DATE_TIME>.
    PERSON 0.85, EMAIL_ADDRESS 1.00, URL 0.50, URL 0.50, DATE_TIME 0.85
my email is <PERSON> at example dot com
    PERSON 0.85
call me on 11 5550-0142
    nothing found
card <CREDIT_CARD>, expires 09/28
    CREDIT_CARD 1.00
Is ISBN 978-0-14-143951-8 in stock?
    nothing found
My CPF is <DATE_TIME>
    DATE_TIME 0.85
```

At 0.5 the ISBN survives and the expiry date stays. So does the telephone number, scored 0.40,
which is now a leak. **There is no threshold that removes everything personal and nothing else**;
there is a choice of which mistake to prefer, and for a trace store the safer one is removing too
much. The patterns from `redact.py` and a recogniser like this are best together: the patterns for
the identifiers the business knows exactly (its order numbers, a CPF, its card formats), the model
for the names nobody can write a pattern for.

Even with both, recognition is a probability. The honest position is the one this lesson keeps
returning to: **redaction lowers how much personal data is kept; it does not make the text
anonymous**. A redacted question that says *My order has not arrived, I live on the street behind the
school* can still point at one person. That is why the text gets a shorter life than the numbers,
which is the last section.
