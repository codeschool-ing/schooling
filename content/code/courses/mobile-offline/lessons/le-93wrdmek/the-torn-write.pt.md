---
title: A escrita rasgada, e o renomear que a evita
version: 1
---

**Um celular mata apps sem pedir licença, e um arquivo que estava sendo gravado nessa hora fica
gravado pela metade.** A pessoa arrasta o app para fora, o sistema precisa de memória para a
câmera, a bateria acaba. O app não ganha chance de terminar. O que o arquivo tinha naquele instante
é o que a próxima abertura lê.

Dá vontade de achar que a janela é curta demais para importar. Um arquivo de configurações é
gravado em bem menos de um milissegundo. Mas apps salvam com frequência, celulares são mortos com
frequência, e alguns milhões de instalações multiplicam uma chance pequena num fluxo constante de
gente que abre o app e encontra as configurações perdidas, ou o app quebrando ao abrir porque o
arquivo não se interpreta mais.

## Medido, parando de propósito

Ninguém consegue cronometrar uma morte para cair no meio de uma escrita, então este programa para
sozinho: ele grava metade das configurações novas, exatamente onde cada abordagem estaria gravando
naquele momento, e depois faz o que a próxima abertura faz. Salve como `torn.ts` na
`~/planner/prefs`:

```typescript
// torn.ts: save new settings and stop halfway through, as a process killed mid-write would.
import { closeSync, openSync, writeFileSync, writeSync } from "node:fs";
import { load } from "./kv.ts";

const mode = process.argv[2]; // "in-place" or "rename"
const path = "torn.json";
writeFileSync(path, JSON.stringify({ theme: "light", reminders: true }, null, 2) + "\n");

const next = JSON.stringify({ theme: "dark", reminders: true, dailyGoal: 45 }, null, 2) + "\n";
const half = next.slice(0, Math.floor(next.length / 2));
const target = mode === "rename" ? `${path}.tmp` : path;
const fd = openSync(target, "w"); // "w" empties the file before a byte is written
writeSync(fd, half);
closeSync(fd);
console.log(`wrote ${half.length} of ${next.length} bytes to ${target}, then stopped`);

// The next launch reads the store.
try {
  console.log("next launch reads", load(path));
} catch (e) {
  console.log("next launch fails:", (e as Error).message);
}
```

O comentário no `openSync` é o problema inteiro. Abrir um arquivo com `"w"` **o esvazia primeiro**,
então desse instante até o último byte chegar, a única cópia das configurações no disco está
incompleta:

```
ana@dev:~/planner/prefs$ node torn.ts in-place
wrote 31 of 62 bytes to torn.json, then stopped
next launch fails: Unterminated string in JSON at position 31 (line 3 column 11)
ana@dev:~/planner/prefs$ node torn.ts rename
wrote 31 of 62 bytes to torn.json.tmp, then stopped
next launch reads { theme: 'light', reminders: true }
ana@dev:~/planner/prefs$ ls
grow.ts
kv.ts
settings.json
settings.ts
torn.json
torn.json.tmp
torn.ts
```

Gravado no lugar, a próxima abertura encontra 31 bytes de um arquivo de 62 e o parser para na
posição 31. Gravado ao lado, o arquivo inacabado é `torn.json.tmp`, que ninguém lê, e o arquivo
verdadeiro ainda guarda as configurações antigas, inteiras. A pessoa perde a única mudança que
estava fazendo, e nada mais. O próximo salvamento sobrescreve o `.tmp` que sobrou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l02-torn\" aria-label=\"Dois jeitos de salvar configurações, cada um em três momentos. Gravado no lugar: antes, torn.json guarda as configurações antigas; o processo é morto no meio, e torn.json guarda 31 de 62 bytes; a próxima abertura não consegue interpretá-lo. Gravado ao lado e renomeado: antes, torn.json guarda as configurações antigas; morto no meio, torn.json.tmp guarda 31 bytes e torn.json está intacto; a próxima abertura lê as configurações antigas, inteiras.\"><defs><marker id=\"l02-torn-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">antes de salvar</text><text x=\"430\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">morto no meio</text><text x=\"610\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">a próxima abertura</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">no lugar</text><rect x=\"170\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"250.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">configurações antigas</text><rect x=\"350\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"430.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">31 de 62 bytes</text><rect x=\"530\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não se interpreta</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">ao lado, depois renomeado</text><rect x=\"170\" y=\"162\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"185.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"250.0\" y=\"198.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">configurações antigas</text><rect x=\"350\" y=\"146\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">torn.json.tmp</text><text x=\"430.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">31 de 62 bytes</text><rect x=\"350\" y=\"196\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">torn.json</text><text x=\"430.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">antigas, intactas</text><rect x=\"530\" y=\"162\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">lê as antigas</text><path d=\"M330 82 L350 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M510 82 L530 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M330 192 L350 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M510 192 L530 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path></svg>", "caption": "Abrir um arquivo para gravar o esvazia. Gravado no lugar, uma morte deixa a única cópia pela metade; gravado ao lado, deixa um arquivo que ninguém lê.", "same": ["torn.json", "torn.json.tmp"]}
```

## O que torna o renomear seguro

No Linux, no Android, no macOS e no iOS, renomear um arquivo por cima de outro no mesmo disco é
**atômico**: não existe momento em que um leitor não encontre nenhum dos dois, ou metade de um. É
por isso que o arquivo temporário fica na mesma pasta do verdadeiro. Um renomear entre dois discos
é uma cópia e uma exclusão, e perde a garantia.

Os armazenamentos das plataformas já fazem isso, o que é um bom motivo para usá-los em vez de
escrever o seu próprio arquivo JSON. O DataStore grava num arquivo temporário e o renomeia; o
`SharedPreferences` mantém uma cópia de segurança enquanto grava e a restaura se a escrita não
terminou. A regra continua valendo para todo arquivo que o próprio app grava, o anexo, a
exportação, a imagem baixada da aula 18: **nunca grave por cima da única cópia.**
