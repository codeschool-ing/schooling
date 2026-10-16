---
title: Uma rede ruim que você liga e desliga
version: 1
---

**Para testar numa conexão ruim, você precisa de uma que seja ruim quando pedir, do mesmo jeito toda
vez.** As redes ruins de verdade não são nenhuma das duas coisas: o túnel não está lá quando o teste
roda, e quando está, é ruim de um jeito diferente a cada passada. Então você constrói uma. Um
**proxy** é um programa que fica entre um cliente e um servidor, recebe a requisição do cliente,
repassa, e devolve a resposta. Um proxy que segura respostas, as manda devagar ou joga algumas fora é
uma rede ruim que você liga com um comando, na frente do boxoffice, do stub de pagamento, ou de
qualquer outra coisa que fale HTTP.

## O proxy

Umas oitenta linhas de Node sem dependências, como o boxoffice. Ele repassa toda requisição intacta e
estraga só a resposta, uma escolha que vale entender antes de usá-lo: **a requisição sempre chega**,
então o que o servidor fizer, está feito. O que o cliente perde é a notícia. Essa é a metade de uma
falha que um cliente não consegue distinguir de uma requisição que nunca saiu, e por isso a metade
para a qual ele precisa se preparar. Salve como `slow-proxy.mjs`:

```js
// slow-proxy.mjs: a bad network between a client and a server, on purpose.
// Start it with `node slow-proxy.mjs`. It listens on port 8070 (PORT changes
// that), forwards every request to TARGET (http://localhost:8080 unless set)
// and spoils the answer on its way back:
//   DELAY  milliseconds each answer is held before it is sent (default 0)
//   RATE   bytes per second the body of an answer is sent at; 0 is no limit
//   DROP   the share of answers thrown away, from 0 to 1: the connection is
//          cut and the client receives nothing at all (default 0)
//   SEED   where the drops start, so a run can be repeated exactly (default 1)
// The request always reaches the server. What is lost is the answer, which is
// the half a client cannot tell apart from a request that never arrived.
import http from 'node:http';

const PORT = Number(process.env.PORT || 8070);
const TARGET = process.env.TARGET || 'http://localhost:8080';
const DELAY = Number(process.env.DELAY || 0);
const RATE = Number(process.env.RATE || 0);
const DROP = Number(process.env.DROP || 0);
let seed = Number(process.env.SEED || 1);

// A small random number generator (mulberry32) that the same SEED repeats.
function random() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

const wait = (ms) => new Promise((done) => setTimeout(done, ms));

// Ask the real server, and collect its whole answer.
function forward(req, body) {
  return new Promise((resolve, reject) => {
    const out = http.request(new URL(req.url, TARGET), { method: req.method, headers: req.headers }, (res) => {
      const parts = [];
      res.on('data', (part) => parts.push(part));
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(parts) }));
    });
    out.on('error', reject);
    out.end(body);
  });
}

// Send the body RATE bytes a second, a tenth of a second at a time.
async function trickle(res, body) {
  const step = Math.max(1, Math.round(RATE / 10));
  for (let i = 0; i < body.length && !res.destroyed; i += step) {
    res.write(body.subarray(i, i + step));
    await wait(100);
  }
  res.end();
}

let count = 0;
http.createServer(async (req, res) => {
  const n = ++count;
  const parts = [];
  for await (const part of req) parts.push(part);
  const lose = random() < DROP;
  let answer;
  try {
    answer = await forward(req, Buffer.concat(parts));
  } catch (err) {
    console.log(`${n} ${req.method} ${req.url}: the server did not answer (${err.code})`);
    return req.socket.destroy();
  }
  await wait(DELAY);
  if (res.destroyed) {
    console.log(`${n} ${req.method} ${req.url} ${answer.status}, but the client had hung up`);
    return;
  }
  if (lose) {
    console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer dropped`);
    return req.socket.destroy();
  }
  console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer sent`);
  const headers = { ...answer.headers, 'content-length': answer.body.length };
  delete headers['transfer-encoding'];
  res.writeHead(answer.status, headers);
  if (RATE > 0) await trickle(res, answer.body);
  else res.end(answer.body);
}).listen(PORT, () => {
  console.log(`slow proxy listening on http://localhost:${PORT}, forwarding to ${TARGET}`);
  console.log(`  DELAY ${DELAY} ms, RATE ${RATE || 'unlimited'} B/s, DROP ${DROP}, SEED ${seed}`);
});
```

```schooling-example
{
 "language": "js",
 "file": "slow-proxy.mjs",
 "parts": [
  {
   "code": "let seed = Number(process.env.SEED || 1);\n\n// A small random number generator (mulberry32) that the same SEED repeats.\nfunction random() {",
   "note": "O `Math.random()` não aceita semente, então uma execução que derrubou a terceira resposta derrubaria a quinta na próxima. Este gerador dá a mesma sequência para a mesma `SEED`, o que transforma uma falha que você viu uma vez numa falha que você consegue mostrar a alguém."
  },
  {
   "code": "  const lose = random() < DROP;\n  let answer;\n  try {\n    answer = await forward(req, Buffer.concat(parts));",
   "note": "Se esta resposta vai se perder é decidido primeiro, na ordem em que as requisições chegam; depois a requisição vai para o servidor, seja qual for a decisão."
  },
  {
   "code": "  await wait(DELAY);\n  if (res.destroyed) {",
   "note": "A resposta fica retida. Se o cliente desistiu enquanto ela esperava, o proxy diz isso no log, e é assim que um timeout do lado do cliente aparece deste lado."
  },
  {
   "code": "  if (lose) {\n    console.log(`${n} ${req.method} ${req.url} ${answer.status}, answer dropped`);\n    return req.socket.destroy();\n  }",
   "note": "Uma resposta perdida: a conexão é cortada sem nada enviado. O status do servidor fica no log, então você vê o que o cliente nunca soube."
  },
  {
   "code": "  if (RATE > 0) await trickle(res, answer.body);\n  else res.end(answer.body);",
   "note": "Com `RATE`, o corpo sai um décimo de segundo de cada vez, como num link fino; os cabeçalhos vão na hora."
  }
 ]
}
```

Ele precisa do boxoffice rodando na 8080, como sempre. Inicie o proxy num terminal próprio, em
`~/boxoffice`; sem nada definido, ele não muda nada:

```
ana@laptop:~/boxoffice$ node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0, SEED 1
```

## Latência

Toda requisição por ele faz um salto a mais. A mesma lista de espetáculos, do próprio boxoffice e pelo
proxy, com o `-w` do curl imprimindo o status e o tempo total em segundos:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8080/v1/shows
200 0.006800
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8070/v1/shows
200 0.023955
```

