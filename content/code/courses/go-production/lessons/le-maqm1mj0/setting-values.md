---
title: Changing a value, and calling a method by name
version: 1
---

Reading is half of what `reflect` does. The other half is writing: setting a variable, filling in a
struct field by its name, calling a method whose name arrived as a string. `encoding/json` does the
first two every time it decodes, and `text/template` does the third when a template says
`{{.Describe}}`: it calls `MethodByName` with the word it read. **The rule for writing is the one `go` lessons 22 and 23 taught for functions: to
change a variable you need its address, and a copy will not do.** Reflection only makes the rule
visible, as a method called `CanSet`.

## Settable means reachable through an address

A program that sets an `int`, a struct field and calls a method, and that makes one mistake chosen
by its argument, in `~/reflect`:

```schooling-example
{
  "language": "go",
  "file": "set/main.go",
  "parts": [
    {
      "code": "// Command set changes values through reflect, and with an argument makes\n// one of the mistakes reflect refuses at run time.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"reflect\"\n)\n\n// Config is something a program might fill in by reflection.\ntype Config struct {\n\tName   string\n\tLimit  int\n\tsecret string\n}\n\n// Describe is a method for reflect to find by its name.\nfunc (c Config) Describe(prefix string) string {\n\treturn fmt.Sprintf(\"%s %s keeps %d\", prefix, c.Name, c.Limit)\n}\n",
      "note": "A struct with two exported fields and one unexported, and a method with one parameter, so there is something to set and something to call."
    },
    {
      "code": "func main() {\n\tx := 10\n\tv := reflect.ValueOf(x)\n\te := reflect.ValueOf(&x).Elem()\n\tfmt.Println(\"ValueOf(x).CanSet():\", v.CanSet())\n\tfmt.Println(\"ValueOf(&x).Elem().CanSet():\", e.CanSet())\n\te.SetInt(25)\n\tfmt.Println(\"x is now\", x)\n",
      "note": "**`v` holds a copy of `x`; `e` reaches `x` itself, through its address.** Only `e` can be set, and setting it changes the variable the program declared."
    },
    {
      "code": "\tc := Config{Name: \"hits\", Limit: 3}\n\ts := reflect.ValueOf(&c).Elem()\n\ts.FieldByName(\"Limit\").SetInt(10)\n\tfmt.Printf(\"%+v\\n\", c)\n\tfmt.Println(\"secret CanSet():\", s.FieldByName(\"secret\").CanSet())\n",
      "note": "The same rule for a struct: start from a pointer, take `Elem`, and every exported field below it is settable. `secret` is reachable and still refused."
    },
    {
      "code": "\tm := reflect.ValueOf(c).MethodByName(\"Describe\")\n\tout := m.Call([]reflect.Value{reflect.ValueOf(\"config\")})\n\tfmt.Println(out[0])\n",
      "note": "`MethodByName` finds a method by a string, and `Call` takes the arguments as a slice of `reflect.Value` and returns the results the same way."
    },
    {
      "code": "\tif len(os.Args) < 2 {\n\t\treturn\n\t}\n\tswitch os.Args[1] {\n\tcase \"copy\":\n\t\tv.SetInt(25)\n\tcase \"kind\":\n\t\te.SetString(\"ten\")\n\tcase \"unexported\":\n\t\ts.FieldByName(\"secret\").SetString(\"open\")\n\tcase \"args\":\n\t\tm.Call(nil)\n\tcase \"typo\":\n\t\treflect.ValueOf(c).MethodByName(\"Describ\").Call(nil)\n\t}\n}",
      "note": "Each word on the command line makes one mistake. **All five compile, and all five pass `go vet`**: the compiler sees calls to methods of `reflect.Value` with the right types, which is all there is to see."
    }
  ]
}
```

Checked by `go vet`, then run with no argument:

```
ana@vm:~/reflect$ go vet ./set && go run ./set
ValueOf(x).CanSet(): false
ValueOf(&x).Elem().CanSet(): true
x is now 25
{Name:hits Limit:10 secret:}
secret CanSet(): false
config hits keeps 10
```

