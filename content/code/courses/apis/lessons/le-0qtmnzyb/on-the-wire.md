---
title: On the wire
version: 1
---

**A Protocol Buffers message is a run of fields, and each field is a tag followed by a value.** The
tag packs the field's number and its **wire type**, which tells the reader how long the value is.
There are no names, no quotes, no braces and no commas. Everything a reader needs beyond that, it
brings from its own copy of the `.proto`.

`protoc`, the compiler lesson 1 installed, can encode a message written in Protocol Buffers' text
format. Write Dom Casmurro's stock level as text, encode it with `stock.proto`, and look at the
bytes with `od`, which prints each one in hexadecimal:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016" title: "Dom Casmurro" copies: 12 availability: IN_STOCK' > dom.txt
ana@api:~/shelf$ protoc --encode=shelf.stock.v1.StockLevel stock.proto < dom.txt > dom.bin
ana@api:~/shelf$ od -An -tx1 dom.bin
 0a 0d 39 37 38 36 35 30 30 30 30 30 30 31 36 12
 0c 44 6f 6d 20 43 61 73 6d 75 72 72 6f 18 0c 20
 01
```

Thirty-three bytes, and the figure below takes them apart a field at a time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The 33 bytes of one StockLevel in four rows, one per field. Field 1, isbn: tag 0a, length 0d, then 13 bytes of digits. Field 2, title: tag 12, length 0c, then 12 bytes spelling Dom Casmurro. Field 3, copies: tag 18, then the varint 0c, which is 12. Field 4, availability: tag 20, then 01, which is IN_STOCK.\"><rect x=\"18\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0a</text><rect x=\"40\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0d</text><rect x=\"62\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"73.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">39</text><rect x=\"84\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">37</text><rect x=\"106\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"117.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">38</text><rect x=\"128\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"139.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">36</text><rect x=\"150\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"161.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">35</text><rect x=\"172\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"183.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"194\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"216\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"227.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"238\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"260\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"282\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"304\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">31</text><rect x=\"326\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"337.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">36</text><text x=\"62\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&quot;9786500000016&quot;</text><text x=\"400\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">isbn</text><text x=\"400\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">field 1 · wire type 2</text><text x=\"560\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13 bytes follow</text><rect x=\"18\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12</text><rect x=\"40\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0c</text><rect x=\"62\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"73.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">44</text><rect x=\"84\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6f</text><rect x=\"106\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"117.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6d</text><rect x=\"128\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"139.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20</text><rect x=\"150\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"161.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43</text><rect x=\"172\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"183.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">61</text><rect x=\"194\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">73</text><rect x=\"216\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"227.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6d</text><rect x=\"238\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75</text><rect x=\"260\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">72</text><rect x=\"282\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">72</text><rect x=\"304\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6f</text><text x=\"62\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&quot;Dom Casmurro&quot;</text><text x=\"400\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">title</text><text x=\"400\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">field 2 · wire type 2</text><text x=\"560\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12 bytes follow</text><rect x=\"18\" y=\"150\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">18</text><rect x=\"40\" y=\"150\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0c</text><text x=\"40\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">12</text><text x=\"400\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">copies</text><text x=\"400\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">field 3 · wire type 0</text><text x=\"560\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a varint</text><rect x=\"18\" y=\"212\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20</text><rect x=\"40\" y=\"212\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">01</text><text x=\"40\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 = IN_STOCK</text><text x=\"400\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">availability</text><text x=\"400\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">field 4 · wire type 0</text><text x=\"560\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a varint</text><rect x=\"18\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tag: field number and wire type</text><rect x=\"250\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">length</text><rect x=\"360\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">value</text><text x=\"702\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">names on the right come from stock.proto</text></svg>", "caption": "The 33 bytes protoc wrote for Dom Casmurro, one row per field. Nothing in them says isbn or title: the reader brings those names from its own copy of stock.proto."}
```

## Reading a tag by hand

The tag is one byte here, because every field number is below 16. **Its low three bits are the wire
type and the rest is the field number.** The first byte is `0a`:

```localised
0a = 00001010
     00001        field number 1: the bits above the last three
          010     wire type 2: the last three bits
```

Wire type 2 means "a length comes next, then that many bytes", so `0d` says 13 bytes follow, and
they are the ISBN's thirteen digits as text: `39` is the character `9`. The next tag, `12`, is field
2 with the same wire type, and twelve bytes spell `Dom Casmurro`. Then `18` is field 3 with wire
type 0, a varint, and `20` is field 4, also a varint.

| wire type | means | used for |
|---|---|---|
| 0 | a varint | `int32`, `int64`, `bool`, enums |
| 1 | eight bytes | `double`, `fixed64` |
| 2 | a length, then that many bytes | `string`, `bytes`, messages, packed `repeated` |
| 5 | four bytes | `float`, `fixed32` |

## Reading a varint by hand

**A varint spends seven bits of each byte on the number and the eighth on saying whether another
byte follows.** Twelve copies fit in one byte, `0c`. Three hundred do not:

```
ana@api:~/shelf$ echo 'copies: 300' | protoc --encode=shelf.stock.v1.StockLevel stock.proto | od -An -tx1
 18 ac 02
```

After the tag `18` come `ac 02`. The low seven bits come first:

```localised
ac = 1 0101100    top bit 1: another byte follows    0101100 = 44
02 = 0 0000010    top bit 0: this is the last        0000010 = 2, worth 2 × 128
                                                     44 + 256 = 300
```

That is why small numbers are cheap and why a negative `int32` is not: its two's complement sets the
top bit, and the varint runs to its full ten bytes.

## With the schema and without it

`--decode` reads the bytes with `stock.proto`; `--decode_raw` reads them with nothing:

```
ana@api:~/shelf$ protoc --decode=shelf.stock.v1.StockLevel stock.proto < dom.bin
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 12
availability: IN_STOCK
ana@api:~/shelf$ protoc --decode_raw < dom.bin
1: "9786500000016"
2: "Dom Casmurro"
3: 12
4: 1
```

**Without the schema the names are gone, and the enum is just the number 1.** That second output is
what a stranger sees in a capture of your traffic, and what you see in your own logs if you log
the bytes. It is enough to debug with when you have the `.proto` open beside it, and nothing like
lesson 1's JSON, which explained itself to anybody who read it.

## How much smaller

The same four values as JSON, compacted by `jq` with no spaces and no final newline, against the
Protocol Buffers file:

```
ana@api:~/shelf$ wc -c < dom.bin
33
ana@api:~/shelf$ echo '{"isbn": "9786500000016", "title": "Dom Casmurro", "copies": 12, "availability": "IN_STOCK"}' | jq -cj . | wc -c
85
```

85 bytes against 33. **Most of the difference is the names**: `isbn`, `title`, `copies` and
`availability` with their quotes are 35 bytes on their own, and `"IN_STOCK"` is ten bytes where
the enum is one. The values themselves, the ISBN and the title, cost the same in both. Smaller
messages help, but they are not the strongest reason to choose gRPC, and the section on choosing
says what is.
