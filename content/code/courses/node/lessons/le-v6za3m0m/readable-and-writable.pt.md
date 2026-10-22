---
title: Streams de leitura e de escrita
version: 1
---

**Um stream de leitura produz dados em pedaços, chamados chunks; um stream de escrita os consome.** Um
arquivo lido com `createReadStream` é de leitura, um arquivo escrito com `createWriteStream` é de
escrita, e a requisição e a resposta da aula 5 são um de cada. Todo stream também é um
`EventEmitter`, e os eventos dizem o que está acontecendo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um arquivo lido como stream: o readable entrega pedaços de 64 KiB, um depois do outro, ao código que os usa, com um evento data para cada um, depois end quando o arquivo acaba, ou error se algo falhou. Só um pedaço fica nas mãos do programa de cada vez.\"><rect x=\"20\" y=\"50\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">access.log</text><text x=\"85\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127 MB no disco</text><rect x=\"180\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"242\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"268\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"304\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"366\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"392\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><rect x=\"428\" y=\"74\" width=\"52\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"454\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">64 KiB</text><line x1=\"150\" y1=\"90\" x2=\"176\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"176.0,90.0 168.6,93.1 168.6,86.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"490\" y1=\"90\" x2=\"528\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"528.0,90.0 520.6,93.1 520.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"530\" y=\"50\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o seu código</text><text x=\"615\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um pedaço de cada vez</text><text x=\"335\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">'data'  'data'  'data'  …  'end'</text><text x=\"335\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ou 'error', em qualquer ponto</text></svg>", "caption": "O arquivo nunca fica inteiro na memória: um pedaço é lido, usado e solto antes do próximo."}
```

```javascript
// chunks.js
import { createReadStream } from "node:fs";

const input = createReadStream("access.log");
let chunks = 0;
let bytes = 0;

input.on("data", (chunk) => {
  chunks++;
  bytes += chunk.length;
});
input.on("end", () => console.log(`${chunks} chunks, ${bytes} bytes, ${bytes / chunks} bytes a chunk`));
input.on("error", (err) => console.error(`could not read: ${err.code}`));
```

```
ana@dev:~/server/files$ node chunks.js
2024 chunks, 132612041 bytes, 65519.7831027668 bytes a chunk
```

**Um stream de arquivo lê 64 kibibytes de cada vez**, 65 536 bytes, que é o `highWaterMark` dele; o
último pedaço é o que sobrar, então a média sai um pouco abaixo. Cada pedaço é um Buffer, bytes, como
a primeira seção desta aula disse: o limite de um pedaço pode cair no meio de uma linha, ou de um
caractere.

## Lendo com for await

O evento `data` é o jeito antigo de ler, e ele tem uma armadilha: começa o fluxo assim que um listener
é ligado, esteja você pronto ou não. **Um stream de leitura também é um iterável assíncrono**, e o
`for await` o lê um pedaço de cada vez, esperando cada volta terminar antes de pedir o próximo:

```javascript
// iterate.js
import { createReadStream } from "node:fs";

let longest = 0;
for await (const chunk of createReadStream("access.log", { highWaterMark: 1024 * 1024 })) {
  longest = Math.max(longest, chunk.length);
}
console.log(`largest chunk: ${longest} bytes`);
```

```
ana@dev:~/server/files$ node iterate.js
largest chunk: 1048576 bytes
```

A opção `highWaterMark` escolheu o tamanho do pedaço, um mebibyte desta vez. **O `for await` é como
este curso lê streams**, como a aula 5 leu um corpo de requisição: os erros chegam como exceções no
laço, e a leitura nunca corre na frente do código que a usa.

## Escrevendo

```javascript
// write.js
import { createWriteStream } from "node:fs";
import { once } from "node:events";

const out = createWriteStream("numbers.txt");
for (let i = 1; i <= 3; i++) out.write(`line ${i}\n`);
out.end("the end\n");
await once(out, "finish");
console.log("finished, and the file is closed");
```

```
ana@dev:~/server/files$ node write.js && cat numbers.txt
finished, and the file is closed
line 1
line 2
line 3
the end
```

O `write` entrega um pedaço ao stream; o `end` entrega o último e diz que não há mais; o `finish`
dispara quando tudo chegou ao arquivo. **Um programa que sai antes do `finish` pode perder o fim do que
escreveu**, e é por isso que as últimas linhas o esperam.
