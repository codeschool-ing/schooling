---
title: Servindo o build do jeito que um host faz
version: 1
---

**Antes que um host sirva o seu build, sirva você mesmo, no seu computador, do jeito que um host
serviria.** A maior parte do que dá errado no primeiro deploy (um caminho errado, um arquivo faltando,
uma página que só funciona pela porta da frente) dá errado aqui também, onde você consegue ver a
requisição que falhou.

Abrir `dist/index.html` com dois cliques não conta. O navegador o carrega de um endereço `file://`, se
recusa a rodar um script de módulo vindo dali, e a página fica em branco. Um host fala HTTP, então o
teste também precisa falar.

## Dois jeitos

**`npm run preview`** roda `vite preview`, que serve `dist/` na porta 4173. É a conferência rápida, e a
própria documentação do Vite diz o que ele não é: um servidor de produção. Ele também perdoa coisas que um
host não perdoa, como mostra a aula 4.

**Um servidor que você consegue ler.** Este tem umas quarenta linhas de Node, sem nada instalado, e faz o que
todo host estático faz no fundo: transforma um caminho num arquivo, envia o arquivo com o `Content-Type`
certo e responde 404 quando não há arquivo. Salve-o na raiz do projeto:

```schooling-example
{"language": "javascript", "file": "host.mjs", "parts": [
 {"code": "// host.mjs\nimport { createServer } from \"node:http\";\nimport { readFile } from \"node:fs/promises\";\nimport { extname, join, normalize } from \"node:path\";\n\nconst root = process.argv[2] ?? \"dist\";\nconst port = Number(process.argv[3] ?? 8080);", "note": "Qual pasta servir e em qual porta, pela linha de comando: `node host.mjs dist 8080` por padrão."},
 {"code": "const types = {\n  \".html\": \"text/html; charset=utf-8\",\n  \".js\": \"text/javascript; charset=utf-8\",\n  \".css\": \"text/css; charset=utf-8\",\n  \".json\": \"application/json\",\n  \".svg\": \"image/svg+xml\",\n};", "note": "O `Content-Type` de cada terminação. Um navegador se recusa a rodar um script de módulo enviado como qualquer coisa que não seja JavaScript, então esta tabela não é enfeite."},
 {"code": "\nasync function load(path) {\n  const file = join(root, normalize(path));\n  for (const candidate of [file, join(file, \"index.html\")]) {\n    try {\n      return { body: await readFile(candidate), type: types[extname(candidate)] ?? \"application/octet-stream\" };\n    } catch {\n      // not there, or a folder: try the next candidate\n    }\n  }\n  return null;\n}", "note": "Um caminho cita um arquivo, ou uma pasta cujo `index.html` é a página. `normalize` resolve qualquer `..` do caminho antes de juntá-lo à raiz, então uma requisição não consegue escapar da pasta servida."},
 {"code": "\nconst server = createServer(async (request, response) => {\n  const path = new URL(request.url, \"http://host\").pathname;\n  const found = await load(path);\n  if (found) {\n    response.writeHead(200, { \"content-type\": found.type });\n    response.end(found.body);\n  } else {\n    const page = await load(\"/404.html\");\n    response.writeHead(404, { \"content-type\": \"text/html; charset=utf-8\" });\n    response.end(page?.body ?? \"not found\\n\");\n  }\n  console.log(response.statusCode, request.method, path);\n});", "note": "Achou: 200 e o arquivo. Não achou: 404, com o `404.html` do próprio site se houver um, que é a convenção que os quatro hosts desta aula seguem. Cada requisição é registrada com o seu status."},
 {"code": "\nserver.listen(port, \"127.0.0.1\", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));", "note": "Só este computador alcança `127.0.0.1`."}
]}
```

Construa e inicie o servidor num terminal:

```
ana@dev:~/planner$ node host.mjs
serving dist on http://127.0.0.1:8080
```

Peça a página, os dados e um arquivo que não existe, a partir de um segundo:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:8080/ | head -3
HTTP/1.1 200 OK
content-type: text/html; charset=utf-8
Date: Fri, 23 Oct 2026 22:17:01 GMT
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/courses.json | head -2
{
  "courses": [
ana@dev:~/planner$ curl -si http://127.0.0.1:8080/nothing-here
HTTP/1.1 404 Not Found
content-type: text/html; charset=utf-8
Date: Fri, 23 Oct 2026 22:17:01 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

not found
```

De volta ao primeiro terminal, o servidor registrou cada requisição:

```
ana@dev:~/planner$ node host.mjs
serving dist on http://127.0.0.1:8080
200 GET /
200 GET /courses.json
404 GET /nothing-here
^C
```

Abra `http://127.0.0.1:8080/` no navegador e o planner funciona como funcionava com `npm run dev`, só
que agora nada está sendo compilado: estes são os quatro arquivos que um host guardaria. O registro
mostra o navegador pedindo a página, depois o script e a folha de estilo que a página cita, depois o
`courses.json` quando o script roda.

## O que um host de verdade acrescenta

Tudo neste servidor é algo que os quatro hosts fazem. O que eles acrescentam por cima é aquilo por que
você paga, ou o que o plano gratuito dá de presente:

- **muitas cópias**: os arquivos em servidores de muitas cidades, e cada requisição respondida pelo mais
  próximo;
- **HTTPS**, com um certificado que eles obtêm e renovam por você, aula 4;
- **compressão**, para que `index-BVi82VJx.js` viaje no tamanho em gzip;
- **cabeçalhos de cache**, para que um navegador guarde os arquivos com hash, aula 9 de front-performance;
- **regras**: redirecionamentos, reescritas e cabeçalhos, lidos de um arquivo no seu repositório, aula 4;
- **um build**, a partir do seu repositório, a cada push, aula 3.

O objetivo deste servidor não é competir com nada disso. É que cada um desses itens é uma **regra sobre a
mesma pasta**, e agora você tem a pasta e um servidor cujo comportamento dá para ler linha a linha quando
uma dessas regras surpreender você.

Faça o commit, para as próximas aulas poderem aumentá-lo:

```
ana@dev:~/planner$ git add host.mjs
ana@dev:~/planner$ git commit -qm "Serve dist/ the way a static host does"
```
