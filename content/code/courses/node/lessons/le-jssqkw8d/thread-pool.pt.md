---
title: O pool de threads
version: 1
---

**Algumas funções do Node não têm como ser feitas sem bloquear, então a libuv as faz num pool de
quatro threads.** O seu callback continua rodando na thread principal; só o trabalho em C por baixo
acontece no pool. Quatro grupos de funções o usam:

| o quê | por que precisa de uma thread |
|---|---|
| a maior parte do `node:fs` | o Linux não oferece um jeito geral de ler um arquivo sem esperar |
| `crypto.pbkdf2`, `scrypt`, `randomBytes` e mais algumas | são computação pura, e longa |
| `zlib`, a compressão da aula 8, na forma com callback | o mesmo |
| `dns.lookup`, que o `http.get("http://example.com")` usa | ele chama o resolvedor do sistema, que bloqueia |

Sockets de rede não estão na tabela, e a próxima seção trata do porquê.

## Quatro de cada vez

O `pbkdf2` estica uma senha numa chave aplicando o hash muitas vezes, que é o que um servidor faz
quando alguém entra. Este programa pede vários ao mesmo tempo e imprime quando cada um termina:

```javascript
// pool.js: hash a password N times at once and say when each one finished.
const crypto = require("node:crypto");

const n = Number(process.argv[2] || 4);
const start = performance.now();
for (let i = 1; i <= n; i++) {
  crypto.pbkdf2("correct horse", "salt", 1_000_000, 64, "sha512", () => {
    console.log(`hash ${i} done at ${Math.round(performance.now() - start)} ms`);
  });
}
```

```
ana@dev:~/server/loop$ node pool.js 1
hash 1 done at 425 ms
ana@dev:~/server/loop$ node pool.js 4
hash 1 done at 423 ms
hash 3 done at 425 ms
hash 2 done at 445 ms
hash 4 done at 453 ms
ana@dev:~/server/loop$ node pool.js 6
hash 2 done at 426 ms
hash 1 done at 428 ms
hash 3 done at 428 ms
hash 4 done at 434 ms
hash 5 done at 843 ms
hash 6 done at 848 ms
```

Um hash leva cerca de 430 ms. Quatro levam mais ou menos o mesmo tempo, porque quatro threads os
fizeram lado a lado. **Seis levam o dobro, em duas levas**: quatro começaram juntos, e os hashes 5 e
6 esperaram uma thread ficar livre. Nada disso aparece no JavaScript. As chamadas retornaram na hora,
e a espera aconteceu numa fila na frente do pool.

## Mudando o tamanho

O `UV_THREADPOOL_SIZE` define o tamanho do pool quando o processo começa, de 1 até 1024:

```
ana@dev:~/server/loop$ UV_THREADPOOL_SIZE=6 node pool.js 6
hash 4 done at 521 ms
hash 1 done at 543 ms
hash 3 done at 565 ms
hash 5 done at 597 ms
hash 2 done at 695 ms
hash 6 done at 696 ms
```

Com seis threads os seis começaram juntos, e nenhum terminou tão cedo quanto 430 ms. **Este
computador tem quatro processadores**, então seis threads fazendo computação pura dividiram quatro
processadores e cada uma levou mais tempo. Aumentar o pool ajuda quando as threads dele passam a
maior parte do tempo esperando, como num disco lento ou num servidor de DNS lento, e pouco faz por um
trabalho que precisa de processador o tempo todo. Ele também é um pool para o processo inteiro: uma
rajada de hashes de senha atrasa cada leitura de arquivo que estiver na fila atrás dela.

A aula 9 trata de definir variáveis como esta, e a aula 10 do que fazer com um trabalho que precisa
de mais processadores do que um pool consegue dar.
