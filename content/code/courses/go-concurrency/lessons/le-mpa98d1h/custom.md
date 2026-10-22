---
title: Flags of your own type
version: 1
---

`String`, `Int`, `Bool` and `Duration` cover most settings, and then a program needs a flag that
can be given twice, or a number that has to be a port, or an address. **`flag.Var` accepts any type
with two methods, `String` and `Set`**, and two shorter forms cover the common cases: `flag.Func`
for a check written as a function, and `flag.TextVar` for any type that already knows how to read
itself from text. The program below uses one of each, saved as `tags/main.go`:

```schooling-example
{"language": "go", "file": "tags/main.go", "parts": [{"code": "// Command tags reads a repeatable flag, a checked number and an address.\npackage main\n\nimport (\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"net/netip\"\n\t\"strconv\"\n\t\"strings\"\n)\n\n", "note": "Three packages besides `flag`: `netip` for the address, `strconv` and `errors` for the port check."}, {"code": "// list collects every -tag it is given, in order.\ntype list []string\n\nfunc (l *list) String() string     { return strings.Join(*l, \",\") }\nfunc (l *list) Set(s string) error { *l = append(*l, s); return nil }\n\n", "note": "**`list` is a `flag.Value`: `Set` is called once for every time the flag appears**, so it appends rather than replaces. `String` is what the help shows as the default."}, {"code": "func main() {\n\tvar tags list\n\tflag.Var(&tags, \"tag\", \"a tag; repeat the flag for more\")\n\n", "note": "`flag.Var` registers the flag with no default of its own: the value starts as whatever `tags` was, an empty list."}, {"code": "\tport := 8080\n\tflag.Func(\"port\", \"TCP port, 1 to 65535 (default 8080)\", func(s string) error {\n\t\tn, err := strconv.Atoi(s)\n\t\tif err != nil || n < 1 || n > 65535 {\n\t\t\treturn errors.New(\"not a port\")\n\t\t}\n\t\tport = n\n\t\treturn nil\n\t})\n\n", "note": "`flag.Func` is `Set` without a type to hang it on. The function receives the raw text, and an error it returns becomes the message `Parse` prints. The default lives in the variable and in the help text, because the flag package never sees it."}, {"code": "\tvar addr netip.Addr\n\tflag.TextVar(&addr, \"addr\", netip.MustParseAddr(\"127.0.0.1\"), \"address to listen on\")\n\tflag.Parse()\n\n", "note": "**`flag.TextVar` takes any type with an `UnmarshalText` method**, and `netip.Addr` has one. The address is parsed and checked by the type that owns the rules, not by this program."}, {"code": "\tfmt.Println(\"tags:\", tags, len(tags))\n\tfmt.Println(\"listen:\", netip.AddrPortFrom(addr, uint16(port)))\n}\n", "note": "`netip.AddrPortFrom` joins the two into one value, which prints as an address and a port."}]}
```

The flag given twice collected both values, the port and the address arrived as typed values, and
with no flags at all the defaults stood:

```
ana@vm:~/flags$ bin/tags -tag go -tag concurrency -port 9000 -addr 192.0.2.10
tags: [go concurrency] 2
listen: 192.0.2.10:9000
ana@vm:~/flags$ bin/tags
tags: [] 0
listen: 127.0.0.1:8080
```

**A refused value is refused with the reason the program gave**: `not a port` is the error the
function returned, and the usage text and status 2 follow exactly as for a built-in flag. The
address was checked by `netip`, whose message names the field that is wrong:

```
ana@vm:~/flags$ bin/tags -port 70000; echo $?
invalid value "70000" for flag -port: not a port
Usage of bin/tags:
  -addr value
    	address to listen on (default 127.0.0.1)
  -port value
    	TCP port, 1 to 65535 (default 8080)
  -tag value
    	a tag; repeat the flag for more
2
ana@vm:~/flags$ bin/tags -addr 192.0.2.300 2>&1 | head -1
invalid value "192.0.2.300" for flag -addr: ParseAddr("192.0.2.300"): IPv4 field has value >255
```

The `2>&1 | head -1` keeps only the first line, because the usage text after it is the same as
above.

Two choices in that program are worth copying. The check lives at the edge, so everything after
`Parse` can trust `port` to be a port. And **a type that already parses itself is used rather than
re-parsed by hand**: a hand-written check for an IPv4 address is a classic place for a bug, and
`netip` has already been written.
