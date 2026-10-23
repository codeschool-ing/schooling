---
title: Argumentos da linha de comando
version: 1
---

**Um servidor lê o ambiente; uma ferramenta que alguém roda à mão lê a linha de comando.** O
`process.argv` é a lista de palavras digitadas, começando pelo caminho do `node` e o do script, e o
`util.parseArgs` do `node:util` transforma o resto em opções com nome, sem pacote nenhum.

Uma ferramenta pequena para quem cuida do serviço links conta os links de um arquivo de dados:

```schooling-example
{"language": "javascript", "file": "count.js", "parts": [
 {"code": "// count.js: how many links a data file holds, and how many visits they had.\nimport { readFile } from \"node:fs/promises\";\nimport { parseArgs } from \"node:util\";\n\nconst { values } = parseArgs({\n  options: {\n    file: { type: \"string\", short: \"f\", default: process.env.DATA_FILE ?? \"data/links.json\" },\n    min: { type: \"string\", default: \"0\" },\n    help: { type: \"boolean\", short: \"h\" },\n  },\n  strict: true,\n});", "note": "**Declare as opções**: os tipos, as letras curtas e os padrões. O `strict` faz de uma opção desconhecida um erro, em vez de algo ignorado em silêncio."},
 {"code": "if (values.help) {\n  console.log(\"usage: node count.js [--file FILE] [--min VISITS]\");\n  process.exit(0);\n}", "note": "O `--help` responde e para, como toda ferramenta deve fazer."},
 {"code": "const links = JSON.parse(await readFile(values.file, \"utf8\"));\nconst min = Number(values.min);\nconst chosen = links.filter((l) => l.visits >= min);\nconsole.log(`${chosen.length} of ${links.length} links with at least ${min} visits in ${values.file}`);", "note": "**As flags vencem o ambiente, que vence o padrão**: o `--file` se foi dado, senão a `DATA_FILE`, senão `data/links.json`."}
]}
```

```
ana@dev:~/server/links$ node count.js --help
usage: node count.js [--file FILE] [--min VISITS]
ana@dev:~/server/links$ node count.js
3 of 3 links with at least 0 visits in data/links.json
ana@dev:~/server/links$ node count.js --min 1
1 of 3 links with at least 1 visits in data/links.json
ana@dev:~/server/links$ node count.js --file test/tmp/links.json
3 of 3 links with at least 0 visits in test/tmp/links.json
ana@dev:~/server/links$ node count.js --minimum 1 2>&1 | grep TypeError
TypeError [ERR_PARSE_ARGS_UNKNOWN_OPTION]: Unknown option '--minimum'
```

**Uma opção que não existe é recusada pelo nome**, o que uma ferramenta que só varresse o
`process.argv` à mão teria ignorado, rodando com padrões que a pessoa não escolheu. A ordem de
precedência (flag, depois ambiente, depois padrão) é a de costume nas ferramentas, e é a mesma que o
`--env-file` segue: decide quem está mais perto do comando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Quatro lugares de onde uma configuração pode vir, do mais longe ao mais perto do comando: o padrão no código, um arquivo .env, o ambiente de verdade, e uma flag na linha de comando. Cada um mais perto do comando sobrepõe os anteriores.\"><rect x=\"20\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o padrão no código</text><text x=\"100\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">?? \"data/links.json\"</text><line x1=\"180\" y1=\"90\" x2=\"190\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,90.0 182.6,93.1 182.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"192\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um arquivo .env</text><text x=\"272\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--env-file=.env</text><line x1=\"352\" y1=\"90\" x2=\"362\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"362.0,90.0 354.6,93.1 354.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"364\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o ambiente de verdade</text><text x=\"444\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DATA_FILE=… node</text><line x1=\"524\" y1=\"90\" x2=\"534\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"534.0,90.0 526.6,93.1 526.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"536\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma flag na linha de comando</text><text x=\"616\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--file …</text><line x1=\"20\" y1=\"160\" x2=\"700\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,160.0 692.6,163.1 692.6,156.9\" fill=\"var(--amber)\"></polygon><text x=\"700\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mais perto do comando: vence</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais longe: só vale se nada mais disser</text></svg>", "caption": "Quem está mais perto do comando decide; um padrão é só o último recurso."}
```
