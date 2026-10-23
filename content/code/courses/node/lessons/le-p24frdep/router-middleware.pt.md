---
title: Middleware para uma parte da aplicação
version: 1
---

**Um middleware pode ser ligado a um roteador ou a uma rota em vez da aplicação inteira**, e é assim
que uma regra que vale para alguns caminhos fica longe dos outros. O exemplo comum é conferir se quem
chama tem permissão para fazer algo. No serviço links, qualquer um pode criar um link e segui-lo, e só
quem roda o serviço pode listar todos ou apagar um.

```schooling-example
{"language": "javascript", "file": "demo/admin.js", "parts": [
 {"code": "import express from \"express\";\nimport { timingSafeEqual } from \"node:crypto\";\n\nconst ADMIN_KEY = \"change-me-in-lesson-9\"; // lesson 9 moves it to the environment\n\nfunction requireKey(req, res, next) {\n  const given = Buffer.from(req.get(\"x-admin-key\") ?? \"\");\n  const wanted = Buffer.from(ADMIN_KEY);\n  if (given.length !== wanted.length || !timingSafeEqual(given, wanted)) {\n    return res.status(401).json({ error: \"this needs the admin key\" });\n  }\n  next();\n}", "note": "**A chave é comparada em tempo constante.** O `===` para no primeiro caractere diferente, então o tempo de uma comparação diz quanto de um palpite estava certo; o `timingSafeEqual` leva o mesmo tempo seja qual for a entrada, desde que os tamanhos batam, o que é conferido antes."},
 {"code": "const app = express();\napp.get(\"/links\", requireKey, (req, res) => res.json([]));\napp.post(\"/links\", (req, res) => res.status(201).json({ code: \"7ctxqn\" }));", "note": "**Numa rota**, o middleware é um argumento antes do handler. O Express os roda da esquerda para a direita, e o handler só se o `requireKey` chamou `next()`."},
 {"code": "const admin = express.Router();\nadmin.use(requireKey);\nadmin.get(\"/stats\", (req, res) => res.json({ links: 0 }));\napp.use(\"/admin\", admin);\n\napp.listen(3000, \"127.0.0.1\");", "note": "**Num roteador inteiro**, o `router.use` o põe na frente de tudo o que estiver montado nele."}
]}
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'x-admin-key: guess' http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H 'X-Admin-Key: change-me-in-lesson-9' http://127.0.0.1:3000/links
[]
ana@dev:~/server/links$ curl -s -X POST http://127.0.0.1:3000/links
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/admin/stats
{"error":"this needs the admin key"}
```

O `req.get` lê um cabeçalho em qualquer combinação de maiúsculas, o auxiliar para o `req.headers[…]`
da aula 5. **O 401 quer dizer "quem é você?"**: a requisição não tinha credenciais, ou tinha erradas.
O irmão dele, o 403, quer dizer "sei quem você é, e não", que este serviço ainda não usa.

Uma chave no código-fonte é uma chave em toda cópia do repositório, e o comentário diz isso de
propósito. A aula 9 a lê do ambiente, e a mantém fora do git. Uma chave compartilhada também é o
esquema mais simples possível, certo para um operador e alguns scripts; um serviço com usuários faz
cada um entrar, o que o curso `apis` cobre.
