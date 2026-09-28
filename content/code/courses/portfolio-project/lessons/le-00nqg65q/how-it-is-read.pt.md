---
title: Como quem avalia lê um histórico
version: 1
---

Quem avalia não lê vinte commits de cima a baixo. Faz amostra, como a aula 1 disse, e um bom histórico dá
lugares por onde começar.

**Os assuntos, num intervalo.** Entre duas tags, o log é a história de um marco, com as datas:

```
ana@laptop:~/loanbook$ git log --format='%h %ad %s' --date=short v0.2.0..v0.3.0
09f10f8 2026-06-29 Deploy with systemd and Caddy
ca4540f 2026-06-26 Build and run in a container
40303b1 2026-06-25 Answer /healthz so a monitor can ask
ff1a9d1 2026-06-24 Read the database path and port from the environment
69aa266 2026-06-22 Refuse a borrower made of spaces
be0bfbb 2026-06-18 Fit the table on a phone
a087fae 2026-06-17 Label every field and announce what happened
```

**Um commit inteiro**, em geral o de assunto mais interessante. `git show` dá a mensagem e o diff juntos;
quem avalia lê a mensagem e confere que o diff faz o que ela diz. Se faz, confia nos outros assuntos sem
abri-los.

**As ligações**, se houver: um `Closes #3` leva à issue e à discussão dela, aula 8.

Três coisas para garantir antes que alguém leia:

- **Nenhum commit quebra o build.** Quem avalia e faz checkout de uma tag ou de um commit do meio espera
  que rode. Um histórico em que um commit sim, um não, falha nos testes diz que os testes rodaram uma vez,
  no fim.
- **Nenhum segredo, e nenhuma depuração, em nenhum commit.** Apagar uma chave num commit posterior não a
  remove do anterior; a aula 14 trata disso.
- **O seu nome e o seu e-mail são os que você quer ali.** Todo commit os carrega, publicamente; a aula 18
  mostra como usar um endereço sem resposta.

Um histórico que passa nessas três e se lê como o desta aula é evidência daquilo que uma equipe mais quer
saber sobre alguém novo: **como é o trabalho dessa pessoa quando ninguém está olhando.**