**`ValueOf(x)` cannot be set, and `ValueOf(&x).Elem()` can.** Section 02 showed why: `ValueOf`
receives an `any`, and putting `x` into an `any` copied it. Setting that copy would change nothing
anybody can see, so the package refuses to pretend. Passing `&x` puts a pointer in the `any`
instead, a copy of the address, and `Elem` follows the address back to the variable itself. `x is now
25` is the proof that it was the real `x`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The variable x holds 10. reflect.ValueOf(x) receives a copy of 10 inside an any, so its Value reports CanSet false, and SetInt panics with unaddressable value. reflect.ValueOf(&amp;x).Elem() starts from a pointer to x, so its Value is x itself, CanSet is true, and e.SetInt(25) turns x from 10 into 25.\"><defs><marker id=\"st-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"st-phos\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"st-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">x := 10</text><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the variable x</text><rect x=\"300\" y=\"88\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10  -&gt;  25</text><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reflect.ValueOf(x)</text><rect x=\"40\" y=\"88\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a copy of 10, in the any</text><path d=\"M298 108 L224 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#st-amber)\"></path><text x=\"260\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">copied</text><text x=\"130\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CanSet() == false</text><text x=\"130\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">setting it would change only the copy,</text><text x=\"130\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">so SetInt panics instead</text><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">reflect.ValueOf(&amp;x).Elem()</text><rect x=\"500\" y=\"88\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a pointer to x</text><path d=\"M498 108 L424 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-phos)\"></path><text x=\"460\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">points at x</text><text x=\"590\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">CanSet() == true</text><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">setting it changes x itself:</text><text x=\"590\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">e.SetInt(25)</text></svg>", "caption": "Settable means reachable through an address. ValueOf(x) is handed a copy; ValueOf(&x).Elem() is handed the way back to x."}
```

The struct works the same way. **`ValueOf(&c).Elem()` is the struct `c` itself, and every exported
field below it is settable**, and `Limit` went from 3 to 10. `secret` is reachable and still `CanSet() false`,
for the reason section 03 gave, and the refusal holds even here, inside package `main`, where
`Config` was declared and ordinary code may write `c.secret` freely. `%+v` printed `secret:` with its empty value, which shows that `fmt`
reads unexported fields when it prints; reading is allowed, writing is not.

`MethodByName("Describe")` returned the method as a `Value` bound to `c`, and `Call` ran it. **The
arguments go in as a `[]reflect.Value` and the results come back the same way**, so `out[0]` is a
`Value` holding the string. `Describe` saw `Limit` as 10, because `c` had been changed before
`ValueOf(c)` copied it.

## Five mistakes, and when each one is found

Each argument makes one mistake. Only the first line of each panic is shown here:

```
ana@vm:~/reflect$ for m in copy kind unexported args typo; do go run ./set $m 2>&1 | grep ^panic; done
panic: reflect: reflect.Value.SetInt using unaddressable value
panic: reflect: call of reflect.Value.SetString on int Value
panic: reflect: reflect.Value.SetString using value obtained using unexported field
panic: reflect: Call with too few input arguments
panic: reflect: call of reflect.Value.Call on zero Value
```

| argument | what the program did | the same mistake without `reflect` |
|---|---|---|
| `copy` | set a `Value` made from `x` instead of `&x` | changing a parameter, which compiles and does nothing |
| `kind` | `SetString` on an `int` | `x = "ten"`, a compile error |
| `unexported` | set `secret` | `c.secret = "open"` from another package, a compile error |
| `args` | called `Describe` with no argument | `c.Describe()`, a compile error |
| `typo` | asked for `Describ`, got the zero `Value`, called it | `c.Describ`, a compile error |

**Four of the five are compile errors in ordinary Go, and every one of them compiled here and passed
`go vet`**, which ran clean on this file in the first transcript. `typo` is the nastiest: **a misspelled
name does not fail where it is spelt**. `MethodByName` returns the zero `Value` without complaint, and
the panic comes from `Call`, a line later, saying `zero Value` rather than naming the method nobody
found. In a larger program that line can be far from the typo.

A whole panic, for `kind`:

```
ana@vm:~/reflect$ go run ./set kind 2>&1 | sed -n 7,20p
panic: reflect: call of reflect.Value.SetString on int Value

goroutine 1 [running]:
reflect.flag.mustBe(...)
	/usr/local/go/src/reflect/value.go:221
reflect.Value.SetString({0x577438?, 0x26f713b75d68?, 0x26f713b75df0?}, {0x4aa05b, 0x3})
	/usr/local/go/src/reflect/value.go:2330 +0xe7
main.main()
	/home/ana/reflect/set/main.go:49 +0x59f
exit status 2
```

The trace points at `set/main.go:49`, the `SetString` call, and `go run` reports the program's exit
status 2. A panic stops the program at the first bad call it reaches, so **a reflective code path
that no test runs is a code path whose mistakes nobody has seen**. A library that reflects on
values it was given usually checks `Kind` and `CanSet` before every write and returns an error, as
`columns.Reflect` checks for a slice of structs in section 03. Doing that by hand, for every case, is
part of what reflection costs.
