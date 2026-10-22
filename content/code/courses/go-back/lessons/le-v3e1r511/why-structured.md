---
title: A log line is data
version: 1
---

Since lesson 2, boxoffice has logged one line per request:

```
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
```

A person reads it easily. **A program reading ten million of them has to guess**: that the fourth word is
the status, that `14B` is a size, that `19µs` is a duration in a unit that changes to `ms` when it grows.
The day somebody adds a field in the middle, every script that split those lines on spaces reads the
wrong column, quietly.

**A structured log writes each line as named fields**, in a format a machine parses without guessing,
almost always JSON with one object per line. The same request becomes:

```json
{"time":"2026-10-22T19:20:06.575241195-03:00","level":"INFO","msg":"request","request_id":"875cefab9e03dc1c","method":"GET","path":"/events/9","status":404,"bytes":90,"duration_ms":0.3}
```

Longer, and **every value now has a name and a type**: `status` is the number 404, `duration_ms` is
always milliseconds. The systems that collect logs from servers, whatever the vendor, index fields like
these, so that "every 5xx on `/events` in the last hour, slowest first" is a query and not a script.

Three ideas come with structure, and this lesson uses all three:

- **Levels.** Each line says how much it matters, usually `DEBUG`, `INFO`, `WARN` and `ERROR`, and a
  service can be told to drop the ones below a level.
- **Context fields.** A request id attached once, at the start, appears on every line written while that
  request is served, so all of one request's lines can be found together.
- **A message that is a constant.** `"request"` or `"ticket sold"`, the same text every time, with the
  variable parts in fields. A message assembled with `Printf` is a different string on every line, and
  cannot be counted or grouped.

Go's standard library has had a structured logger since Go 1.21, in `log/slog`. Two libraries were widely
used before it existed, zerolog and zap, and they remain in many codebases. This lesson uses all three on
the same lines, and gives boxoffice the first.
