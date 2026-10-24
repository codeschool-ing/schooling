---
title: Pré-renderizando o planner à mão
version: 1
---

**O `server.ts` da aula 1 desenhava uma página quando alguém pedia. Uma pré-renderização desenha
todas antes e salva cada uma no endereço a que pertence.** O código é quase o mesmo, porque o
trabalho é o mesmo: ler o plano, chamar `page`, pôr o resultado na casca que o build escreveu. Só o
momento muda.

## O script

Salve isto como `prerender.ts`, ao lado do `server.ts`. Ele roda depois do `vite build` e acrescenta
ao `dist/` uma página para cada endereço:

```schooling-example
{"language": "typescript", "file": "prerender.ts", "parts": [
 {"code": "// prerender.ts: draw every page of the planner once, at build time, as files in dist/.\nimport { mkdir, readFile, writeFile } from \"node:fs/promises\";\nimport { join } from \"node:path\";\nimport type { Plan } from \"./src/planner.ts\";\nimport { page } from \"./src/view.ts\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst shell = await readFile(join(dist, \"index.html\"), \"utf8\");\nconst plan: Plan = JSON.parse(await readFile(join(dist, \"courses.json\"), \"utf8\"));\nconst draw = (path: string) =>\n  shell.replace('<main id=\"app\"></main>', `<main id=\"app\">${page(plan, path)}</main>`);", "note": "Os mesmos imports do server.ts, e a mesma casca: o index.html que o vite build escreveu, com o seu main vazio."},
 {"code": "for (const path of [\"/\", ...plan.courses.map((c) => `/courses/${c.slug}`)]) {\n  await mkdir(join(dist, path), { recursive: true });\n  await writeFile(join(dist, path, \"index.html\"), draw(path));\n  console.log(`${path} -> dist${path === \"/\" ? \"\" : path}/index.html`);\n}", "note": "A lista de endereços vem dos dados, como o generateStaticParams fazia no Next.js. Cada página é escrita como index.html numa pasta com o nome do seu endereço, que é como uma hospedagem estática acha /courses/git."},
 {"code": "await writeFile(join(dist, \"404.html\"), draw(\"/courses/-\"));\nconsole.log(\"anything else -> dist/404.html\");", "note": "E uma página para todo endereço que não é curso. \"/courses/-\" é um slug que nenhum curso tem, então page desenha o seu \"No such course\"."}
]}
```

**Ele sobrescreve o `dist/index.html` com a página inicial**, então tem de rodar num build novo, nunca
duas vezes no mesmo: a segunda vez não acharia um `<main>` vazio para preencher. Um script no
`package.json` faz dos dois um comando só:

```
ana@dev:~/planner$ npm pkg set scripts.build:static="npm run build && node prerender.ts"
ana@dev:~/planner$ npm run build:static 2>&1 | tail -6
✓ built in 137ms
/ -> dist/index.html
/courses/html-css -> dist/courses/html-css/index.html
/courses/javascript -> dist/courses/javascript/index.html
/courses/git -> dist/courses/git/index.html
anything else -> dist/404.html
ana@dev:~/planner$ find dist -name '*.html' | sort
dist/404.html
dist/courses/git/index.html
dist/courses/html-css/index.html
dist/courses/javascript/index.html
dist/index.html
```

Cinco arquivos, cada um uma página pronta. `npm run build` sozinho ainda faz a casca vazia de que o
`server.ts` precisa; os dois builds produzem pastas `dist/` diferentes, e a que você rodou por último
é a que você tem.

## Uma hospedagem estática, em trinta linhas

O `vite preview` é a coisa errada para testar isto: ele foi feito para um app que desenha toda
página no navegador, então responde a qualquer endereço que não conhece com o `dist/index.html`. Uma
hospedagem estática faz três coisas no lugar, e o `static.ts` faz exatamente essas três. Salve ao
lado dos outros:

```schooling-example
{"language": "typescript", "file": "static.ts", "parts": [
 {"code": "// static.ts: serve dist/ the way a static host does: a file as it is, a folder's\n// index.html for the folder's address, and 404.html, with a 404, for anything else.\nimport { createServer } from \"node:http\";\nimport { readFile, stat } from \"node:fs/promises\";\nimport { extname, join } from \"node:path\";\n\nconst dist = join(import.meta.dirname, \"dist\");\nconst types: Record<string, string> = {\n  \".html\": \"text/html; charset=utf-8\", \".js\": \"text/javascript\", \".css\": \"text/css\",\n  \".json\": \"application/json\", \".svg\": \"image/svg+xml\",\n};", "note": "Renderização nenhuma: toda resposta é um arquivo que já está em dist/."},
 {"code": "async function find(path: string): Promise<string | null> {\n  for (const candidate of [path, join(path, \"index.html\")]) {\n    try {\n      if ((await stat(candidate)).isFile()) return candidate;\n    } catch {\n      // nothing at this path; the next candidate, or null, says so\n    }\n  }\n  return null;\n}", "note": "Um endereço é tentado como arquivo e depois como pasta com index.html. O stat lança um erro para um caminho que não existe, e essa é a resposta \"não é este\", então o laço segue."},
 {"code": "createServer(async (req, res) => {\n  const { pathname } = new URL(req.url ?? \"/\", \"http://localhost\");\n  const found = await find(join(dist, pathname));\n  const path = found ?? join(dist, \"404.html\");\n  res.writeHead(found ? 200 : 404, { \"content-type\": types[extname(path)] ?? \"application/octet-stream\" });\n  res.end(await readFile(path));\n}).listen(8080, () => console.log(\"dist/ on http://localhost:8080\"));", "note": "Nada encontrado é um 404 com a página 404 do próprio site, que é o que o GitHub Pages, o Netlify e o Cloudflare Pages fazem com um 404.html na raiz."}
]}
```

Faça o build e ligue-o no segundo terminal:

```sh
npm run build:static && node static.ts
```

No primeiro terminal, peça um curso, um endereço que não existe, e a página inicial com o JavaScript
desligado:

```
ana@dev:~/planner$ curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/courses/nonsense
404
ana@dev:~/planner$ curl -s http://localhost:8080/courses/nonsense | grep -o '<h1>[^<]*</h1>'
<h1>No such course</h1>
ana@dev:~/planner$ node tools/look.ts http://localhost:8080/ --no-js | head -3
requests: / /assets/index-1yLCgpWc.css
first contentful paint: 32 ms
text on the screen:
```

**A página do curso é um arquivo, e diz exatamente o que o `server.ts` desenhava**, com JavaScript ou
sem. O curso desconhecido recebe a página do próprio site e um 404 de verdade, que o `server.ts`
nunca mandou. E o servidor que respondeu não faz ideia do que seja um curso: ele poderia ser
qualquer hospedagem estática da internet. A aula 9 volta a este servidor e ensina a ele os
cabeçalhos de cache que uma hospedagem acrescentaria.
