---
title: Buffers, que são bytes
version: 1
---

**Uma string é texto; um Buffer é bytes.** Arquivos, sockets e hashes lidam com bytes, e o Node os
entrega a você como objetos `Buffer`: sequências de tamanho fixo de números de 0 a 255. Texto vira
bytes por meio de uma **codificação**, quase sempre UTF-8, e a diferença entre os dois é onde mora uma
família inteira de bugs. O REPL da aula 1 já mostrou uma: `"olá"` tem três caracteres e quatro bytes.

O trabalho desta aula fica em `~/server/files`, uma pasta com um `package.json` que diz
`"type": "module"`, como a da aula 5.

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
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A palavra olá como caracteres e como bytes. O o é o byte 6f e o l é 6c, um byte cada; o á são dois bytes, c3 a1, em UTF-8. Então a string tem 3 caracteres e o buffer 4 bytes. Cortar o buffer depois de 3 bytes divide o á ao meio, e o meio byte c3 vira o caractere de substituição.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">caracteres: 3</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">bytes: 4</text><rect x=\"150\" y=\"22\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">o</text><rect x=\"218\" y=\"22\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"248.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">l</text><rect x=\"286\" y=\"22\" width=\"128\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">á</text><rect x=\"150\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6f</text><rect x=\"218\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"248\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">6c</text><rect x=\"286\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"316\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">c3</text><rect x=\"354\" y=\"82\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">a1</text><line x1=\"354\" y1=\"72\" x2=\"354\" y2=\"128\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"4 3\"></line><text x=\"354\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">subarray(0, 3)</text><text x=\"500\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">→ \"ol�\"</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um corte no meio de um caractere vira um caractere de substituição</text></svg>", "caption": "O length conta caracteres, o byteLength conta bytes, e uma fronteira de byte não é uma fronteira de caractere.", "same": ["bytes: 4"]}
```

Leia linha a linha:

1. **`length` quer dizer duas coisas diferentes.** Na string ele conta unidades de código UTF-16; no
   Buffer, bytes. O `á` é um caractere e dois bytes, `c3 a1`.
2. **Um Buffer é impresso em hexadecimal**, dois dígitos por byte, que é como se olha o que um arquivo
   ou um socket realmente tem.
3. **Hex e base64 são dois jeitos de escrever bytes como texto.** O base64 é o que um corpo JSON, um
   cookie ou um e-mail usa quando precisa levar bytes que não são texto.
4. **Um emoji são duas unidades de código e quatro bytes.** Nenhum dos dois números é "um caractere",
   e um limite que conta o `length` de uma string aceita quatro vezes mais bytes do que parece.
5. **Bytes cortados no meio de um caractere não decodificam.** Três dos quatro bytes dão `ol` e um
   caractere de substituição, `�`. É por isso que a aula 5 só decodificava um corpo depois de
   juntar todos os pedaços, e por isso a seção sobre transforms lê linhas com uma ferramenta que sabe
   onde elas terminam.

`Buffer.from(string)`, `buf.toString(codificação)` e `Buffer.byteLength(string)` são a maior parte do
que um servidor precisa. Um Buffer também é um `Uint8Array`, então todo método de array tipado
funciona nele.
