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
