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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um pedido dividido nas partes que o Express entrega a uma rota. O método GET e o caminho /links/7ctxqn são comparados com a rota links.get(&#x27;/:code&#x27;), pendurada em /links; a parte que casou com :code vira req.params.code. O que vem depois do ponto de interrogação, limit=2, vira req.query.limit. Os dois chegam como strings.\"><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">GET /links/7ctxqn?limit=2</text><line x1=\"218\" y1=\"54\" x2=\"300\" y2=\"54\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"305\" y1=\"54\" x2=\"360\" y2=\"54\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"372\" y1=\"54\" x2=\"448\" y2=\"54\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><rect x=\"150\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">links.get(\"/:code\")</text><text x=\"250\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pendurada em /links</text><line x1=\"258\" y1=\"58\" x2=\"250\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"380\" y=\"90\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">req.params.code</text><text x=\"460\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"7ctxqn\"</text><line x1=\"332\" y1=\"58\" x2=\"440\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><rect x=\"560\" y=\"90\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">req.query.limit</text><text x=\"630\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"2\"</text><line x1=\"410\" y1=\"58\" x2=\"610\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os dois são strings, e os dois foram digitados pelo cliente</text></svg>", "caption": "O caminho escolhe a rota e preenche os params; a query string é um objeto à parte, ao lado."}
```

**A conferência é escrita uma vez e protege toda rota do roteador que cita `:code`**, as duas aqui, e
qualquer uma acrescentada depois. Um código com `1`, um código de nove caracteres e um caminho com
espaço são recusados antes de qualquer rota rodar, e a mensagem cita o valor com `JSON.stringify`,
para que os caracteres estranhos que ele tiver cheguem visíveis como texto.

**400 e 404 dizem coisas diferentes.** O `7ctxqn` é um código bem formado que pode ou não existir, o
que é pergunta para o store e um 404 se não existir. O `seven` nunca poderia ser um código, então
perguntar ao store é inútil e a resposta é erro do cliente, um 400.
