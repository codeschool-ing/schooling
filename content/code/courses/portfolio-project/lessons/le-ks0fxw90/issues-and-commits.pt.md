---
title: Do cartão ao commit
version: 1
---

Um quadro merece lugar num portfólio quando está **ligado ao código**. Quem avalia e lê um commit consegue
então voltar até o cartão, e do cartão até o motivo de o trabalho ter sido feito. A ligação é uma linha no
fim da mensagem de commit:

```
ana@laptop:~/loanbook$ git log --format='%h %s%n%b' --grep='Closes #'
5e90846 Mark a loan overdue the day after it is due
Closes #5

2fb7c61 Refuse to lend an item that is already out
Two people could lend the same projector from two browsers, and the
list then showed it twice. A partial unique index allows one open loan
per item, so the database refuses the second one even when both
requests arrive together. The handler turns that refusal into a 409
with a sentence the page shows.

Closes #3
```

`git log --grep` lista os commits cuja mensagem casa com um padrão, e estes são os dois do loanbook que
fecham uma issue. No GitHub e no GitLab, um commit ou pull request que diz **`Closes #3`** fecha a issue 3
quando chega ao branch padrão, e cada lado aponta para o outro: a issue mostra o commit que a fechou, e o
commit leva à issue.

Para um portfólio isso faz três coisas. **Mostra que o trabalho foi planejado**, não improvisado: o cartão
existia antes do código. **Mantém a discussão num lugar só**: se a issue diz por que o índice foi para o
banco e não para o código, a mensagem de commit pode ser curta e ainda assim ser entendida. E **dá um
índice ao histórico**: quem quer ver como a coisa única foi construída abre a issue 3 e tem o commit, o
teste e a discussão a um clique.

Use a palavra-chave só no commit que termina o cartão. Um commit que é parte do trabalho pode dizer *refs
#3*, que liga sem fechar.
