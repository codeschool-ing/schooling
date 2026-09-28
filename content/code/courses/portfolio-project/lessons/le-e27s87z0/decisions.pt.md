---
title: As decisões, com os custos
version: 1
---

A seção que mais faz por um portfólio é a que a maioria dos READMEs não tem. É onde a segunda prova da aula
1, *você decide*, vira algo que quem avalia consegue ler:

```
ana@laptop:~/loanbook$ sed -n '/^## Decisions/,/^## Not yet/p' README.md
## Decisions

- **The database refuses a second loan, not the code.** A partial unique
  index allows one open loan per item, so two people pressing Lend at the same
  moment cannot both succeed. A check in Python would read "available" twice
  and write two loans.
- **SQLite, not a database server.** One room, a few dozen items, one server:
  a file is enough, and a backup is a copy of it. If several schools shared
  one instance, this is the first thing to change.
- **No accounts.** The borrower is a name typed in. Everybody who uses it works
  in the same building, and a login would have doubled the first version. The
  cost is that anybody who can open the page can lend.
- **The standard library only.** Nothing to install or upgrade; the price is
  about fifteen lines of routing written by hand.

## Not yet
```

Quatro decisões, e todas têm as mesmas três partes. **O que foi decidido**, em negrito, nas primeiras
palavras. **Por quê**, nos termos dos fatos deste projeto: uma sala, algumas dezenas de itens, um servidor,
todo mundo no mesmo prédio. **O que custa**, ou quando deixaria de estar certo: *se várias escolas
dividissem uma instância, esta é a primeira coisa a mudar*; *qualquer pessoa que abra a página pode
emprestar*.

A terceira parte é a que a aula 6 insistiu, e é a que torna a seção crível. Uma lista de escolhas só com
motivos se lê como uma lista de coisas de que você gosta. Com os custos, se lê como critério, porque mostra
que você sabia do que estava abrindo mão.

Duas a quatro decisões é o número certo. Escolha as que quem avalia perguntaria de outro modo: a escolha
incomum, *sem framework*; a que tem limite visível, *SQLite*; a que parece uma falta, *sem contas*; e a que
é o ponto do projeto, *o banco recusa*. Cada uma é também uma pergunta para a qual você agora está pronto
na aula 20, porque escreveu a resposta antes de alguém perguntar.
