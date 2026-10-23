---
title: Renderização no servidor, à mão
version: 1
---

**Renderizar no servidor quer dizer que o servidor roda o mesmo código de view antes de responder,
e manda a página pronta.** Os frameworks da aula 2 fazem isso com muita maquinaria, e é fácil sair
achando que a maquinaria é a ideia. Não é. A ideia cabe num arquivo pequeno, porque o
`src/view.ts` já transforma um plano em HTML sem tocar na página.

## O servidor

Salve isto como `server.ts` ao lado do `package.json`. Ele serve os arquivos que o build escreveu,
e para qualquer endereço que não seja um arquivo ele lê o plano, chama `page` do `src/view.ts` e
põe o resultado dentro do `<main>` da página que o build escreveu:

```schooling-example
{"language": "typescript", "file": "server.ts", "parts": [
 {"code": "// server.ts: the same planner, with each page drawn here before it is sent.\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\nimport { page } from \"./src/view.ts\";", "note": "O servidor importa o próprio código do planner. O Node 22 tira os tipos dos dois arquivos enquanto os carrega."},
 {"code": "const dist = join(import.meta.dirname, \"dist\");\nconst types: Record<string, string> = {\n  \".js\": \"text/javascript\", \".css\": \"text/css\", \".json\": \"application/json\", \".svg\": \"image/svg+xml\",\n};\nconst shell = await readFile(join(dist, \"index.html\"), \"utf8\");", "note": "A casca é o dist/index.html, lido uma vez na partida. Ele já nomeia o script e a folha de estilo com hash, então o servidor nunca precisa saber os nomes deles."},
 {"code": "createServer(async (req, res) => {\n  const { pathname } = new URL(req.url ?? \"/\", \"http://localhost\");\n  if (extname(pathname)) {\n    // A file the build wrote: a script, a stylesheet, the data.\n    try {\n      const body = await readFile(join(dist, pathname));\n      res.writeHead(200, { \"content-type\": types[extname(pathname)] ?? \"application/octet-stream\" });\n      res.end(body);\n    } catch {\n      res.writeHead(404).end();\n    }\n    return;\n  }", "note": "Um endereço com extensão é um arquivo do build. O new URL já resolveu qualquer ../ do caminho, então o join fica dentro de dist."},
 {"code": "  // A page: read the plan and draw it into the shell the build wrote.\n  const plan: Plan = JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));\n  const html = shell.replace('<main id=\"app\"></main>', `<main id=\"app\">${page(plan, pathname)}</main>`);\n  res.writeHead(200, { \"content-type\": \"text/html; charset=utf-8\" });\n  res.end(html);\n}).listen(3000, () => console.log(\"planner on http://localhost:3000\"));", "note": "Qualquer outra coisa é uma página. O plano é lido a cada requisição, então uma edição nos dados aparece na próxima. O main vazio é trocado pela página que o endereço nomeia."}
]}
```

São umas trinta linhas e não fazem nada que a metade do navegador também não faça. Essa igualdade é
o ponto: **uma função `page`, chamada em dois lugares**, e assim o HTML do servidor e o HTML do
navegador não têm como discordar. A aula 4 mostra o que acontece quando discordam.

## Rodando

Pare o servidor de preview, faça o build de novo para o `dist/` ficar atualizado e ligue este no
segundo terminal:

```
ana@dev:~/planner$ npm run build >/dev/null && node server.ts
planner on http://localhost:3000
```

No primeiro terminal, peça a página de um curso:

```
ana@dev:~/planner$ curl -s http://localhost:3000/courses/git
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-Dv4jVJdV.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-1yLCgpWc.css">
  </head>
  <body>
    <main id="app"><p><a href="/">All courses</a></p>
<h1>Git</h1>
<ul class="sessions"><li>2026-10-24 · 25 min <button data-done="5">Mark done</button></li><li>2026-10-27 · 40 min <button data-done="6">Mark done</button></li></ul>
<form>
  <label>Date <input name="date" type="date" required></label>
  <label>Minutes <input name="minutes" type="number" min="5" step="5" required></label>
  <button>Add session</button>
</form></main>
  </body>
</html>
```

**As sessões estão na primeira resposta.** Os mesmos dois links e a mesma tag de script estão lá
como antes, mas o `<main>` agora tem o título, as duas sessões do curso de Git com os seus botões,
e o formulário. E o navegador, com e sem JavaScript:

```
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/ --no-js
requests: / /assets/index-1yLCgpWc.css
first contentful paint: 44 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 36 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

Sem JavaScript o navegador buscou duas coisas, pintou, e a página diz exatamente o mesmo que com
JavaScript. **O que ele não consegue fazer sem JavaScript é todo o resto**: um clique em
*Mark done* não roda código nenhum, e o *Add session* do formulário mandaria o formulário ao
servidor, que não tem tratador para ele. Com JavaScript, o script ainda roda, busca o
`/courses.json` e desenha a página de novo, por cima da que o servidor mandou.

Esse redesenho é desperdício, e é pior que desperdício num celular lento, onde a página está
visível e não faz nada enquanto o script não chega. A aula 4 o troca pela **hidratação**: o script
prende os seus listeners ao HTML que já está lá, em vez de jogá-lo fora. Para esta aula o
redesenho serve, porque o HTML que ele desenha é idêntico.

## O que o servidor agora faz e antes não fazia

Cada requisição de página lê um arquivo, faz o parse e monta uma string. Para três cursos isso não
é nada; as próximas seções medem mesmo assim. Num site real é uma consulta ao banco e um template,
para cada visitante, em cada página que ele abre, e o servidor precisa de um programa rodando e de
processador suficiente para isso. Um site renderizado no cliente só precisava de alguém que
entregasse arquivos.
