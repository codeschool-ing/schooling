---
title: A operação que nunca vai ser aceita
version: 1
---

**Uma drenagem que para em toda falha tem um ponto fraco: uma operação que o servidor sempre vai
recusar trava todas as operações atrás dela, para sempre.** Essa operação se chama **veneno**
(*poison*), e a caixa de saída precisa reconhecê-la, tirá-la do caminho e dizer isso.

A reação errada é tratar toda falha do mesmo jeito, tentar de novo e parar de novo. Um erro de rede
é temporário e a próxima drenagem pode dar certo. Um **422 Unprocessable Entity** é o servidor lendo
a operação e dizendo não, e ele vai dizer não aos mesmos bytes toda vez. Tentar de novo é um laço; as
outras sessões da pessoa esperam atrás e nenhuma sai do celular.

## Tirá-la do caminho

O `drain.ts` já distingue as duas. Um erro de rede ou um 5xx para a drenagem. Um 4xx move a operação
para a tabela `dead` com o motivo do servidor, numa transação junto com tirá-la da caixa de saída, e
a drenagem segue. Uma sessão de 300 minutos, uma correção dela e uma sessão diferente depois das
duas:

```
ana@dev:~/planner/outbox$ node app.ts add s11 statistics 2026-10-27 300
ana@dev:~/planner/outbox$ node app.ts minutes s11 200
ana@dev:~/planner/outbox$ node app.ts add s12 spanish 2026-10-28 30
ana@dev:~/planner/outbox$ node drain.ts
#9 create s11: 422 a session is at most 240 minutes, moved to dead
#10 update s11: held behind a dead operation
#11 create s12: 201
1 waiting
ana@dev:~/planner/outbox$ node app.ts outbox
#10 update s11  {"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}
dead #9 create s11: 422 a session is at most 240 minutes
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-poison\" aria-label=\"A caixa de saída guarda três operações em ordem: a número 9, create s11 com 300 minutos; a número 10, update s11 para 200 minutos; a número 11, create s12. A drenagem envia a número 9 e o servidor responde 422, então ela vai para a tabela dead. A número 10 fica retida, porque atualiza uma sessão que o servidor nunca criou. A número 11 é de outra sessão e é enviada, e o servidor responde 201.\"><defs><marker id=\"l08-poison-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-poison-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a caixa de saída, da mais antiga</text><rect x=\"20\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#9  create s11  300 min</text><text x=\"270\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">422: vai para dead</text><rect x=\"20\" y=\"102\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#10 update s11  200 min</text><text x=\"270\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">retida: mesma sessão</text><rect x=\"20\" y=\"164\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#11 create s12   30 min</text><text x=\"270\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">201: enviada</text><rect x=\"560\" y=\"162\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor</text><path d=\"M240 192 L556 192\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-poison-ah-phosphor)\"></path><rect x=\"560\" y=\"38\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dead</text><path d=\"M240 68 L556 68\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-poison-ah-amber)\"></path></svg>", "caption": "Uma operação recusada sai da fila para as outras passarem, e as operações da mesma linha esperam atrás dela."}
```

Três respostas, e a segunda é a interessante. `#10` é um update válido, 200 minutos, e não foi
enviado. **Ele ficou retido porque a sessão que ele atualiza nunca foi criada no servidor.** Enviado,
ele teria sido um 404; enviado e aceito, teria descrito uma linha que não existe. `s12` é de outra
sessão, não depende de nada, e foi.

Esse é o limite honesto de uma drenagem que pula o veneno. **Operações sobre linhas diferentes são
independentes e podem passar por uma morta; operações sobre a mesma linha não podem.** Se as
operações do planner dependessem umas das outras entre linhas, uma sessão de um curso que tivesse
sido recusado, o conjunto retido teria de seguir essa dependência também.

## Trazê-la de volta

Uma operação morta é uma decisão da pessoa, não do app, e a última seção da aula 7 diz como
apresentá-la: qual sessão, por quê, o que fazer. Aqui a pessoa já corrigiu, mudando a duração para
200. O `revive` descarta a operação morta e a retida, e enfileira um create só a partir da linha
como ela está agora:

```
ana@dev:~/planner/outbox$ node app.ts revive s11
ana@dev:~/planner/outbox$ node app.ts outbox
#12 create s11  {"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}
ana@dev:~/planner/outbox$ node drain.ts
#12 create s11: 201
0 waiting
ana@dev:~/planner/outbox$ curl -s http://127.0.0.1:8008/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":40},{"id":"s8","course":"statistics","date":"2026-10-24","minutes":40},{"id":"s10","course":"guitar","date":"2026-10-26","minutes":20},{"id":"s12","course":"spanish","date":"2026-10-28","minutes":30},{"id":"s11","course":"statistics","date":"2026-10-27","minutes":200}]
```

O servidor tem `s11`, com a duração que a pessoa escolheu, e a caixa de saída está vazia.

## Uma contagem, e um limite

A `dead` também é o lugar onde olhar quando há algo errado com o app e não com a pessoa. Uma versão
que envia um corpo malformado a enche em todo celular ao mesmo tempo, e uma contagem de operações
mortas informada pelo app é como uma equipe descobre no mesmo dia. A aula 9 acrescenta a outra
metade disso: quanto esperar antes de tentar uma operação de novo, e quantas vezes.
