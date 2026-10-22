---
title: Levels that move, and the context that travels
version: 1
---

Two needs arrive with the first incident in production. Somebody wants the `DEBUG` records now,
without a restart that would make the problem go away. And somebody wants every record about one
request to carry that request's id, from code that was never handed a logger with it. **A
`slog.LevelVar` answers the first, and a handler that reads the `context.Context` answers the
second**: the same context that lessons 10 and 11 pass down every call. Saved as
`levels/main.go`:

```schooling-example
{"language": "go", "file": "levels/main.go", "parts": [{"code": "// Command levels changes what is logged while the program runs, and takes\n// a request id from the context.\npackage main\n\nimport (\n\t\"context\"\n\t\"log/slog\"\n\t\"os\"\n)\n\nfunc noTime(groups []string, a slog.Attr) slog.Attr {\n\tif a.Key == slog.TimeKey && len(groups) == 0 {\n\t\treturn slog.Attr{}\n\t}\n\treturn a\n}\n\n", "note": "The same `noTime` as before."}, {"code": "type ctxKey struct{}\n\n", "note": "A key type of its own, as lesson 10 recommends for context values, so no other package can collide with it."}, {"code": "// withRequest adds the request id it finds in the context to every record.\ntype withRequest struct{ slog.Handler }\n\nfunc (h withRequest) Handle(ctx context.Context, r slog.Record) error {\n\tif id, ok := ctx.Value(ctxKey{}).(string); ok {\n\t\tr.AddAttrs(slog.String(\"request_id\", id))\n\t}\n\treturn h.Handler.Handle(ctx, r)\n}\n\n", "note": "**`withRequest` embeds a `slog.Handler` and overrides only `Handle`.** Before passing the record on, it looks in the context for a request id and, when there is one, adds it as an attribute."}, {"code": "func main() {\n\tvar level slog.LevelVar // Info, its zero value\n\tbase := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: &level, ReplaceAttr: noTime})\n\tlog := slog.New(withRequest{base})\n\n", "note": "**The level is a `LevelVar`, a variable the handler reads on every record**, not a value copied when the handler was made. Its zero value is `INFO`."}, {"code": "\tctx := context.WithValue(context.Background(), ctxKey{}, \"r-81f3\")\n\tlog.DebugContext(ctx, \"query plan\", \"rows\", 3)\n\tlog.InfoContext(ctx, \"order placed\", \"order\", 1042)\n\n", "note": "`DebugContext` and `InfoContext` are the logging calls that carry a context to the handler. At `INFO`, the debug record is dropped."}, {"code": "\tlevel.Set(slog.LevelDebug)\n\tlog.DebugContext(ctx, \"query plan\", \"rows\", 3)\n\tlog.Info(\"no context, no request id\")\n}\n", "note": "`level.Set` lowers the level while the program runs, and the next debug record is written. `log.Info`, with no context, reaches the handler with an empty one, so it gets no request id."}]}
```

```
ana@vm:~/logs$ go run ./levels
level=INFO msg="order placed" order=1042 request_id=r-81f3
level=DEBUG msg="query plan" rows=3 request_id=r-81f3
level=INFO msg="no context, no request id"
```

Three records out of four calls. The first `query plan` was below the level and vanished; the
second, after `level.Set`, was written. `request_id=r-81f3` was added by the handler to both calls
that carried the context, and is missing from the one that did not.

## Where a `LevelVar` is set from

In a real service the `level.Set` call sits behind something an operator can reach: a signal, a
flag read at start-up as lesson 21 showed, or an administrative endpoint. **Every handler made with
the same `LevelVar` follows it at once**, and nothing needs restarting, which is the point: the
problem is still happening while you look at it.

Turning `DEBUG` on in production is a cost as well as a help. Records are written to a disk or sent
over a network, and a hot path that logs a debug line per request can multiply the volume by a
hundred. Turn it on for as long as you need it, and set it back.

## Why the context, and not a logger in the context

A tempting alternative is to put a whole logger inside the context and fetch it everywhere. The
handler above keeps the logger where it was built and puts only the request's id in the context,
which every function in the call already receives as its first argument. **The value travels with
the request; the decision about how to write it stays in one place.** A function that logs with
`InfoContext(ctx, …)` needs to know nothing about request ids, and a request id added to the
context where the request arrives, in an HTTP handler like lesson 12's, reaches every record below
it.
