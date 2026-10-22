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
