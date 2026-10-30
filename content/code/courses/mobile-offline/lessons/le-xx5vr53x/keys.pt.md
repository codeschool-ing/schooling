---
title: A chave, criada no aparelho quando a pessoa age
version: 1
---

**A chave é criada uma vez, quando a pessoa age, antes de a primeira requisição sair, e a mesma chave
vai com toda nova tentativa daquela operação.** Cada palavra dessa frase é uma regra que alguém já
quebrou.

- **Criada uma vez.** Uma chave criada por requisição é uma chave nova na nova tentativa, e o
  servidor vê uma operação nova. É exatamente o erro que a chave existe para impedir.
- **Quando a pessoa age.** Uma chave feita a partir do corpo, um hash de curso e valor, diz que dois
  toques em Comprar são um só, e podem não ser: a pessoa pode querer duas vagas.
- **No aparelho.** Só o aparelho sabe que uma nova tentativa é uma nova tentativa. O servidor vê duas
  requisições e nada mais.

O `buy.ts` a cria com `randomUUID()`, de `node:crypto`, fora do laço. Um UUID versão 4 tem 122 bits
aleatórios, então dois celulares escolhendo o mesmo não é um caso que valha projetar. Suba o servidor
como `node server.ts drop` de novo e toque em Comprar, desta vez com chave:

```
ana@dev:~/planner/idempotency$ node buy.ts key
attempt 1: no answer, trying again
attempt 2: 201, replayed { id: 'p1', user: 'ana', course: 'statistics', cents: 4900 }
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/purchases
[{"id":"p1","user":"ana","course":"statistics","cents":4900}]
```

A primeira tentativa cobrou `p1` e perdeu a resposta, como antes. A nova tentativa levou a mesma
chave, e o servidor respondeu **com a resposta que tinha guardado**, `p1` de novo, e um cabeçalho
dizendo que era uma repetição. Uma cobrança. O cliente não distingue uma repetição de uma primeira
resposta e não precisa; o cabeçalho está ali para registros e testes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-key\" aria-label=\"Uma sequência no tempo entre o celular e o servidor. O celular cria a chave K quando a pessoa toca em Comprar e envia POST /purchases com a chave K. O servidor cobra o cartão, guarda p1 como a resposta de K, e o 201 dele se perde na volta. O celular não vê resposta e tenta de novo com a mesma chave K. O servidor encontra K, manda de novo o p1 guardado marcado como repetido, e não cobra nada.\"><defs><marker id=\"l10-key-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-key-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"70\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o celular</text><rect x=\"490\" y=\"14\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor</text><path d=\"M140 44 L140 290\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M560 44 L560 290\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"150\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">toca em Comprar: a chave K nasce</text><path d=\"M140 76 L560 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><text x=\"350\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST /purchases, chave K</text><rect x=\"568\" y=\"92\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"102.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobra o cartão</text><text x=\"643.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">guarda p1 sob K</text><path d=\"M560 132 L350 142\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-key-ah-amber)\"></path><text x=\"330\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">✕</text><text x=\"350\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">201 perdido no caminho</text><text x=\"150\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sem resposta: mesma chave K de novo</text><path d=\"M140 196 L560 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><rect x=\"568\" y=\"210\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"220.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">acha K: manda p1 de novo</text><text x=\"643.0\" y=\"233.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não cobra nada</text><path d=\"M560 256 L140 276\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-key-ah-phosphor)\"></path><text x=\"350\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">201, repetido: p1</text></svg>", "caption": "A chave nasce antes da primeira tentativa e vai em toda nova tentativa, então o servidor distingue uma nova tentativa de uma segunda compra."}
```

## Na caixa de saída

Num app a chave mora na linha da caixa de saída, gravada na mesma transação da mudança, ao lado de
`seq`. A tabela da aula 8, com uma coluna a mais:

```sql
create table if not exists outbox (
  seq     integer primary key autoincrement,
  op      text not null check (op in ('create', 'update', 'delete')),
  session text not null,
  body    text,
  key     text not null unique  -- made with the row, sent with every try of it
);
```

*Esta tabela é a da aula 8 com a coluna `key` acrescentada; a aula não a roda de novo.*

Guardá-la ali é o que a faz sobreviver ao app ser encerrado entre duas tentativas: a próxima
drenagem, num processo novo, lê a mesma chave de volta.

**E isso muda a coalescência da aula 8 num ponto.** Dobrar um update dentro de um create só é seguro
se o create nunca foi enviado. Se ele foi enviado e a resposta se perdeu, o servidor pode tê-lo
guardado sob a chave dele; reenviar um corpo diferente sob a mesma chave é recusado por um servidor
que compara corpos, e num que não compara, respondido com a resposta antiga guardada enquanto o
update some em silêncio. Então uma operação que já foi tentada pelo menos uma vez nunca recebe outra
dobrada dentro dela, e uma coluna como `tried` na linha da caixa de saída é como a drenagem e a
compactação concordam sobre isso.
