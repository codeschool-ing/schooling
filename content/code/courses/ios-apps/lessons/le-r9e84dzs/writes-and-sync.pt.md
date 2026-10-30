---
title: Escrever no aparelho, e enviar depois
version: 1
---

**Uma escrita que espera o servidor é uma escrita que falha no trem.** Então o `add` do repositório
faz o contrário do que o `fetch` da aula 12 fazia: põe a sessão no aparelho, na lista de sessões
pendentes, salva o arquivo, e só então tenta enviá-la. Se o envio funciona, a sessão passa de
pendente para confirmada. Se não funciona, a sessão continua pendente e a pessoa a vê no plano assim
mesmo.

A segunda metade do repositório, na listagem da seção 04, são esses dois métodos. O `add` confere a
sessão contra o plano que o aparelho tem, a acrescenta em `pending`, salva e chama o `sync`. O `sync`
percorre a lista de pendentes e envia cada sessão. **A lista é a promessa**: enquanto uma sessão está
nela, o aparelho não ouviu que o servidor a tem.

## Acrescentando sem servidor

O servidor continua parado desde a seção 04. Acrescente uma sessão:

```
ana@vm:~/planner$ .build/debug/repo add s5 mobile 2026-10-22 30
added s5 on the device
2 courses, 5 sessions, 1 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
ana@vm:~/planner$ grep -A8 "\"pending\"" planner.json
  "pending" : [
    {
      "courseId" : "mobile",
      "date" : "2026-10-22",
      "done" : false,
      "id" : "s5",
      "minutes" : 30
    }
  ],
```

O plano agora tem cinco sessões, uma delas esperando, e o total da semana já a conta: 180 minutos
planejados. O arquivo diz exatamente o que o aparelho sabe, e a lista `pending` nele é a parte que
importa. É a mesma grafia `courseId` que o servidor usa, porque o arquivo reaproveita os tipos de fio
da aula 12.

## A rede volta

Inicie o servidor de novo e rode o `sync`. Num app isso aconteceria sozinho, quando o app volta ao
primeiro plano ou a rede volta; a aula 16 trata de quando o iOS deixa isso acontecer em segundo plano
também.

```
ana@vm:~/planner$ .build/debug/repo sync
synced
2 courses, 5 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
```

**Nada está esperando, e o terminal do servidor mostra o `POST /sessions` que a trouxe**: a sessão que
o aparelho tinha guardado chegou. O plano não mudou, porque do lado da pessoa nada aconteceu: a sessão
estava no plano antes, e está no plano agora.

## Duas escritas que não são o mesmo erro

Nem todo envio que falhou deve ser guardado. O `catch` do `sync` separa dois tipos:

| o que voltou | o que quer dizer | o que o `sync` faz |
|---|---|---|
| `offline`, `cancelled`, ou um `5xx` | o servidor não a recebeu desta vez | a mantém pendente, para tentar de novo |
| um `4xx`, como `422 no course art` | o servidor nunca vai recebê-la | a descarta, e devolve o id dela |

Uma sessão que o servidor recusa de vez ficaria para sempre em `pending` e seria enviada a cada
sincronização, e a pessoa a veria num plano onde ela nunca pode ser confirmada. Devolver o id dela é
como a tela fica sabendo e consegue dizer isso. A seção 07 faz os dois casos acontecerem.
