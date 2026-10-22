---
title: Escrevendo um arquivo que sobrevive a uma queda
version: 1
---

**O `writeFile` não é um passo só.** Ele trunca o arquivo, depois escreve os bytes novos, e um processo
morto entre os dois — um deploy, uma queda, falta de energia — deixa o arquivo escrito pela metade.
Para um store, isso são todos os links perdidos de uma vez, porque meio documento JSON não é JSON.

Este programa escreve um array grande num arquivo, e é morto no meio, como uma queda o mataria:

```javascript
// torn.js
import { writeFile } from "node:fs/promises";

const links = Array.from({ length: 200_000 }, (_, i) => ({ code: `c${i}`, url: `https://example.com/${i}` }));
await writeFile("store.json", JSON.stringify([{ code: "first", url: "https://example.com/" }]));
console.log("a good store.json is on disk");
setTimeout(() => process.kill(process.pid, "SIGKILL"), 15);
await writeFile("store.json", JSON.stringify(links));
console.log("never printed");
```

```
ana@dev:~/server/files$ node torn.js; ls -l store.json; node -e 'JSON.parse(require("fs").readFileSync("store.json", "utf8"))' 2>&1 | grep -E '^SyntaxError'
a good store.json is on disk
bash: line 3:  4596 Killed                  node torn.js
-rw-r--r-- 1 ana ana 0 Oct 22 19:16 store.json
SyntaxError: Unexpected end of JSON input
```

O `writeFile` já tinha esvaziado o arquivo bom, e os bytes novos não tinham chegado: zero bytes, que
não são JSON. Com um instante de diferença no tempo, seria metade do array novo, que também não é.
**Os dados antigos e os novos sumiram juntos.**

## Escreva ao lado, depois renomeie

A solução é um rename, que no mesmo disco é um passo único que o sistema operacional faz por inteiro
ou não faz: **escreva o conteúdo novo num arquivo temporário ao lado do de verdade, depois renomeie-o
por cima do de verdade.** Uma queda antes do rename deixa o arquivo antigo inteiro; uma queda depois
deixa o novo inteiro. Não existe momento em que o `links.json` tenha metade de nada.

O store do serviço links guarda os links em `data/links.json` desse jeito daqui em diante, que é a
mudança para a qual a aula 6 tornou toda função `async`:

```schooling-example
{"language": "javascript", "file": "src/store.js", "parts": [
 {"code": "// src/store.js: where the links live, in a JSON file written so that a crash cannot tear it.\nimport { mkdir, readFile, rename, writeFile } from \"node:fs/promises\";\nimport path from \"node:path\";\nimport { makeCode } from \"./code.js\";\n\nconst file = path.join(import.meta.dirname, \"..\", \"data\", \"links.json\");", "note": "**O arquivo mora ao lado do código**, em `data/`, montado a partir do `import.meta.dirname` como a aula 3 disse. A aula 9 deixa o ambiente escolhê-lo."},
 {"code": "let links = null;\nasync function load() {\n  if (links) return links;\n  try {\n    links = new Map(JSON.parse(await readFile(file, \"utf8\")).map((l) => [l.code, l]));\n  } catch (err) {\n    if (err.code !== \"ENOENT\") throw err;\n    links = new Map();\n  }\n  return links;\n}", "note": "Carregado uma vez, na primeira vez que algo pede. Um arquivo ausente é um store vazio; qualquer outro erro para o serviço, como a seção anterior disse que deve."},
 {"code": "let saving = Promise.resolve();\nfunction save() {\n  const run = saving.catch(() => {}).then(async () => {\n    await mkdir(path.dirname(file), { recursive: true });\n    const temp = `${file}.${process.pid}.tmp`;\n    await writeFile(temp, JSON.stringify([...links.values()], null, 2) + \"\\n\");\n    await rename(temp, file);\n  });\n  saving = run;\n  return run;\n}", "note": "**Cada save espera o anterior.** Duas requisições mudando links ao mesmo tempo escreveriam dois arquivos temporários e os renomeariam em qualquer ordem, e o mais velho poderia vencer. Um save que falhou é informado a quem o chamou e não impede o próximo."},
 {"code": "export async function add(url) {\n  await load();\n  let code;\n  do code = makeCode();\n  while (links.has(code));\n  const link = { code, url, visits: 0, created: new Date().toISOString() };\n  links.set(code, link);\n  await save();\n  return link;\n}\n\nexport async function find(code) {\n  return (await load()).get(code);\n}\n\nexport async function all() {\n  return [...(await load()).values()];\n}\n\nexport async function remove(code) {\n  const gone = (await load()).delete(code);\n  if (gone) await save();\n  return gone;\n}\n\nexport async function visit(code) {\n  const link = (await load()).get(code);\n  if (link) {\n    link.visits++;\n    await save();\n  }\n  return link;\n}", "note": "As cinco funções que as rotas da aula 6 chamam, com os mesmos nomes e as mesmas respostas. Toda função que muda um link salva antes de retornar, então um 201 quer dizer que o link está no disco."}
]}
```

O `data/` guarda os dados do serviço, então ele se junta ao `node_modules/` no `.gitignore`. Agora os
links sobrevivem a um reinício:

```
ana@dev:~/server/links$ curl -s -o /dev/null -w '%{http_code}\n' -H 'content-type: application/json' -d '{"url": "https://nodejs.org/"}' http://127.0.0.1:3000/links
201
ana@dev:~/server/links$ cat data/links.json
[
  {
    "code": "jsfgve",
    "url": "https://nodejs.org/",
    "visits": 0,
    "created": "2026-10-22T22:17:00.026Z"
  }
]
ana@dev:~/server/links$ cat .gitignore
node_modules/
data/
```

e com o servidor parado e iniciado de novo, o link continua lá:

```
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[{"code":"jsfgve","url":"https://nodejs.org/","visits":0,"created":"2026-10-22T22:17:00.026Z"}]
```

**Um arquivo para o store inteiro está certo para alguns milhares de links e errado para milhões**:
toda mudança reescreve todos eles. Um banco de dados é a resposta nesse tamanho, e o curso
`sql-databases`, o próximo desta trilha, é onde o store vai para um. As rotas também não vão notar
essa mudança.
