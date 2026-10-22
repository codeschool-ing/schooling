---
title: Attributes, groups and secrets
version: 1
---

A record's values are its attributes, and most of them repeat. Every line about one request should
carry the request's id, and passing it to every call is how one gets forgotten. **`Logger.With`
returns a new logger that adds its attributes to every record it writes.** The program below uses
it, groups two values under one name, and keeps a credential out of the log, saved as
`attrs/main.go`:

```schooling-example
{"language": "go", "file": "attrs/main.go", "parts": [{"code": "// Command attrs attaches context to a logger and keeps a secret out of it.\npackage main\n\nimport (\n\t\"log/slog\"\n\t\"os\"\n)\n\nfunc noTime(groups []string, a slog.Attr) slog.Attr {\n\tif a.Key == slog.TimeKey && len(groups) == 0 {\n\t\treturn slog.Attr{}\n\t}\n\treturn a\n}\n\n", "note": "The same `noTime` as the previous section's program, so the output does not depend on when it ran."}, {"code": "// Token is a credential. Its LogValue is what any handler records.\ntype Token string\n\nfunc (Token) LogValue() slog.Value { return slog.StringValue(\"REDACTED\") }\n\n", "note": "**A type with a `LogValue` method decides how it is logged**, whatever handler writes it. `Token` answers `REDACTED`, so the credential cannot reach a log by accident."}, {"code": "func main() {\n\tlog := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{ReplaceAttr: noTime}))\n\n", "note": "One JSON handler for the whole program."}, {"code": "\treq := log.With(\"request_id\", \"r-81f3\", \"user\", 7)\n\treq.Info(\"order placed\", slog.Int(\"order\", 1042))\n", "note": "`log.With` returns a new logger; `log` itself is unchanged. `slog.Int` builds an attribute with its type stated, which is the same as the pair `\"order\", 1042`, written so a typo cannot unbalance the pairs."}, {"code": "\treq.Info(\"shipping\", slog.Group(\"address\", \"city\", \"Recife\", \"zip\", \"50000-000\"))\n\n", "note": "`slog.Group` nests attributes under one key, which JSON writes as an object inside the object."}, {"code": "\treq.Info(\"charging card\", \"token\", Token(\"tok_live_4f9a\"))\n", "note": "The token is passed as it is. Its `LogValue` runs inside the handler."}, {"code": "\treq.Info(\"odd number of arguments\", \"order\")\n}\n", "note": "**One argument short**: `\"order\"` has no value after it."}]}
```

```
ana@vm:~/logs$ go run ./attrs
{"level":"INFO","msg":"order placed","request_id":"r-81f3","user":7,"order":1042}
{"level":"INFO","msg":"shipping","request_id":"r-81f3","user":7,"address":{"city":"Recife","zip":"50000-000"}}
{"level":"INFO","msg":"charging card","request_id":"r-81f3","user":7,"token":"REDACTED"}
{"level":"INFO","msg":"odd number of arguments","request_id":"r-81f3","user":7,"!BADKEY":"order"}
```

The first two attributes of every line are `request_id` and `user`, written once in `With`. The
address arrived as an object, `"address":{"city":"Recife",…}`, and the token as `REDACTED`.
**The last line is the mistake made visible**: with an odd number of arguments, `slog` cannot know
the lone string was meant as a key, so it records it under `!BADKEY`. The record is still written,
because a logging call that failed would hide the very line somebody needs. `go vet` catches the
mistake before it runs:

```
ana@vm:~/logs$ go vet ./attrs; echo $?
attrs/main.go:29:2: call to slog.Logger.Info missing a final value
1
```

**`go vet` checks the pairs of every `slog` call it can see**, and exits with status 1. It is the
cheapest of the habits this lesson recommends: run it before every commit, as lesson 4 of `go`
said.

## What not to put in an attribute

A log is read by more people, and kept longer, than the data it describes. A password, a token, a
card number or a person's full address in a log line is that data copied somewhere with weaker
protection. `LogValue` on the type is the defence that does not depend on everybody remembering:
the type that holds a secret says once how it is logged. Recife and the postal code in the program
above are an example of a value that is personal and still ends up in logs every day; whether it
should is a decision for the team that owns the data, made before the first line is written.
