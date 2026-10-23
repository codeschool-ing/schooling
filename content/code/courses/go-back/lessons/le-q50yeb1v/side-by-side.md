---
title: The four side by side
version: 1
---

Five versions of one API now sit in `~/fw`. Three numbers can be read off each of them with
commands you already know: the non-blank lines of `main.go`, the modules in its module graph (`go list
-m all` counts the program's own module too), and the size of the binary in bytes.

```
ana@vm:~/fw/std$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
75
1
9807673
ana@vm:~/fw/gin$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
62
56
31606863
ana@vm:~/fw/echo$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
64
9
11094543
ana@vm:~/fw/fiber$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
60
26
15285110
ana@vm:~/fw/beego$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
73
103
21684349
```

| | lines | modules besides yours | binary |
|---|---|---|---|
| standard library | 75 | 0 | 9.8 MB |
| Gin | 62 | 55 | 31.6 MB |
| Echo | 64 | 8 | 11.1 MB |
| Fiber | 60 | 25 | 15.3 MB |
| Beego | 73 | 102 | 21.7 MB |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Two bar charts side by side for the five versions. Binary size: standard library 9.8 MB, Gin 31.6, Echo 11.1, Fiber 15.3, Beego 21.7. Modules besides the program's own: standard library 0, Gin 55, Echo 8, Fiber 25, Beego 102.\"><defs><marker id=\"gb-l4-weight-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"240\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">binary, MB</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">modules besides yours</text><text x=\"120\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">standard library</text><rect x=\"130\" y=\"40\" width=\"62.1\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"198.1\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9.8</text><rect x=\"440\" y=\"40\" width=\"1\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"447\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"120\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Gin</text><rect x=\"130\" y=\"80\" width=\"200.0\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"336.0\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">31.6</text><rect x=\"440\" y=\"80\" width=\"107.8\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"553.8\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">55</text><text x=\"120\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Echo</text><rect x=\"130\" y=\"120\" width=\"70.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"206.2\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11.1</text><rect x=\"440\" y=\"120\" width=\"15.7\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"461.7\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><text x=\"120\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Fiber</text><rect x=\"130\" y=\"160\" width=\"96.7\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"232.7\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">15.3</text><rect x=\"440\" y=\"160\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"495.0\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">25</text><text x=\"120\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Beego</text><rect x=\"130\" y=\"200\" width=\"137.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"273.2\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">21.7</text><rect x=\"440\" y=\"200\" width=\"200.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"646.0\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">102</text></svg>", "caption": "The same API five times. The lines of code barely move; the binary and the modules that come with it do."}
```

**The lines barely differ.** A framework saves about a dozen lines here, mostly the two helpers that
write JSON, and the standard library version is the longest by that much. On an API of forty routes
the saving grows with the routes, and so does the code the frameworks bring with them.

**The dependencies differ by two orders of magnitude.** Every one of those modules is code that
runs inside your process, that has to be upgraded when it has a vulnerability, and whose licence
your organisation may need to approve. Gin's `go.mod` names 31 of its modules directly, and they explain
the count: a library for each format its binding can read besides JSON (YAML, TOML, MessagePack,
BSON, Protocol Buffers), three alternative JSON encoders it can be built with, and an HTTP/3
implementation. The binary sizes follow, and a binary
three times larger is a container image three times larger to push and pull.

## How each answered the same six questions

| question | standard library | Gin | Echo | Fiber | Beego |
|---|---|---|---|---|---|
| wrong method | 405, `Allow: GET, HEAD` | **404** | 405, `Allow: OPTIONS, GET`, JSON | 405, `Allow: GET, HEAD` | **404, HTML page** |
| unknown path | 404, text | 404, text | 404, JSON | 404, text | 404, HTML page |
| invalid value | the handler's check | **validator tags**, Go field names in the message | the handler's check | the handler's check | the handler's check |
| wrong type | `encoding/json`'s message | `encoding/json`'s message | **`Bad Request` only**, detail in the log | the message, as text | `encoding/json`'s message |
| access log | none | on by default | a middleware you add, JSON | a middleware you add | startup only |
| runs on `net/http` | yes | yes | yes | **no, fasthttp** | yes |

None of these is wrong, and each is a decision taken on your behalf. **Gin's 404 for a wrong method,
Echo's hidden detail and Beego's HTML page are defaults**, and each can be changed by someone who
knows it is there. That is the real cost of a framework, and lesson 5 weighs it against what it
saves: not the bytes, but the number of behaviours in your service that you did not choose.

## Which one, if any

If a team already uses one, use that one: consistency inside a codebase is worth more than any row
of the table above. Starting fresh, the honest summary of this lesson is short. **Echo and Gin are
`net/http` underneath and easy to leave**; Echo carries less with it, and Gin more people know.
**Fiber suits people coming from Express and services where its speed has been measured to matter**,
and asks you to live outside `net/http`. **Beego suits a team that wants the whole stack chosen for
it**, and costs the most to change your mind about. And the first column is lesson 5's subject.
