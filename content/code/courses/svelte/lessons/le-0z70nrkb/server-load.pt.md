---
title: Uma função load de servidor, para o que o servidor possui
version: 1
---

**O arquivo de dados está em `static`, e tudo em `static` é servido a quem pedir.** Isso era aceitável
enquanto o planner só lia o arquivo. A aula 14 faz o planner gravar sessões de volta, e um arquivo em
que o servidor escreve não é um para entregar pelo seu endereço. Também não é onde os dados moram numa
aplicação com mais de um usuário: lá é um banco de dados, que o navegador não alcança de jeito nenhum.
De um jeito ou de outro, a leitura tem de acontecer no servidor, em código que nunca vai para o
navegador.

Mova o arquivo para fora de `static`, para uma pasta própria no topo do projeto. O `git mv` o move e
avisa o Git de que ele foi movido:

```
ana@dev:~/planner$ mkdir data src/lib/server
ana@dev:~/planner$ git mv static/planner.json data/planner.json
```

`src/lib/server` é uma pasta que o SvelteKit trata de modo especial, como a próxima parte mostra. Salve
ali o código que lê o arquivo, como `src/lib/server/planner.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/server/planner.js", "parts": [
 {"code": "// planner.js: the planner's data, read from the file the server keeps it in.\nimport { readFile } from 'node:fs/promises';"},
 {"code": "const FILE = 'data/planner.json';", "note": "Um caminho relativo é tomado a partir da pasta em que o servidor foi iniciado: o projeto, no caso do `npm run dev`."},
 {"code": "export async function readPlanner() {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}", "note": "`node:fs/promises` é o módulo de sistema de arquivos do próprio Node. Ele não existe num navegador."}
]}
```

## A mudança óbvia, e por que ela falha

A mudança óbvia é chamá-lo da função load que já existe. Substitua o
`src/routes/(planner)/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.js", "parts": [
 {"code": "// +layout.js: the data every page of the planner needs. (This is the wrong file for it.)\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "`#lib/server/planner.js` é o módulo de cima. Este arquivo roda no navegador também, e esse é o problema."}
]}
```

O servidor fica contente com ela:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

e o navegador não:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
title: 225 min this week · Study planner
- text: "server_only_import Cannot import `#lib/server/planner.js` into code that runs in the browser, as this could leak sensitive information. src/routes/(planner)/+layout.js imports #lib/server/planner.js If you're only using the import as a type, change it to `import type`. https://svelte.dev/e/kit/server_only_import Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.js
- text: .
```

**O título diz que o servidor renderizou a semana; a página embaixo é a tela de erro do Vite.** Um
`+layout.js` é universal, então, depois de renderizar no servidor, o SvelteKit o manda para o navegador
rodar de novo, junto com tudo o que ele importa. Um desses imports lê um arquivo com o sistema de
arquivos do Node, que o navegador não tem. O SvelteKit o barra antes de chegar a esse ponto: um módulo
em `src/lib/server`, ou um com nome `*.server.js`, só pode ser importado por código que fica no
servidor, e o `server_only_import` nomeia o arquivo que quebrou a regra. A regra existe pelo caso que
importa, um módulo guardando a senha de um banco ou uma chave de API, que seria, de outro modo, enviado
a cada visitante para ler.

## `+layout.server.js`

**Uma função load num arquivo cujo nome termina em `.server.js` roda no servidor e em nenhum outro
lugar.** O navegador nunca recebe o código dela; ele pede o resultado ao servidor. Renomear o arquivo é
a correção inteira:

```
ana@dev:~/planner$ mv 'src/routes/(planner)/+layout.js' 'src/routes/(planner)/+layout.server.js'
```

Troque o comentário da primeira linha, já que ele agora é o arquivo certo para o trabalho:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "O mesmo código do `+layout.js` que ele substitui. Só o nome do arquivo é diferente, e com ele o lugar onde o código roda."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ | head -4
at /
title: 225 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
```

A semana voltou. O arquivo de onde ela veio não é mais alcançável:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/planner.json
404
```

O componente de layout não mudou. O `data` é a mesma prop com os mesmos cursos e sessões dentro, e o
layout não tem como saber se foi uma função load universal ou de servidor que o produziu.
