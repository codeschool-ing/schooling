---
title: Três estados em que uma linha pode estar
version: 1
---

**Quando o aparelho guarda a verdade primeiro, toda linha tem um segundo fato sobre ela além do
dado: se o servidor já a tem.** O planner grava esse fato na própria linha, na coluna `sync`, com
um de três valores.

| estado | o que significa | o que a tela diz |
|---|---|---|
| `pending` | gravada aqui, ainda não aceita pelo servidor | `waiting to send` |
| `synced` | o servidor a aceitou | `saved` |
| `failed` | o servidor respondeu, e a resposta foi não | `not saved:` e o motivo |

Um atalho comum é um booleano só, `dirty`, ligado numa mudança e desligado depois de um envio. Ele
não distingue `failed` de `pending`, então uma sessão que o servidor recusou é reenviada para sempre
e parece, para a pessoa, só uma sessão lenta. **Uma recusa é uma resposta, e a linha precisa
guardá-la.** A coluna `error` guarda o que o servidor disse, para a tela poder repetir.

A restrição `check` do `store.ts` importa pelo mesmo motivo. Um erro de digitação como `'synched'`
em algum código futuro seria gravado, não bateria com nenhuma consulta e deixaria uma linha que
nenhuma tela conta como pendente e nenhuma sincronização envia.

## Enviar, com e sem rede

`app.ts sync offline` é o app percebendo que não há rede: ele olha o que está pendente e deixa como
está. `sync online` envia cada linha pendente ao servidor de mentira, que recusa uma sessão com mais
de 240 minutos, a regra que o servidor de um planner de verdade manteria. Adicione mais uma sessão,
de 300 minutos, e rode os dois:

```
ana@dev:~/planner/offline$ node app.ts add s8 statistics 2026-10-24 300
added s8
ana@dev:~/planner/offline$ node app.ts sync offline
s7: no network, still pending
s8: no network, still pending
ana@dev:~/planner/offline$ node app.ts sync online
s7: accepted
s8: refused, a session is at most 240 minutes
ana@dev:~/planner/offline$ node app.ts week 2026-10-19
2026-10-19  spanish     30 min  saved
2026-10-20  statistics  45 min  saved
2026-10-21  guitar      20 min  saved
2026-10-22  spanish     30 min  saved
2026-10-23  guitar      25 min  saved
2026-10-24  statistics 300 min  not saved: a session is at most 240 minutes
```

Três coisas aconteceram, e vale dizer cada uma em voz alta.

- **Offline, nada mudou.** As linhas continuam `pending`, o que é verdade, e a pessoa pode seguir
  trabalhando.
- **Online, `s7` virou `synced`.** O dado dela não mudou; só o fato sobre o servidor.
- **`s8` virou `failed`, e continuou na tela.** O planner não a apagou. A sessão é da pessoa,
  digitada por ela, e a recusa do servidor não a faz sumir; faz dela algo a corrigir.

## O que "synced" não promete

`synced` quer dizer que o servidor aceitou esta versão da linha. Não quer dizer que a linha é igual
à do servidor agora: outro aparelho pode tê-la mudado desde então. Esse é o assunto das aulas 11 a
15, e o estado acima é de onde elas partem. A próxima seção é sobre a metade da pessoa: o que a
tela diz enquanto uma linha está `pending`, e o que ela diz quando uma vira `failed` uma hora depois
de a pessoa digitá-la.
