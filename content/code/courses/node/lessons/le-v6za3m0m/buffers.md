---
title: Buffers, which are bytes
version: 1
---

**A string is text; a Buffer is bytes.** Files, sockets and hashes deal in bytes, and Node hands
them to you as `Buffer` objects: fixed-length sequences of numbers from 0 to 255. Text becomes bytes
through an **encoding**, almost always UTF-8, and the difference between the two is where a whole
class of bugs lives. Lesson 1's REPL already showed one: `"olá"` is three characters and four bytes.

The work for this lesson goes in `~/server/files`, a folder with a `package.json` saying
`"type": "module"`, like lesson 5's.

```javascript
// bytes.js
const word = "olá";
const bytes = Buffer.from(word, "utf8");

console.log(word.length, bytes.length);
console.log(bytes);
console.log(bytes.toString("hex"), bytes.toString("base64"));

const link = "\u{1F517}"; // the link emoji, written as its code point
console.log(link.length, Buffer.byteLength(link));

const cut = bytes.subarray(0, 3);
console.log(cut, JSON.stringify(cut.toString("utf8")));
```

```
ana@dev:~/server/files$ node bytes.js
3 4
<Buffer 6f 6c c3 a1>
6f6cc3a1 b2zDoQ==
2 4
<Buffer 6f 6c c3> "ol�"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The word olá as characters and as bytes. o is the byte 6f and l is 6c, one byte each; á is two bytes, c3 a1, in UTF-8. So the string has 3 characters and the buffer 4 bytes. Cutting the buffer after 3 bytes splits á in half, and the half byte c3 decodes as the replacement character.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">characters: 3</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytes: 4</text><rect x=\"150\" y=\"22\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">o</text><rect x=\"218\" y=\"22\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"248.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">l</text><rect x=\"286\" y=\"22\" width=\"128\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">á</text><rect x=\"150\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6f</text><rect x=\"218\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"248\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6c</text><rect x=\"286\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"316\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">c3</text><rect x=\"354\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">a1</text><line x1=\"354\" y1=\"72\" x2=\"354\" y2=\"128\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></line><text x=\"354\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">subarray(0, 3)</text><text x=\"500\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">→ \"ol�\"</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cut in the middle of a character decodes as a replacement character</text></svg>", "caption": "length counts characters, byteLength counts bytes, and a byte boundary is not a character boundary."}
```

Read it line by line:

1. **`length` means two different things.** On the string it counts UTF-16 code units; on the Buffer
   it counts bytes. `á` is one character and two bytes, `c3 a1`.
2. **A Buffer prints as hexadecimal**, two digits a byte, which is how to look at what a file or a
   socket really holds.
3. **Hex and base64 are two ways to write bytes as text.** Base64 is what a JSON body, a cookie or an
   email uses when it has to carry bytes that are not text.
4. **An emoji is two code units and four bytes.** Neither number is "one character", and a limit
   that counts `length` on a string accepts four times as many bytes as it seems to.
5. **Bytes cut in the middle of a character do not decode.** Three of the four bytes give `ol` and
   a replacement character, `�`. This is why lesson 5 decoded a body only after joining every
   piece, and why the section on transforms reads lines with a tool that knows where they end.

`Buffer.from(string)`, `buf.toString(encoding)` and `Buffer.byteLength(string)` are most of what a
server needs. A Buffer is also a `Uint8Array`, so every typed-array method works on it.
