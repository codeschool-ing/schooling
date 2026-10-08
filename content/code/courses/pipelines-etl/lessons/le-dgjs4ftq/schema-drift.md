---
title: When the source changes shape
version: 1
---

On 5 March the distributor's file arrived in a different encoding, with semicolons, Portuguese
headers and a Brazilian date format. Ana's loader handled the day before and stopped on this one:

```
ana@vm:~/etl$ python load_stock.py inbox/stock_2026-03-04.csv
inbox/stock_2026-03-04.csv: 1200 rows loaded
ana@vm:~/etl$ python load_stock.py inbox/stock_2026-03-05.csv; echo "exit status $?"
Traceback (most recent call last):
  File "/home/ana/etl/load_stock.py", line 11, in <module>
    header = next(reader)
  File "<frozen codecs>", line 325, in decode
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xed in position 11: invalid continuation byte
exit status 1
```

It stopped, and that is the right outcome — but read the message. The loader has a check for
exactly this: it compares the header with the one it expects and refuses with a sentence naming
both. **The check never ran.** Python was told the file was UTF-8, met the byte `0xED` — `í` in
Latin-1, the `í` of `disponível` — and raised before the header was read. The failure is loud, and
it names the wrong problem: whoever is on call reads "codec can't decode" and goes looking for a
corrupt file.

Two lessons in that:

- **Order your checks by what can fail first.** Reading the first line as bytes, before decoding
  anything, and comparing it with the expected header, would have produced the sentence that was
  written for this day.
- **A failure message is written for the person who reads it at 3 a.m.**, not for the
  programmer. "The distributor's header is now `isbn;disponível;data`" sends them to the phone.
  A traceback sends them to the code.

## Fail, or adapt?

The tempting fix is a loader that adapts: detect the encoding, sniff the separator, map
`disponível` to `available` and parse either date format. Each step is reasonable, and together
they make a pipeline that accepts **any** change the supplier makes, including the one where
`disponível` now means something else — reserved stock, say, rather than stock on hand.

**Shape changes are decisions, and a pipeline should not make them on its own.** The rule that
serves best:

- **stop on a change of shape** — a column renamed, added, removed, retyped — with a message that
  says what changed;
- **let a person decide**, usually by asking the supplier what happened and whether it is
  permanent;
- **change the loader on purpose**, in a commit that says why, so that next year's reader knows
  that `disponível` was a deliberate mapping and not an accident.

Lesson 16 gives that rule a name — a **data contract** — and a way to write it down that the
pipeline checks for itself. The file for 5 March stays in the inbox unloaded; the lab's distributor
goes back to the old format on the 6th, which real suppliers rarely do.
