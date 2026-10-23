---
title: Padrões de caminho no Express 5
version: 1
---

**Um caminho de rota é um padrão, e o Express 5 entende quatro coisas nele**: texto comum, um
parâmetro com nome `:nome`, uma parte opcional entre chaves `{…}`, e um curinga `*nome` que casa com o
resto do caminho. Essa é a linguagem inteira, e ela é menor que a do Express 4 de propósito.

```javascript
// demo/patterns.js
import express from "express";

const app = express();

app.get("/links/:code", (req, res) => res.json(req.params));
app.get("/stats{/:period}", (req, res) => res.json(req.params));
app.get("/files/*path", (req, res) => res.json(req.params));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/stats
{}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/stats/week
{"period":"week"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/files/2026/october/report.txt
{"path":["2026","october","report.txt"]}
```

- **O `:code`** casa com um segmento, até a próxima `/`, e chega como string.
- **O `{/:period}`** torna a barra e o parâmetro opcionais juntos: `/stats` e `/stats/week` casam os
  dois, e no primeiro o `period` simplesmente não existe.
- **O `*path`** casa com um ou mais segmentos, e chega como um **array** deles: `["2026", "october",
  "report.txt"]`. Juntá-los de volta é escolha sua, e também conferir que nenhum deles seja `..`, o
  que a seção da aula 8 sobre caminhos explica.

## O que mudou desde o Express 4

Tutoriais escritos para o Express 4 usam padrões que a versão 5 recusa, e a recusa vem na
inicialização:

```javascript
// demo/old-pattern.js
import express from "express";

const app = express();
app.get("*", (req, res) => res.send("everything\n"));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ node demo/old-pattern.js 2>&1 | grep TypeError
PathError [TypeError]: Missing parameter name at index 1: *; visit https://git.new/pathToRegexpError for info
```

**Um curinga agora precisa de nome**, `*rest` ou `*path`, e um `*` sozinho é um erro com um endereço
que o explica. Outras três formas da versão 4 foram pelo mesmo caminho: `:id?` virou `{/:id}`, uma
expressão regular escrita dentro da string sumiu, e caracteres como `(`, `)` e `+` não significam
mais nada especial. O motivo foi tanto segurança quanto arrumação: os padrões antigos viravam
expressões regulares que podiam levar tempo exponencial em certos caminhos, o que a auditoria da aula
4 mostrou como um alerta contra o `path-to-regexp`. **A linguagem nova não consegue expressar um
padrão que retrocede.**

Uma rota que precisa de mais que essas quatro coisas — "um código tem seis caracteres deste
alfabeto" — diz isso no handler, não no padrão. A seção da aula 7 sobre parâmetros faz exatamente
isso.
