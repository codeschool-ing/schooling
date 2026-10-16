---
title: "Errors as values: a Result instead of an exception"
version: 1
---

**An exception is a side effect of a kind that is easy to forget: a function that raises has a
second way of returning, and nothing in its signature says so.** `date.fromisoformat(text)` returns
a `date`, says its type, and also sometimes jumps out of the caller and up the stack. That is often
exactly right. It is a poor fit when failure is an expected outcome, such as a line in a file that
somebody typed wrong, because then the caller has to remember a `try` that the type never asked
for.

The functional answer is to return the failure as a value. A function's result is either *ok, with
a value* or *an error, with a reason*, and the caller has to look at which one it got before using
it. Rust calls the type `Result`, Haskell `Either`, and Go returns `value, err` from almost every
function that can fail.

## Loading loans from text

The library imports loans from lines of text, title, date and kind separated by semicolons. Some
lines are wrong in different ways, and the import should report every bad line rather than stop at
the first:

```schooling-example
{"language": "python", "file": "result.py", "parts": [
 {"code": "# result.py\nfrom dataclasses import dataclass\nfrom datetime import date\n\nLOAN_DAYS = {\"book\": 14, \"film\": 7}", "note": "The loan length per kind, as a table: the lesson 14 point about data that differs only in values."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Ok:\n    value: tuple[str, date, int]\n\n\n@dataclass(frozen=True)\nclass Err:\n    error: str", "note": "The whole Result type: two small frozen classes. Python has no built-in one, and this is all it needs to be."},
 {"code": "\n\ndef parse_loan(line: str) -> Ok | Err:\n    fields = line.split(\";\")\n    if len(fields) != 3:\n        return Err(f\"expected 3 fields, got {len(fields)}: {line!r}\")\n    title, lent, kind = fields\n    try:\n        lent_on = date.fromisoformat(lent)\n    except ValueError as err:\n        return Err(f\"{lent!r} is not a date: {err}\")\n    if kind not in LOAN_DAYS:\n        return Err(f\"unknown kind {kind!r} for {title!r}\")\n    return Ok((title, lent_on, LOAN_DAYS[kind]))", "note": "The signature says both outcomes: `Ok | Err`. The one exception the standard library raises is caught at the point it happens and turned into a value."},
 {"code": "\n\nLINES = [\"Dom Casmurro;2026-03-02;book\",\n         \"Central do Brasil;2026-03-09;film\",\n         \"Iracema;2026-02-30;book\",\n         \"Vidas Secas;2026-03-10;magazine\",\n         \"Cidade de Deus 2026-03-01 film\"]", "note": "Two good lines and three bad ones, each bad in its own way: 30 February, a kind the library does not lend, and spaces where the semicolons should be."},
 {"code": "\n\nif __name__ == \"__main__\":\n    results = [parse_loan(line) for line in LINES]\n    for result in results:\n        match result:\n            case Ok((title, lent_on, days)):\n                print(f\"ok     {title}: {days} days from {lent_on}\")\n            case Err(message):\n                print(f\"error  {message}\")\n    loaded = [r.value for r in results if isinstance(r, Ok)]\n    print(f\"{len(loaded)} of {len(results)} lines loaded\")", "note": "`match` (Python 3.10 and later) takes the result apart by shape. Every line is parsed, the errors are data to print, and nothing stops the loop."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 result.py
ok     Dom Casmurro: 14 days from 2026-03-02
ok     Central do Brasil: 7 days from 2026-03-09
error  '2026-02-30' is not a date: day is out of range for month
error  unknown kind 'magazine' for 'Vidas Secas'
error  expected 3 fields, got 1: 'Cidade de Deus 2026-03-01 film'
2 of 5 lines loaded
```

Every line got an answer. A version of `parse_loan` that raised on a bad line would stop the import
at *Iracema* unless every caller wrapped each call in its own `try`, and the report that three lines
out of five were wrong would never be printed.

## What the type checker adds

At run time, `Ok | Err` is a promise in a comment. With a type checker such as mypy, it becomes a
check: `parse_loan(line).value` is refused, because an `Err` has no `value`, until the code has
narrowed the result with `isinstance` or `match`. **The failure case becomes something the code has
to handle before it compiles, not something a reviewer has to remember to ask about.** Go gets a
weaker version of this from convention and linters: an unused `err` is flagged, though nothing
stops `if err != nil` from being written wrongly.

## When to raise anyway

Python is built around exceptions, and fighting that everywhere makes code worse. A reasonable
division:

| situation | in Python |
|---|---|
| input that is often wrong and must be reported in bulk: imports, form validation | return a result value |
| a failure the caller can do something sensible about, case by case | either; a result makes it visible |
| a bug or an impossible state: a negative number of days, a missing configuration | raise, and let it crash loudly |
| a failure deep inside I/O that only the top level can handle: a lost connection | raise; returning it through ten layers is noise |

The test is whether the caller is expected to handle the failure as part of its ordinary job. If
yes, put it in the return type, where the caller cannot miss it. If no, an exception carries it to
whoever can deal with it, which is what exceptions are for.
