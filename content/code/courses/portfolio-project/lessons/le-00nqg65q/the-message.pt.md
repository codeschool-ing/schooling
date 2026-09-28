---
title: Um assunto, uma linha em branco, um motivo
version: 1
---

Uma mensagem de commit tem duas partes, e o git as trata de forma diferente. O **assunto** é a primeira
linha: é o que `git log --oneline` mostra, o que um pull request usa como título, o que quem avalia passa
os olhos. Depois **uma linha em branco**, e depois o **corpo**, tão longo quanto precisar, para quem abre o
commit.

```
Refuse to lend an item that is already out

Two people could lend the same projector from two browsers, and the
list then showed it twice. A partial unique index allows one open loan
per item, so the database refuses the second one even when both
requests arrive together. The handler turns that refusal into a 409
with a sentence the page shows.

Closes #3
```

Esse é o commit 2fb7c61, e ele segue as convenções que a maioria dos projetos usa:

| parte | convenção | por quê |
|---|---|---|
| assunto | umas 50 letras, imperativo, sem ponto final | cabe em toda ferramenta que mostra uma linha |
| linha em branco | sempre | as ferramentas a usam para separar assunto de corpo |
| corpo | quebrado em umas 72 colunas | lê bem num terminal e num e-mail |
| conteúdo do corpo | **por quê**, e o que foi considerado | o diff já diz o quê |
| última linha | *Closes #N* ou *refs #N* | aula 8 |

A regra que mais importa é a quarta. **O diff mostra o que mudou; só a mensagem diz por quê.** *Add unique
index on loans* repete o diff. *Um índice único parcial permite um empréstimo aberto por item, então o
banco recusa o segundo mesmo quando as duas requisições chegam juntas* diz por que ele está ali e por que
ali, e ninguém lendo só o diff conseguiria reconstruir isso.

Nem todo commit precisa de corpo. *Fit the table on a phone* tem duas linhas e não precisa de mais. O corpo
é para os commits em que quem lê de outro modo perguntaria *por quê?*, e são justamente esses que quem
avalia abre.
