---
title: Um servidor, de mais cinco jeitos
version: 1
---

**Este curso escolheu uma linguagem e foi fundo nela, e a primeira aula fez uma promessa sobre a
última**: que HTTP, códigos de status, configuração pelo ambiente, um desligamento limpo e o resto
existem em toda linguagem de servidor, e que, tendo construído isso uma vez, você os leria em outro
lugar como as mesmas ideias com nomes novos. Esta aula cumpre a promessa. Ela escreve um servidor
pequeno em Node e depois em outras cinco linguagens que rodam uma boa parte dos servidores do mundo,
roda cada um, e faz as mesmas três perguntas a todos.

O servidor é pequeno de propósito, para que o que mude seja a linguagem e não o programa:

| pedido | resposta |
|---|---|
| `GET /hello?name=ana` | `200`, `{"hello":"ana"}`; sem nome, `world` |
| `GET /slow` | `200` depois de um segundo, como se esperasse um banco |
| qualquer outro | `404`, `{"error":"nothing at /…"}` |

Ele escuta na porta que está em `PORT`, ou na 3000, como a aula 9 ensinou.

A versão em Node, só com o `node:http`, em `~/server/other/node`; cada linguagem ganha uma pasta ao
lado:

```javascript
// hello.mjs: the server every section of this lesson writes again.
import http from "node:http";

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");
  const send = (status, body) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body));
  };
  if (req.method === "GET" && url.pathname === "/hello") {
    return send(200, { hello: url.searchParams.get("name") ?? "world" });
  }
  if (req.method === "GET" && url.pathname === "/slow") {
    return setTimeout(() => send(200, { slept: 1000 }), 1000);
  }
  send(404, { error: `nothing at ${url.pathname}` });
});
const port = Number(process.env.PORT ?? 3000);
server.listen(port, "127.0.0.1", () => console.log(`node on :${port}`));
```

```
ana@dev:~/server/other/node$ node hello.mjs
node on :3000
^C
```

E as três perguntas, feitas de um segundo terminal: ele responde, ele diz 404 direito, e **quanto
tempo levam dez pedidos lentos que chegam juntos?**

```
ana@dev:~/server/other/node$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/node$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"} 404
ana@dev:~/server/other/node$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.016s
user	0m0.030s
sys	0m0.025s
```

**Dez pedidos que esperam um segundo cada levaram um segundo no total**, porque o Node espera todos ao
mesmo tempo: o event loop da aula 2. A última pergunta é onde as linguagens mais diferem, e a seção
sobre modelos de concorrência volta a ela.

## Você não precisa instalá-las

Cada seção mostra a execução, então a aula pode ser lida sem instalar nada. Se quiser experimentar uma,
cada seção dá os comandos para o Ubuntu, que também é o que o WSL roda no Windows, e para um Mac com
Homebrew. **Os comandos `apt` foram rodados na máquina do curso e os do Homebrew não**; são os nomes de
fórmula de sempre, e a seção sobre Go diz como o Go dela foi instalado. Cada linguagem ocupa algumas
centenas de megabytes, e um `sudo apt remove` com o mesmo nome de pacote a tira de novo.