Os dois abaixo de três centésimos de segundo: o salto extra quase não custa nada. Pare o proxy com
Ctrl-C e inicie-o segurando cada resposta por 800 ms:

```
ana@laptop:~/boxoffice$ DELAY=800 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 800 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{time_total}\n' localhost:8070/v1/shows
200 0.818174
```

0,818 segundo: o atraso, mais os poucos milissegundos que a viagem em si leva. Toda requisição paga
isso, e uma tela que precisa de três requisições em sequência paga três vezes.

## Banda

`RATE=200` manda as respostas a 200 bytes por segundo. O curl consegue dizer quando chegou o primeiro
byte da resposta e quando chegou o último:

```
ana@laptop:~/boxoffice$ RATE=200 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE 200 B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{size_download} bytes, first byte %{time_starttransfer}, last %{time_total}\n' localhost:8070/v1/shows
200 379 bytes, first byte 0.020703, last 1.835973
```

O primeiro byte chega na hora e o último depois de quase dois segundos, para 379 bytes. Duzentos bytes
por segundo é muito mais lento que até o perfil mais lento do emulador na seção 05, escolhido para o
efeito ficar fácil de ver; nesse ritmo, uma imagem de 200 kilobytes levaria uns dezessete minutos.
**Banda castiga tamanho**, e um teste dela pertence às telas que carregam mais.

## Perda

`DROP=0.3` joga fora umas três respostas em dez. O curl imprime `000` para uma requisição que não
recebeu status nenhum:

```
ana@laptop:~/boxoffice$ DROP=0.3 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.3, SEED 1
ana@laptop:~/boxoffice$ for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' localhost:8070/v1/shows; done; echo
200 000 200 200 200 000 200 200 200 200 
```

E o terminal do proxy diz quais, e o que o servidor tinha respondido:

```
ana@laptop:~/boxoffice$ DROP=0.3 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 0 ms, RATE unlimited B/s, DROP 0.3, SEED 1
1 GET /v1/shows 200, answer sent
2 GET /v1/shows 200, answer dropped
3 GET /v1/shows 200, answer sent
4 GET /v1/shows 200, answer sent
5 GET /v1/shows 200, answer sent
6 GET /v1/shows 200, answer dropped
7 GET /v1/shows 200, answer sent
8 GET /v1/shows 200, answer sent
9 GET /v1/shows 200, answer sent
10 GET /v1/shows 200, answer sent
```

**Duas perdidas, não três.** Uma fração é uma chance por requisição, e dez requisições são poucas, e é
por isso que a semente importa: com a `SEED` igual, as mesmas duas se perdem em toda execução, e um
teste que falhou por causa da segunda requisição falha de novo pelo mesmo motivo. Mude a semente para
ver um dia ruim diferente.

## Mais lento do que o cliente espera

O último caso é aquele com que a seção 02 terminou: uma resposta mais lenta que o timeout do cliente.
O Tickets espera cinco segundos; o `--max-time 5` do curl espera o mesmo. Com o proxy segurando as
respostas por seis:

```
ana@laptop:~/boxoffice$ DELAY=6000 node slow-proxy.mjs
slow proxy listening on http://localhost:8070, forwarding to http://localhost:8080
  DELAY 6000 ms, RATE unlimited B/s, DROP 0, SEED 1
ana@laptop:~/boxoffice$ curl -sS --max-time 5 localhost:8070/v1/shows; echo "exit $?"
curl: (28) Operation timed out after 5002 milliseconds with 0 bytes received
exit 28
```

`curl: (28)` é o código do curl para timeout, depois de 5002 ms e nenhum byte. **Seis segundos é uma
rede funcionando**, pela qual o boxoffice respondeu em poucos milissegundos, e para o cliente ela não
se distingue de rede nenhuma. A seção 05 mostra o que o Tickets diz ao usuário quando isso acontece.
