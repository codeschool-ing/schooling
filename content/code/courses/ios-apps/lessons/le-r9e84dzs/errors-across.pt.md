---
title: Falhas que atravessam a fronteira
version: 1
---

**Entre o telefone e o servidor há falhas que nenhum dos lados enxerga inteiras.** O telefone sabe que
enviou um pedido e não recebeu resposta. Ele não tem como saber se o pedido nunca chegou, ou chegou,
foi feito, e só a resposta se perdeu. Os pedidos cancelados da aula 12 mostraram o segundo caso do
lado do servidor: o trabalho foi feito para um cliente que tinha ido embora. Para uma leitura isso não
custa nada. Para uma escrita é a pergunta que esta seção responde.

## A resposta que se perdeu

O teste `anAnswerLostOnTheWayIsSentAgainAndKeptOnce` da seção 06 é exatamente isso. O falso guarda a
sessão e depois lança `timedOut`, então o repositório a mantém pendente, como deve: do ponto onde ele
está, nada foi confirmado. O próximo `sync` a envia **uma segunda vez**. Isso só é seguro por causa de
uma regra no servidor, e o `serve.py` da aula 12 a segue: **uma sessão enviada duas vezes com o mesmo
`id` é guardada uma vez.** O id é escolhido no aparelho, quando a sessão é criada, então o segundo
envio é reconhecivelmente a mesma sessão e não uma nova.

Sem essa regra, cada resposta perdida viraria uma sessão duplicada no plano, e o repositório não
conseguiria evitar isso tomando cuidado: tomar cuidado é esperar uma resposta que nunca vai chegar.
**Uma operação que dá o mesmo resultado não importa quantas vezes seja repetida se chama
idempotente**, e tornar as escritas idempotentes é a metade do servidor no offline-first. A aula 10 de
`mobile-offline` constrói a versão geral, a chave de idempotência, para pedidos que não têm um id
natural.

## A escrita que o servidor recusa

O segundo caso difícil é uma sessão que o aparelho aceitou e o servidor nunca vai aceitar: um curso
apagado no servidor enquanto o telefone estava longe. O teste
`aSessionTheServerRefusesIsDroppedAndReported` dá ao aparelho um curso chamado `art` que o falso não
tem, acrescenta uma sessão para ele, e confere que ela volta na lista de ids recusados e sai do plano.

O próprio aparelho recusa um passo antes quando pode. Rode o `repo` com um curso de que o aparelho
nunca ouviu falar, com o servidor rodando ou não:

```
ana@vm:~/planner$ .build/debug/repo add s6 art 2026-10-22 30
not added: unknownCourse("art")
2 courses, 5 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
```

**Essa recusa veio do `Plan.add` da aula 1, antes de qualquer coisa ser salva ou enviada.** O
repositório confere uma escrita contra o plano que tem; só uma escrita que passa nessa conferência
chega a `pending`, e só o servidor pode recusá-la depois disso.

## A falha no próprio aparelho

A terceira falha é o arquivo. Um disco cheio ou uma permissão revogada faz o `save` lançar, e um `add`
que engolisse isso diria à pessoa que uma sessão foi guardada quando não foi. O repositório registra o
erro em `storeError`, e o `repo` o imprime sempre que ele está preenchido. Nenhuma das execuções desta
aula o imprimiu, porque nenhuma falhou ao salvar; a linha existe para que, no dia em que uma falhar,
alguém fique sabendo.

| onde falha | o que o repositório faz | o que a pessoa vê |
|---|---|---|
| a rede, numa leitura | mantém o plano que tem | o plano, e um aviso de que ele pode estar velho |
| a rede, numa escrita | mantém a sessão pendente | a sessão, marcada como ainda não enviada |
| o servidor recusa uma escrita | a descarta e devolve o id | uma mensagem dizendo o que não foi guardado |
| o próprio arquivo do aparelho | registra `storeError` | uma mensagem de que o aparelho não conseguiu salvar |
