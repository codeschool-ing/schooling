---
title: Como o Node decide qual um arquivo é
version: 1
---

**A extensão do arquivo decide primeiro, e para um `.js` comum quem decide é o `package.json` mais
próximo.** Essa é a regra inteira, e vale tê-la exata:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Como o Node decide o que um arquivo é. Um arquivo .mjs é ES module e um .cjs é CommonJS. Para um .js, o Node procura o package.json mais próximo: &quot;type&quot;: &quot;module&quot; faz dele um ES module; qualquer outro package.json faz dele CommonJS; sem package.json nenhum, o Node detecta a sintaxe.\"><rect x=\"20\" y=\"95\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o arquivo</text><rect x=\"180\" y=\"20\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.mjs</text><rect x=\"180\" y=\"100\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.js</text><rect x=\"180\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.cjs</text><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,40.0 176.9,47.9 171.5,44.7\" fill=\"var(--paper-dim)\"></polygon><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,120.0 170.6,123.1 170.6,116.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"130\" y1=\"120\" x2=\"178\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"178.0,200.0 171.5,195.3 176.9,192.1\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"85\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">package.json</text><text x=\"455.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">package.json</text><line x1=\"320\" y1=\"120\" x2=\"378\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,120.0 370.6,123.1 370.6,116.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"580\" y=\"14\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ES module</text><rect x=\"580\" y=\"176\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">CommonJS</text><line x1=\"320\" y1=\"40\" x2=\"578\" y2=\"40\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,40.0 570.6,43.1 570.6,36.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"320\" y1=\"200\" x2=\"578\" y2=\"200\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,200.0 570.6,203.1 570.6,196.9\" fill=\"var(--amber)\"></polygon><line x1=\"530\" y1=\"100\" x2=\"578\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,52.0 575.0,59.4 570.6,55.0\" fill=\"var(--phosphor)\"></polygon><text x=\"562\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">\"type\": \"module\"</text><line x1=\"530\" y1=\"140\" x2=\"578\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,188.0 570.6,185.0 575.0,180.6\" fill=\"var(--amber)\"></polygon><text x=\"562\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">qualquer outro</text><text x=\"455\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum: detecta a sintaxe</text></svg>", "caption": "A extensão vence. Só um .js comum pergunta ao package.json, e todo projeto deste curso diz \"type\": \"module\".", "same": ["CommonJS", "ES module"]}
```

- `.mjs` é sempre ES module, e `.cjs` é sempre CommonJS, onde quer que estejam.
- `.js` sobe pelas pastas, da sua em direção a `/`, até o primeiro `package.json`. Se esse arquivo
  disser `"type": "module"`, o `.js` é um ES module. Se disser `"type": "commonjs"`, ou não disser
  nada sobre `type`, o arquivo é CommonJS.

O mesmo `hello.js`, em três pastas chamadas `none`, `typeless` e `typed`:

```javascript
// hello.js
import os from "node:os";
console.log(`${os.platform()} has ${os.cpus().length} processors`);
```

A `none` não tem `package.json`. Dê à `typeless` um só com um nome, e à `typed` um que diga
`"type": "module"`:

```
ana@dev:~/server/modules$ cat typeless/package.json typed/package.json
{ "name": "typeless" }
{ "name": "typed", "type": "module" }
ana@dev:~/server/modules$ cd none && node hello.js
linux has 4 processors
ana@dev:~/server/modules/none$ cd ../typeless && node hello.js
linux has 4 processors
(node:15484) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/server/modules/typeless/hello.js is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/server/modules/typeless/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
ana@dev:~/server/modules/typeless$ cd ../typed && node hello.js
linux has 4 processors
```

Os três rodaram, e o do meio reclamou, que é a parte a entender.

**A `none` não tem `package.json` em lugar nenhum acima dela.** O Node 22 então *detecta* a sintaxe:
tenta o arquivo como CommonJS, encontra `import`, e o roda como ES module. Essa detecção é um
recurso de reserva, acrescentado para scripts sem projeto em volta.

**A `typeless` tem um `package.json` sem `type`**, então pela regra o arquivo é CommonJS. Ele não é,
e o Node diz isso, reprocessa o arquivo, e informa o custo — todo arquivo carregado duas vezes — e a
solução, nas últimas linhas do aviso. **A `typed` diz `"type": "module"`**, e roda em silêncio.

## Na outra direção

Um arquivo escrito em CommonJS, numa pasta que diz `"type": "module"`, falha de vez:

```javascript
// old.js
const os = require("node:os");
console.log(os.platform());
```

```
ana@dev:~/server/modules/typed$ node old.js
file:///home/ana/server/modules/typed/old.js:2
const os = require("node:os");
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and '/home/ana/server/modules/typed/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///home/ana/server/modules/typed/old.js:2:12
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

**A mensagem de erro é a documentação, para variar**: dentro de um ES module não existe `require`, e
a saída para um arquivo é a extensão `.cjs`. Esse é o uso de `.cjs` e `.mjs` num projeto: um arquivo
que precisa ser do outro tipo, como um arquivo de configuração que uma ferramenta carrega com
`require`. Todo o resto segue o `type`, e **todo projeto deste curso diz `"type": "module"`** no
`package.json`.
