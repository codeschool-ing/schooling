---
title: Vinte linhas
version: 1
---

Aqui está o histórico inteiro do loanbook, do mais antigo ao mais novo:

```
ana@laptop:~/loanbook$ git log --oneline --reverse
19e36eb Say what loanbook is for
64f0369 Serve a page with nothing on it yet
8623595 List the equipment from SQLite
3227967 Lend an item to somebody
28edce4 Take an item back
2fb7c61 Refuse to lend an item that is already out
55012ed Test the loan rules
b7f4c5f Answer every error as JSON
946c9a3 Say what to do when there is nothing to lend
5e90846 Mark a loan overdue the day after it is due
a087fae Label every field and announce what happened
be0bfbb Fit the table on a phone
69aa266 Refuse a borrower made of spaces
ff1a9d1 Read the database path and port from the environment
40303b1 Answer /healthz so a monitor can ask
ca4540f Build and run in a container
09f10f8 Deploy with systemd and Caddy
0f5e8a6 Seed a week that looks real
5579396 Explain how to run it and why it is built this way
c40ef55 License under MIT
```

Leia só os assuntos e o projeto se explica. Disse para que servia, serviu uma página vazia, listou,
emprestou, recebeu de volta. Depois encontrou o problema da aula 5 e recusou um segundo empréstimo, testou
a regra, arrumou os erros, tratou a lista vazia, marcou os atrasos. Depois acessibilidade, o celular, um
bug encontrado por um teste, configuração para o container, um health check, o container, o deploy.
Depois o que o torna digno de ser mostrado.

É isso que quem avalia tira do `git log --oneline` em dez segundos, e três coisas produzem isso.

- **Cada linha é uma mudança.** Não *várias correções*, não *dia 4*. Uma coisa que se descreve numa frase,
  que é também uma coisa que dá para reverter sozinha.
- **Cada assunto diz o que o projeto faz depois do commit**, no imperativo: *refuse*, *mark*, *answer*,
  como se completasse a frase *este commit vai…*. É a convenção do próprio git, e é por isso que as
  mensagens que o git gera dizem *Merge branch…* e *Revert…*. Em português vale o mesmo: *recusa*,
  *marca*, *responde*, ou o infinitivo, desde que o projeto inteiro use um só.
- **A ordem é a ordem do trabalho.** Nada aqui foi reordenado para ficar bonito. O commit de acessibilidade
  vem depois das regras porque foi quando ele foi feito, e quem avalia consegue ver.

Compare com o histórico que isto substitui, que todo mundo já escreveu uma vez:

```
a1b2c3d fix
d4e5f6a wip
b7c8d9e more changes
e0f1a2b fix tests
c3d4e5f final
f6a7b8c final 2
```

Seis linhas, e quem avalia não sabe nada do projeto e sabe uma coisa sobre quem o fez.
