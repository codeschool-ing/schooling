---
title: Rotas e roteadores
version: 1
---

**Uma rota é um método, um padrão de caminho e um handler, e o Express as tenta na ordem em que
foram acrescentadas.** A primeira cujo método e padrão casam com a requisição roda. Três ferramentas
as organizam:

```schooling-example
{"language": "javascript", "file": "demo/routes.js", "parts": [
 {"code": "import express from \"express\";\n\nconst app = express();\n\napp\n  .route(\"/links\")\n  .get((req, res) => res.send(\"the list of links\\n\"))\n  .post((req, res) => res.send(\"a new link\\n\"));", "note": "**Um caminho, vários métodos**: o `app.route` nomeia o caminho uma vez. Um método que falte aqui é o 405 que a aula 5 escrevia e o Express não; a seção sobre rotas que não casam volta a isso."},
 {"code": "const admin = express.Router();\nadmin.get(\"/\", (req, res) => res.send(\"the admin page\\n\"));\nadmin.get(\"/stats\", (req, res) => res.send(\"the numbers\\n\"));\napp.use(\"/admin\", admin);", "note": "**Um `Router` é uma pequena aplicação própria**, com rotas escritas em relação ao lugar onde ele for montado. Aqui, o `/` dentro dele é o `/admin/` fora."},
 {"code": "app.get(\"/links/new\", (req, res) => res.send(\"a form for a new link\\n\"));\napp.get(\"/links/:code\", (req, res) => res.send(`the link ${req.params.code}\\n`));\n\napp.listen(3000, \"127.0.0.1\");", "note": "**A ordem decide entre dois padrões que casam ao mesmo tempo.** O `/links/new` é um caminho fixo, escrito primeiro para que o `:code` não o pegue."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
the list of links

ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
a new link

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/
the list of links

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/ADMIN/stats
the numbers

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/new
a form for a new link

ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
the link 7ctxqn
```

Três coisas nessas respostas são padrões do Express, e cada uma é uma decisão que alguém tomou por
você:

- **Uma barra no fim não importa**: o `/links/` chegou à rota `/links`. O roteador da aula 5 tratava
  os dois como caminhos diferentes.
- **Maiúsculas não importam**: o `/ADMIN/stats` chegou ao `/admin/stats`. Os dois padrões podem ser
  mudados com `express.Router({ strict: true, caseSensitive: true })`, e quase ninguém muda.
- **O `/links/new` não virou código**, porque foi acrescentado primeiro. Troque as duas linhas e o
  `new` vira um link para o qual ninguém consegue abrir um formulário. Uma lista de rotas é lida de
  cima para baixo como um programa, e um padrão amplo acima de um estreito o esconde.

Um roteador é como um serviço maior é dividido por funcionalidade, a segunda organização da aula 3:
o `users.js` exporta um roteador, o `billing.js` outro, e o `app.js` monta cada um sob o seu
prefixo. O serviço links tem um, e a última seção desta aula o escreve.
