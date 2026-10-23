---
title: Os auxiliares da resposta
version: 1
---

**O Express acrescenta à resposta métodos para tudo o que o `send` da aula 5 fazia à mão**, e a
maioria deles devolve a resposta, então eles se encadeiam:

| auxiliar | o que faz |
|---|---|
| `res.status(201)` | define o status, e devolve o `res` |
| `res.set(nome, valor)`, `res.type("text")` | define um cabeçalho, ou o content type por um nome curto |
| `res.json(valor)` | escreve JSON, com tipo e tamanho |
| `res.send(corpo)` | escreve uma string como HTML, um Buffer como bytes, um objeto como JSON |
| `res.location(url)` | define o `Location`, para um 201 ou um redirecionamento |
| `res.redirect(status, url)` | define o status e o `Location`, com um corpo curto |
| `res.sendStatus(404)` | o status, com o nome dele como corpo |
| `res.end()` | encerra sem corpo, do que um 204 precisa |

## Qual redirecionamento

O serviço links responde os links curtos com um redirecionamento, e existem quatro, que diferem de
dois jeitos:

| status | permanente? | o cliente pode trocar POST por GET? |
|---|---|---|
| 301 Moved Permanently | sim, e os navegadores o guardam | pode, e troca |
| 302 Found | não | pode, e troca |
| 307 Temporary Redirect | não | não: o mesmo método e o mesmo corpo |
| 308 Permanent Redirect | sim | não |

```javascript
// demo/redirects.js
import express from "express";

const app = express();
for (const status of [301, 302, 307, 308]) {
  app.all(`/r${status}`, (req, res) => res.redirect(status, "/landed"));
}
app.all("/landed", (req, res) => res.send(`landed with ${req.method}\n`));
app.listen(3000, "127.0.0.1");
```

O `curl -L` segue redirecionamentos como um navegador faria, e o `-X POST -d …` começa com um POST:

```
ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r302
landed with GET

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r307
landed with POST

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r301
landed with GET

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r308
landed with POST

ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/r302 | grep -iE '^HTTP|^location'
HTTP/1.1 302 Found
Location: /landed
```

**O 302 chegou como GET e o 307 manteve o POST.** Para o redirecionamento do próprio serviço links um
302 é o certo: só GETs seguem um link curto. E **um 301 é uma promessa que o serviço não consegue
desfazer**, porque um navegador que viu um pode ir direto ao endereço antigo por meses sem perguntar
de novo. Um link que é apagado, ou mudado, precisa ser perguntado toda vez, e é o 302 que faz isso
acontecer.
