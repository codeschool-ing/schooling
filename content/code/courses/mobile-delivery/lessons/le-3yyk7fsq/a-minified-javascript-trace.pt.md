---
title: Uma pilha JavaScript minificada, e o source map dela
version: 1
---

**Um release React Native leva o JavaScript como um único bundle minificado, e um crash nele aponta
para a linha 1 e uma coluna.** O **source map** produzido ao lado do bundle diz, para cada posição do
bundle, de que arquivo, linha e coluna do seu código ela veio. Aqui quem empacota é o **esbuild**, que
faz o mesmo trabalho do Metro do React Native para este propósito, e quem lê é a biblioteca
`source-map` que os próprios coletores de crash usam.

Instale os dois em `~/planner`, com versão fixada:

```sh
npm install -E esbuild@0.28.2 source-map@0.8.0
```

## Um bug pequeno, gerado para release

Salve isto como `week.ts`:

```typescript
// week.ts: the planner's week total, with the bug of lesson 12
type Session = { course: string; minutes: number };
const byCourse: Record<string, Session[]> = { spanish: [{ course: "spanish", minutes: 30 }] };

export function totalFor(course: string): number {
  return byCourse[course].reduce((n, s) => n + s.minutes, 0);
}

console.log("spanish", totalFor("spanish"));
console.log("guitar", totalFor(process.argv[2] ?? "guitar"));
```

Empacote do jeito que um release faz, minificado, com um source map, e rode:

```
ana@dev:~/planner$ npx esbuild week.ts --bundle --minify --sourcemap --platform=node --format=esm --log-level=warning --outfile=dist/bundle.js
ana@dev:~/planner$ ls dist; cat dist/bundle.js
bundle.js
bundle.js.map
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
//# sourceMappingURL=bundle.js.map
ana@dev:~/planner$ node dist/bundle.js 2> trace.txt; cat trace.txt
spanish 30
file:///home/ana/planner/dist/bundle.js:1
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
                                                                          ^

TypeError: Cannot read properties of undefined (reading 'reduce')
    at s (file:///home/ana/planner/dist/bundle.js:1:75)
    at file:///home/ana/planner/dist/bundle.js:1:161
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

A pilha está correta e não serve para nada: função `s`, linha 1, coluna 75. Nada nela diz `totalFor`
ou `week.ts`.

## Lendo de volta

Salve isto como `symbolicate.ts`. Ele lê uma pilha da entrada padrão e um source map nomeado na
linha de comando, e reescreve cada quadro que aponta para dentro do bundle:

```schooling-example
{"language": "typescript", "file": "symbolicate.ts", "parts": [{"code": "// symbolicate.ts: rewrite the frames of a minified trace through the bundle's source map\nimport { SourceMapConsumer } from \"source-map\";\nimport { readFileSync } from \"node:fs\";\n\nconst map = JSON.parse(readFileSync(process.argv[2], \"utf8\"));\nconst trace = readFileSync(0, \"utf8\");", "note": "O source map, nomeado na linha de comando, e a pilha, lida da entrada padrão, para que uma pilha possa ser passada direto por um pipe."}, {"code": "const FRAME = /^(\\s*at )(?:(\\S+) \\()?(.*bundle\\.js):(\\d+):(\\d+)\\)?$/;", "note": "Um quadro que aponta para o bundle: um nome de função opcional, depois o arquivo, a linha e a coluna."}, {"code": "await SourceMapConsumer.with(map, null, (consumer) => {\n  for (const line of trace.trimEnd().split(\"\\n\")) {\n    const m = line.match(FRAME);\n    if (!m) {\n      console.log(line);\n      continue;\n    }", "note": "Toda linha que não é um quadro desses é impressa como veio: a mensagem, e os quadros do próprio Node."}, {"code": "    const p = consumer.originalPositionFor({ line: Number(m[4]), column: Number(m[5]) - 1 });\n    console.log(`${m[1]}${p.source}:${p.line}:${p.column + 1}  (bundle ${m[2] ?? \"top level\"} ${m[4]}:${m[5]})`);\n  }\n});", "note": "As colunas do mapa contam a partir de 0 e as de uma pilha a partir de 1, daí as duas correções. O nome minificado fica entre parênteses."}]}
```

```
ana@dev:~/planner$ node symbolicate.ts dist/bundle.js.map < trace.txt
file:///home/ana/planner/dist/bundle.js:1
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
                                                                          ^

TypeError: Cannot read properties of undefined (reading 'reduce')
    at ../week.ts:6:27  (bundle s 1:75)
    at ../week.ts:10:23  (bundle top level 1:161)
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

Agora o primeiro quadro é `week.ts`, linha 6, o `reduce` num curso que não está ali, e o segundo é a
linha 10, a chamada com `guitar`. Os nomes minificados ficam ao lado, porque são eles que o coletor
de crashes usou para agrupar. Os quadros do próprio Node, os de `node:internal`, ficam como estão:
eles nunca foram minificados.

## O que um coletor de crashes faz com isso

Exatamente isto, no servidor dele: o source map é enviado com o release, e todo relatório daquele
release é reescrito antes que alguém o leia. No seu próprio computador, o Node consegue fazer isso
durante a execução com `node --enable-source-maps`; num celular, o Hermes roda o bundle sem o mapa,
que fica na sua máquina de build, e o servidor é onde os dois se encontram.
