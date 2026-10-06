---
title: A aba de rede
version: 1
---

**O painel Network lista toda requisição que uma página faz: o que pediu, o status que voltou, o
tamanho e o tempo.** Quando uma página mostra o dado errado, ou nenhum, é aqui que você descobre se
o problema está na página ou no servidor. O `--network` do laboratório imprime uma linha por
resposta. O `missing.html` carrega este script com `<script type="module">`, porque ele usa `await`
no nível de cima, como a aula 9 explicou:

```javascript
for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
  const res = await fetch(path);
  console.log(path, "answered", res.status);
}
```

```
ana@dev:~/js$ page missing.html --network
net  GET /missing.html  200  document  165 B
/api/books/2 answered 200
net  GET /missing.js  200  script  150 B
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
/api/books/9 answered 404
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
/api/broken answered 500
net  GET /api/books/2  200  fetch  87 B
net  GET /api/books/9  404  fetch  21 B
net  GET /api/broken  500  fetch  41 B
```

Cada linha `net` tem o método, o endereço, o **status**, o **tipo** da requisição e o tamanho do
corpo. O laboratório imprime a linha quando o corpo chega, então as linhas das três requisições vêm
depois das mensagens da própria página.

Duas coisas aqui valem saber antes que confundam você:

- **O Chromium registrou um `[error]` para o 404 e o 500 por conta própria**, `Failed to load
  resource`, embora o código da página tenha tratado os dois. Essa mensagem vem da camada de rede do
  navegador, não do seu código;
- **O `fetch` não lançou erro.** Um 404 e um 500 são respostas, como a aula 16 mostrou, e o código
  leu o status deles. No painel eles aparecem em vermelho, o que quer dizer "o servidor disse não",
  não "o código quebrou".

No DevTools, clicar numa requisição mostra os cabeçalhos, o corpo enviado e o corpo recebido. A
opção **Preserve log** mantém a lista através de um recarregamento ou de um redirecionamento, e
**Disable cache** faz toda requisição ir ao servidor. Nenhuma das duas foi capturada aqui.

## A cascata

A coluna de tempo do painel Network desenha cada requisição como uma barra numa linha do tempo
comum: a **cascata** (waterfall). É o jeito mais rápido de ver requisições que esperam umas pelas
outras sem precisar. O `waits.html` também carrega este como módulo:

```javascript
const get = (book) => fetch(`/api/slow?ms=400&book=${book}`).then((res) => res.json());
const tenths = (ms) => Math.round(ms / 100) * 100;

async function oneByOne() {
  const t0 = performance.now();
  await get(1);
  await get(2);
  await get(3);
  console.log(`one by one: about ${tenths(performance.now() - t0)} ms`);
}

async function together() {
  const t0 = performance.now();
  await Promise.all([get(1), get(2), get(3)]);
  console.log(`together: about ${tenths(performance.now() - t0)} ms`);
}

await oneByOne();
await together();
```

```
ana@dev:~/js$ page waits.html --wait 3000 --waterfall
one by one: about 1200 ms
together: about 400 ms
start  took    request
    0     0  GET /waits.html              #
    0     0  GET /waits.js                #
    0   400  GET /api/slow?ms=400&book=1  ####
  400   400  GET /api/slow?ms=400&book=2      ####
  800   400  GET /api/slow?ms=400&book=3          ####
 1200   400  GET /api/slow?ms=400&book=1              ####
 1200   400  GET /api/slow?ms=400&book=2              ####
 1200   400  GET /api/slow?ms=400&book=3              ####
```

O `--waterfall` do laboratório desenha a mesma linha do tempo em texto, arredondada a 100 ms, com
um `#` a cada 100 ms. As três primeiras requisições formam uma escada. Cada uma começa quando a
anterior termina, porque cada `await` espera antes de o próximo `fetch` ser enviado. As três últimas
começam juntas, porque o `Promise.all` enviou as três antes de esperar por qualquer uma.

**Uma escada na cascata é o formato de um `await` sequencial.** Quando as requisições não dependem
umas das outras, enviá-las juntas transforma três esperas em uma, como a aula 14 mostrou. O
`front-performance`, na aula 6, leva a cascata adiante, com o painel Performance e o Lighthouse.
