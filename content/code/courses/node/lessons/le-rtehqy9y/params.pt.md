---
title: Parâmetros de rota, conferidos uma vez
version: 1
---

**Um parâmetro de rota é texto que o cliente escolheu**, e as rotas da aula 6 entregavam o
`req.params.code` direto ao store. Isso funcionava porque o store só procura, e um código que não
existe simplesmente não é encontrado. Para de funcionar no dia em que um parâmetro for usado para
qualquer outra coisa — um nome de arquivo, uma consulta ao banco, uma linha de log — então vale ter o
hábito desde a primeira rota.

O serviço links já sabe o que é um código: o `isCode` da aula 4, seis caracteres do alfabeto. O
Express consegue rodar uma conferência sempre que uma rota com determinado parâmetro casa, com o
`router.param`:

```javascript
// demo/param.js
import express from "express";
import { isCode } from "../src/code.js";

const links = express.Router();

links.param("code", (req, res, next, code) => {
  if (!isCode(code)) return res.status(400).json({ error: `${JSON.stringify(code)} is not a link code` });
  next();
});

links.get("/:code", (req, res) => res.json({ code: req.params.code }));
links.delete("/:code", (req, res) => res.status(204).end());

const app = express();
app.use("/links", links);
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxq1
{"error":"\"7ctxq1\" is not a link code"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqnabc
{"error":"\"7ctxqnabc\" is not a link code"}
ana@dev:~/server/links$ curl -s -X DELETE http://127.0.0.1:3000/links/a%20b
{"error":"\"a b\" is not a link code"}
```

**A conferência é escrita uma vez e protege toda rota do roteador que cita `:code`**, as duas aqui, e
qualquer uma acrescentada depois. Um código com `1`, um código de nove caracteres e um caminho com
espaço são recusados antes de qualquer rota rodar, e a mensagem cita o valor com `JSON.stringify`,
para que os caracteres estranhos que ele tiver cheguem visíveis como texto.

**400 e 404 dizem coisas diferentes.** O `7ctxqn` é um código bem formado que pode ou não existir, o
que é pergunta para o store e um 404 se não existir. O `seven` nunca poderia ser um código, então
perguntar ao store é inútil e a resposta é erro do cliente, um 400.
