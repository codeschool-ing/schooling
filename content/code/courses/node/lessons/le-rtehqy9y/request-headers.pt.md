---
title: Lendo cabeçalhos da requisição
version: 1
---

**O `req.get(nome)` lê um cabeçalho em qualquer combinação de maiúsculas, e três auxiliares respondem
às perguntas para as quais os cabeçalhos costumam ser lidos.** Eles poupam escrever a leitura à mão, e
acertam os detalhes:

| auxiliar | a pergunta | lê |
|---|---|---|
| `req.get("x-admin-key")` | o que este cabeçalho diz? | qualquer cabeçalho |
| `req.is("application/json")` | o corpo é deste tipo? | `content-type` |
| `req.accepts(["json", "text"])` | qual destes o cliente aceita? | `accept` |
| `req.ip`, `req.ips` | quem mandou? | o socket, e o `x-forwarded-for` quando há confiança |

O `req.ip` tem a última seção desta aula só para ele. Os outros três numa demonstração:

```javascript
// demo/headers.js
import express from "express";

const app = express();
app.use(express.text());

app.post("/echo", (req, res) => {
  res.json({ isJson: req.is("application/json"), isText: req.is("text/*"), agent: req.get("user-agent") });
});

app.get("/links/:code", (req, res) => {
  const link = { code: req.params.code, url: "https://example.com/" };
  const kind = req.accepts(["json", "text"]);
  if (kind === "text") return res.type("text").send(`${link.code} -> ${link.url}\n`);
  if (kind === "json") return res.json(link);
  res.status(406).json({ error: "this answers in JSON or plain text" });
});

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: text/plain' -d 'hello' http://127.0.0.1:3000/echo
{"isJson":false,"isText":"text/plain","agent":"curl/8.5.0"}
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{}' http://127.0.0.1:3000/echo
{"isJson":"application/json","isText":false,"agent":"curl/8.5.0"}
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/links/7ctxqn
{"code":"7ctxqn","url":"https://example.com/"}
ana@dev:~/server/links$ curl -s -H 'accept: text/plain' http://127.0.0.1:3000/links/7ctxqn
7ctxqn -> https://example.com/

ana@dev:~/server/links$ curl -s -H 'accept: image/png' http://127.0.0.1:3000/links/7ctxqn
{"error":"this answers in JSON or plain text"}
```

**O `req.is` responde com o tipo que casou, ou `false`**, e entende curingas e parâmetros,
`text/plain; charset=utf-8` incluído, que uma comparação de strings no cabeçalho erraria. **O
`req.accepts` é negociação de conteúdo**: o cliente diz o que aceita, em ordem de preferência, e o
servidor escolhe o melhor que tem. O `Accept: */*` padrão do curl aceita qualquer coisa, então o
primeiro oferecido venceu, JSON. Um cliente que não aceita nenhum dos dois recebe um 406, Not
Acceptable, que é uma resposta mais clara que um corpo que ele não consegue ler.

Negociação é rara numa API que responde JSON a todo mundo, e comum nas beiradas dela: um endpoint que
manda um CSV a uma planilha e JSON a um programa, ou uma página de erro que é HTML para um navegador e
JSON para o `fetch`.
