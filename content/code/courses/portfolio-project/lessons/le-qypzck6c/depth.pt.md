---
title: Como a profundidade aparece num histórico
version: 1
---

Profundidade não é uma contagem de funcionalidades. É o momento num projeto em que algo deu errado ou
ficou difícil e quem fez decidiu o que fazer. Um tutorial nunca tem esse momento, porque o tutorial
removeu todos antes de você chegar.

O loanbook tem um logo no começo. Aqui estão os cinco commits entre os seus dois primeiros marcos, as
tags da aula 7:

```
ana@laptop:~/loanbook$ git log --oneline v0.1.0..v0.2.0
5e90846 Mark a loan overdue the day after it is due
946c9a3 Say what to do when there is nothing to lend
b7f4c5f Answer every error as JSON
55012ed Test the loan rules
2fb7c61 Refuse to lend an item that is already out
```

O log lista os mais novos primeiro, então o mais antigo dos cinco está embaixo, e é esse que um
tutorial não teria. Aqui está ele inteiro:

```
ana@laptop:~/loanbook$ git show --stat 2fb7c61
commit 2fb7c61d4803b708129010e93072f67369b02445
Author: Ana Lima <ana@example.org>
Date:   Tue Jun 9 10:10:00 2026 -0300

    Refuse to lend an item that is already out
    
    Two people could lend the same projector from two browsers, and the
    list then showed it twice. A partial unique index allows one open loan
    per item, so the database refuses the second one even when both
    requests arrive together. The handler turns that refusal into a 409
    with a sentence the page shows.
    
    Closes #3

 app.py        | 58 +++++++++++++++++++++++++++++++++++++++++++++-------------
 static/app.js |  3 ++-
 2 files changed, 47 insertions(+), 14 deletions(-)
```

Leia o que a mensagem faz. Ela nomeia **uma falha que aconteceu de verdade**: dois navegadores
conseguiam emprestar o mesmo projetor, e a lista mostrava ele duas vezes. Nomeia **a decisão**: deixar o
banco recusar o segundo empréstimo por meio de um índice único parcial. Diz **por que ali e não no código**: o banco
recusa mesmo quando as duas requisições chegam juntas, o que uma verificação em Python, lendo
"disponível" duas vezes, não faria. E liga a mudança à issue que a pediu.

Quem contrata e encontra esse commit encontrou a conversa que quer ter com você. A mudança em si é
pequena, dois arquivos. A profundidade está no que a mensagem diz sobre como você pensa, e não custou nada
além de escrever no dia.
