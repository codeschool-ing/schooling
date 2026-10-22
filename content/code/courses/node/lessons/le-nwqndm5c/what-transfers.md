---
title: What carried over
version: 1
---

**Read the five programs again with this course's lessons beside them, and almost nothing in them is
new.** The syntax is, and each language's names for things. What a server *does* is the same in all
of them, because it is HTTP's and the operating system's, not JavaScript's:

| the idea | in this course | in every one of the five |
|---|---|---|
| a request is a method, a path, headers and a body | lessons 5 and 6 | the handler receives exactly those |
| a status code says how it went | lesson 7 | `send_response(404)`, `WriteHeader`, `sendResponseHeaders`, `http_response_code`, `statusCode:` |
| JSON is text with a content type | lessons 5 and 7 | each sets `content-type: application/json` itself |
| configuration comes from the environment | lesson 9 | `os.environ`, `os.Getenv`, `System.getenv`, `$_SERVER`, `Environment` |
| a blocked thread stops what it serves | lessons 2 and 10 | the concurrency models above |
| stop on `SIGTERM` without dropping requests | lesson 10 | ASP.NET Core does it; Go's `Server.Shutdown`; the others through their servers |
| state kept in memory breaks under several copies | lesson 10 | the same, except PHP, which keeps none |
| packages, a manifest and a lockfile | lesson 4 | `pip` and `pyproject.toml`, `go.mod`, Maven, Composer, NuGet |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two layers. The lower one, which carries over between languages: HTTP, status codes, JSON, configuration from the environment, signals and graceful shutdown, state outside the process, packages with a lockfile. The upper one, learnt again for each language: syntax, the framework, its libraries, its tools and its error messages.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">learnt again for each language</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">syntax · the framework · its libraries · its tools · its error messages</text><rect x=\"20\" y=\"110\" width=\"680\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">carried over, from this course</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP · status codes · JSON · configuration from the environment</text><text x=\"360\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SIGTERM and a graceful stop · state outside the process · a lockfile</text></svg>", "caption": "The lower layer is what a server is; the upper layer is how one language spells it."}
```

The configuration row is the one to see run, because it is the one every deployment depends on. The
same `PORT`, given to five of the six at once, in one terminal; PHP takes its port on its command line
and sits this one out:

```
ana@dev:~/server/other$ (cd node && PORT=4001 node hello.mjs) & (cd python && PORT=4002 python3 hello.py) & (cd go && PORT=4003 ./hello) & (cd java && PORT=4004 java Hello.java) & (cd csharp && PORT=4005 dotnet run --no-build) & wait
2026/10/22 20:12:23 go on :4003
python on :4002
node on :4001
Using launch settings from /home/ana/server/other/csharp/Properties/launchSettings.json...
java on :4004
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:4005
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /home/ana/server/other/csharp
127.0.0.1 - - [22/Oct/2026 20:12:24] "GET /hello?name=port-4002 HTTP/1.1" 200 -
^C
```

And in a second one:

```
ana@dev:~/server/other$ for p in 4001 4002 4003 4004 4005; do curl -s "http://127.0.0.1:$p/hello?name=port-$p"; done
{"hello":"port-4001"}
{"hello": "port-4002"}
{"hello":"port-4003"}

{"hello":"port-4004"}
{"hello":"port-4005"}
```

**Five languages, one variable, five answers**, each on the port it was told. A process manager, a
container platform or a systemd unit from lesson 10 starts any of them the same way: a command, an
environment, and `SIGTERM` to stop it.

**What does not transfer is the ecosystem.** Which framework to use, how its middleware is written,
which package does JSON or talks to a database, what the error messages mean, where the runtime's
documentation hides the thing you need: each of those is learnt again, and each takes the time lesson
1 said it would. The difference is that you would be learning *Go's way of doing* something you
already understand, which is a fraction of learning the thing.
