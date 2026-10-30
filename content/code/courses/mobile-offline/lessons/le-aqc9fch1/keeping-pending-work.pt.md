---
title: Guardar o trabalho que ainda não foi enviado
version: 1
---

**Uma ressincronização substitui a cópia que o aparelho tem do dado do servidor. Ela não pode
substituir o trabalho da pessoa que o servidor ainda não viu**, e esse trabalho é a caixa de saída.
Jogar fora o arquivo antigo com a caixa de saída dentro seria o erro de "substituir tudo" da aula 11,
cometido justamente pelo trecho de código que devia ser cuidadoso.

O `resync.ts` cuida disso em dois passos, dentro da mesma transação que grava o snapshot. Ele copia
toda linha da caixa de saída com o seu `seq`, então a ordem se mantém e a chave de idempotência da
aula 10, numa caixa de saída de verdade, vem junto com a linha. Depois ele aplica cada operação
pendente à cópia nova: um create ou um update escreve o corpo por cima da linha do snapshot, e um
delete a remove. **A tela depois da ressincronização mostra o que mostrava antes, mais o que o
servidor sabia e o aparelho não.**

## Com uma sessão esperando

Reinicie o servidor e busque. Depois, offline, acrescente uma sessão de espanhol, enquanto outro
celular apaga `s3` e o servidor esquece; depois busque:

```
ana@dev:~/planner/resync$ rm planner.db
ana@dev:~/planner/resync$ node device.ts pull
delta: 6 changes, cursor 6
ana@dev:~/planner/resync$ node device.ts add s9 spanish 2026-10-27 30
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 6 is older than 7; resync
snapshot: 5 sessions, 453 bytes; 1 pending carried over
ana@dev:~/planner/resync$ node device.ts show
s1   2026-10-19  spanish     30 min
s2   2026-10-20  statistics  45 min
s4   2026-10-22  spanish     30 min
s5   2026-10-26  statistics  60 min
s9   2026-10-27  spanish     30 min  waiting to send
s6   2026-10-28  guitar      20 min
cursor 7
```

O snapshot trouxe cinco sessões, e uma operação pendente foi levada junto. `s9` está na tela e ainda
`waiting to send`, e a próxima drenagem a envia como se nenhuma ressincronização tivesse acontecido,
o que, para a caixa de saída, é verdade. Os dois tipos de verdade ficaram separados: o snapshot
decidiu o que o servidor tem, e a caixa de saída decidiu o que a pessoa fez desde então.

## Onde fica mais difícil

A operação pendente foi aplicada *por cima* do snapshot, o que está certo para um create que o
servidor nunca viu. É uma escolha, não uma lei, a partir do momento em que os dois lados mexeram na
mesma linha. Se a pessoa alongou `s5` enquanto estava fora, e outro celular apagou `s5` nesse meio
tempo, o snapshot diz que `s5` não existe e a caixa de saída diz que ela agora tem 90 minutos.
Aplicar a caixa de saída a traz de volta; descartá-la joga fora a edição da pessoa. Isso é um
conflito, e as aulas 13 a 15 são três jeitos de resolver um. A ressincronização não o resolve; **ela
só não pode escondê-lo**, e é por isso que guarda a operação em vez de decidir pela pessoa.
