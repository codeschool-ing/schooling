---
title: Os middlewares que o Express traz
version: 1
---

**O Express traz alguns middlewares para o trabalho de que quase todo serviço precisa**, e cada um é
uma chamada que devolve uma função para o `app.use`:

| middleware | o que faz | o que deixa no `req` |
|---|---|---|
| `express.json()` | lê um corpo JSON, com limite de tamanho | `req.body`, um objeto |
| `express.urlencoded()` | lê um formulário, `nome=valor&…` | `req.body`, um objeto |
| `express.text()`, `express.raw()` | lê um corpo como string, ou como Buffer | `req.body` |
| `express.static(pasta)` | manda os arquivos de uma pasta, com tipos e cabeçalhos de cache | nada; ele responde |

## express.json

Ele substitui o `readJson` da aula 5, com as mesmas três conferências:

```javascript
// demo/json.js
import express from "express";

const app = express();
app.use(express.json({ limit: "1kb" }));

app.post("/links", (req, res) => res.json({ received: req.body }));

app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/links
{"received":{"url":"https://example.com/"}}
ana@dev:~/server/links$ curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/links
{}
```

**Um corpo que não é JSON não é recusado: é ignorado.** O `express.json` só lê uma requisição cujo
`content-type` diz JSON, e passa qualquer outra adiante sem `req.body` nenhum, o que no Express 5 é
`undefined`. É por isso que o formulário recebeu `{}` de volta: `received` era `undefined`, e o JSON
deixa uma propriedade assim de fora. Então uma rota que lê `req.body.url` lança um `TypeError` num
formulário, e uma rota que lê `req.body?.url` trata um formulário como corpo vazio. A aula 7 decide
qual dos dois o serviço links quer. As duas falhas que o `readJson` respondia sozinho, grande demais e
mal formado, são erros que o `express.json` passa ao handler de erros, e a seção sobre handlers de
erro mostra o que ele faz com eles.

## express.static

```javascript
// demo/static.js
import express from "express";
import path from "node:path";

const app = express();
app.use(express.static(path.join(import.meta.dirname, "..", "public")));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ mkdir -p public && echo '<h1>links</h1>' > public/index.html
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/
HTTP/1.1 200 OK
X-Powered-By: Express
Accept-Ranges: bytes
Cache-Control: public, max-age=0
Last-Modified: Fri, 16 Oct 2026 23:19:53 GMT
ETag: W/"f-1a14703cc20"
Content-Type: text/html; charset=utf-8
Content-Length: 15
Date: Fri, 16 Oct 2026 23:19:53 GMT
Connection: keep-alive
Keep-Alive: timeout=5

<h1>links</h1>

ana@dev:~/server/links$ curl -s -o /dev/null -w "%{http_code}\n" --path-as-is http://127.0.0.1:3000/../package.json
404
```

O `express.static` respondeu `/` com o `index.html`, definiu o tipo, e acrescentou o `Last-Modified` e
cabeçalhos de cache. **A pasta é montada a partir do `import.meta.dirname`**, então o programa
encontra o `public` ao lado do projeto de qualquer pasta de onde for iniciado, o argumento da aula 3
sobre o `process.cwd()`. E uma requisição para um caminho fora da pasta é recusada: o `--path-as-is`
faz o curl mandar `/../package.json` como está escrito em vez de arrumá-lo, e a pasta se manteve como
fronteira.
