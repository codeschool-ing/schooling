---
title: Operações que são idempotentes por natureza
version: 1
---

**Algumas operações não precisam de chave, porque fazê-las duas vezes já tem o efeito de fazê-las
uma.** Definir um valor é uma delas: "a sessão `s7` são 25 minutos de violão em 23 de outubro" dito
duas vezes deixa a mesma sessão. Somar não é: "acrescente uma sessão" dito duas vezes acrescenta
duas. O HTTP dá nome à diferença. `PUT` e `DELETE` são definidos como idempotentes, `POST` não, e as
definições são uma promessa que o código do servidor precisa cumprir.

O planner pode usar isso. **Se o aparelho escolhe o id de uma sessão quando ela é criada**, como as
aulas 7 e 8 fizeram com `s7`, então criá-la pode ser um `PUT` em `/sessions/s7` em vez de um `POST`
em `/sessions`, e uma nova tentativa é inofensiva por construção. A duplicata da aula 9 precisou de
um servidor que escolhia ids; um cliente que os escolhe elimina o caso. A aula 4 explica por que um
id criado no aparelho precisa ser aleatório em vez de `s7`, que dois celulares escolheriam.

Suba o servidor como `node server.ts`, sem falhas, e mande o mesmo `PUT` duas vezes:

```
ana@dev:~/planner/idempotency$ curl -s -X PUT -H 'x-user: ana' -d '{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}' http://127.0.0.1:8010/sessions/s7
{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
ana@dev:~/planner/idempotency$ curl -s -X PUT -H 'x-user: ana' -d '{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}' http://127.0.0.1:8010/sessions/s7
{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}
ana@dev:~/planner/idempotency$ curl -s http://127.0.0.1:8010/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":25}]
```

Duas requisições, uma sessão. O servidor guardou o corpo sob o caminho, então o segundo `PUT`
escreveu os mesmos bytes sobre eles mesmos.

## Onde isso para

A idempotência natural cobre uma escrita que diz o resultado inteiro. Ela não cobre:

- **um pagamento**, em que o efeito está fora do servidor, na processadora do cartão, e a
  processadora precisa da própria chave;
- **um incremento**, "some 25 minutos à semana", que é o evento da aula 8 que não pode ser dobrado e
  o contador da aula 15;
- **um `PUT` que faz mais do que guardar**: um que também manda um e-mail, ou cobra, ou acrescenta a
  um histórico, é idempotente na linha guardada e não nos efeitos colaterais.

Então as duas ferramentas dividem o trabalho. **Linhas que o aparelho nomeia vão por `PUT`, com o id
do aparelho; operações que causam algo vão por `POST`, com uma chave de idempotência.** As sessões do
planner são do primeiro tipo e comprar um curso é do segundo, e um app precisa dos dois.
