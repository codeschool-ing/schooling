---
title: A query string
version: 1
---

**O `req.query` é a query string, lida num objeto de strings.** Como ela é lida é uma configuração, e
o Express 5 mudou o padrão para a simples. Pedir a um servidor de demonstração que a devolva mostra o
que isso significa:

```javascript
// demo/query.js
import express from "express";

const app = express();
app.get("/q", (req, res) => res.json(req.query));
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -sg 'http://127.0.0.1:3000/q?limit=10&tag=a&tag=b&empty=&user[admin]=true'
{"limit":"10","tag":["a","b"],"empty":"","user[admin]":"true"}
```

O `-g` impede o curl de tratar os colchetes como sintaxe de padrão própria e os manda como estão.

- **Todo valor é string**, ou um array de strings: `limit` é `"10"`, e `empty` é `""`.
- **Um nome dado duas vezes vira array**: `tag` é `["a", "b"]`. Uma rota que espera uma string
  precisa estar pronta para um array, porque quem decide é o cliente.
- **Colchetes não significam nada**: `user[admin]` é uma chave própria, não um objeto `user` com uma
  propriedade `admin`. O Express 4 o lia como objeto, com o pacote `qs` da auditoria da aula 4, e
  objetos aninhados montados a partir da query string de um estranho são de onde vêm os alertas de
  poluição de protótipo. O parser simples não consegue montar um.

## Um limite, conferido

A lista de links do administrador cresce sem fim, então ela aceita um `limit`, e um limite vindo de
uma query string precisa virar número e ficar dentro de uma faixa:

```javascript
// demo/limit.js
import express from "express";

function limitFrom(query, fallback = 20, most = 100) {
  if (query.limit === undefined) return fallback;
  const n = Number(query.limit);
  if (!Number.isInteger(n) || n < 1 || n > most) return null;
  return n;
}

const app = express();
app.get("/links", (req, res) => {
  const limit = limitFrom(req.query);
  if (limit === null) return res.status(400).json({ error: "limit must be a whole number from 1 to 100" });
  res.json({ limit });
});
app.listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links'
{"limit":20}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=5'
{"limit":5}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=2.5'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=abc'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=1&limit=2'
{"error":"limit must be a whole number from 1 to 100"}
ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links?limit=10000000'
{"error":"limit must be a whole number from 1 to 100"}
```

`Number("abc")` é `NaN`, `Number("2.5")` não é inteiro, e `Number(["1", "2"])` também é `NaN`, então
um `Number.isInteger` recusa os três. **Um máximo faz parte da conferência**, não é capricho: sem ele,
`limit=10000000` é um pedido para ler o store inteiro e mandá-lo, que é o loop bloqueado da aula 2
pedido com educação.
