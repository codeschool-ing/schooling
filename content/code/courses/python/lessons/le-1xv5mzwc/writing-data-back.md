---
title: Never build either format by hand
version: 1
---

```python
import csv

with open(path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "city", "score"])
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
```

`DictWriter` takes the field names, writes the header, and quotes whatever needs quoting. A city
called `Porto, Portugal` comes out correctly quoted, and you did not have to think about it.

`writerows(rows)` is the loop in one line.

## The hand-made version, and what it costs

```python
f.write(",".join([name, city, str(score)]) + "\n")      # no
```

This is correct until a value contains a comma, a quote or a newline — and then it produces a
file that looks fine, opens in a spreadsheet, and has the columns shifted on one row out of
eleven thousand. Nothing raises, here or when it is read back.

The same argument applies to JSON, and more strongly: escaping a quote, a backslash and a control
character correctly is what `json.dumps` is for.

## Writing JSON somebody will read

```python
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)
    f.write("\n")
```

`indent=2` for the diff, `ensure_ascii=False` for the accents, `sort_keys=True` so two runs
produce the same bytes. The trailing newline is not JSON's business and is every text tool's.

## Writing safely

```python
tmp = path.with_suffix(".tmp")
tmp.write_text(text, encoding="utf-8")
tmp.replace(path)          # atomic on the same filesystem
```

Opening the real file with `"w"` truncates it before the first byte is written, so a crash in the
middle leaves you with neither the old file nor the new one. Writing beside it and renaming
means the reader sees one or the other and never a half.

**This matters for anything a program reads on start-up** — a cache, a state file, a
configuration somebody else's process is watching.
