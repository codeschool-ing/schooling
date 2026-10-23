---
title: Onde o Node procura o que você nomeou
version: 1
---

**O que você escreve depois de `require` ou `from` é um especificador, e o Node o lê de um de três
jeitos.** Qual jeito depende só de como ele começa:

| o especificador | o que ele nomeia | exemplo |
|---|---|---|
| começa com `node:` | um módulo embutido no Node | `node:fs`, `node:http` |
| começa com `./`, `../` ou `/` | um arquivo, pelo caminho | `./store.js`, `../config.js` |
| qualquer outra coisa | um **pacote**, procurado em pastas `node_modules` | `express`, `tidy/words` |

A terceira linha é a que tem uma busca. O Node procura em `node_modules` ao lado do arquivo que pede,
depois no `node_modules` da pasta acima, e assim por diante até `/`, e para no primeiro que tiver uma
pasta com aquele nome. Um arquivo CommonJS consegue imprimir a própria lista:

```
ana@dev:~/server/modules/pkg$ node -p module.paths
[
  '/home/ana/server/modules/pkg/node_modules',
  '/home/ana/server/modules/node_modules',
  '/home/ana/server/node_modules',
  '/home/ana/node_modules',
  '/home/node_modules',
  '/node_modules'
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Pastas aninhadas, de / até /home/ana/server/modules/pkg, onde está o arquivo que chama require(&quot;tidy&quot;). O Node procura uma pasta node_modules primeiro em pkg, depois em cada pasta acima, até /, e para na primeira que tiver tidy.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/</text><rect x=\"42\" y=\"48\" width=\"636\" height=\"198\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home</text><rect x=\"64\" y=\"82\" width=\"592\" height=\"164\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home/ana</text><rect x=\"86\" y=\"116\" width=\"548\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/home/ana/server</text><rect x=\"108\" y=\"150\" width=\"504\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"118\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/server/modules</text><rect x=\"130\" y=\"184\" width=\"460\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/server/modules/pkg</text><rect x=\"146\" y=\"210\" width=\"150\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"221\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">require(\"tidy\")</text><text x=\"560\" y=\"197\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">1. node_modules/tidy ?</text><text x=\"560\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2. node_modules/tidy ?</text><text x=\"560\" y=\"129\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3. node_modules/tidy ?</text><text x=\"560\" y=\"95\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4. node_modules/tidy ?</text><text x=\"560\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5. node_modules/tidy ?</text><text x=\"560\" y=\"27\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6. node_modules/tidy ?</text></svg>", "caption": "Uma pasta de cada vez, do arquivo para fora. A primeira node_modules que tiver o pacote vence."}
```

Então um pacote instalado num projeto é encontrado por todo arquivo do projeto, por mais fundo que
esteja. E um `node_modules` no seu diretório home, deixado ali por uma instalação rodada na pasta
errada, é encontrado por todo projeto debaixo de `~` que não tenha o pacote. **Quando um pacote é
encontrado e não devia ser, o `require.resolve` diz qual arquivo foi escolhido:**

```
ana@dev:~/server/modules/pkg$ node -p 'require.resolve("tidy")'
/home/ana/server/modules/pkg/node_modules/tidy/dist/tidy.cjs
```

Esse caminho termina em `dist/tidy.cjs`, que não é um nome que alguém escreveu no `require`; foi o
pacote que escolheu, e a seção sobre `exports` mostra como.

## Caminhos: o CommonJS adivinha, os ES modules não

O CommonJS completa o que você deixa de fora. `require("./lib")` tenta `./lib`, depois `./lib.js`,
`./lib.json` e `./lib.node`, depois uma pasta `./lib` com o `index.js` dela. **Um `import` não faz
nada disso**: o caminho é uma URL, e precisa nomear o arquivo, com extensão. Uma pasta `lib` com um
`index.js` dentro mostra as duas coisas, e os arquivos são criados pelas próprias linhas que os
usam:

```
ana@dev:~/server/modules/paths$ mkdir lib && echo 'module.exports = "lib/index.js";' > lib/index.js
ana@dev:~/server/modules/paths$ node -e 'console.log(require("./lib"))'
lib/index.js
ana@dev:~/server/modules/paths$ echo 'import x from "./lib/index"; console.log(x);' > no-extension.mjs
ana@dev:~/server/modules/paths$ node no-extension.mjs 2>&1 | grep -E "^Error"
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/server/modules/paths/lib/index' imported from /home/ana/server/modules/paths/no-extension.mjs
ana@dev:~/server/modules/paths$ echo 'import x from "./lib"; console.log(x);' > folder.mjs
ana@dev:~/server/modules/paths$ node folder.mjs 2>&1 | grep -A1 -E "^Error"
Error [ERR_UNSUPPORTED_DIR_IMPORT]: Directory import '/home/ana/server/modules/paths/lib' is not supported resolving ES modules imported from /home/ana/server/modules/paths/folder.mjs
Did you mean to import "./lib/index.js"?
```

Os dois erros são os dois palpites que os ES modules se recusam a dar: sem extensão, e uma pasta. As
duas mensagens dizem qual é o problema, e a segunda diz a solução. Escrever o caminho inteiro custa
alguns caracteres e compra algo real: o que uma linha importa pode ser lido na própria linha, sem
saber quais arquivos existem ao lado dela.
