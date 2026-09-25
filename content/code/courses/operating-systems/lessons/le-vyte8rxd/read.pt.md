---
title: Lendo um arquivo sem abri-lo inteiro
version: 1
---

```
ana@server:~/work$ cat clients.csv
id,name,city
1,Acme Ltd,Sao Paulo
2,Bravo & Filhos,Campinas
3,Casa Verde,Santos
ana@server:~/work$ wc -l backup.log clients.csv
 240 backup.log
   4 clients.csv
 244 total
ana@server:~/work$ head -3 backup.log
2026-09-01 09:00 backup ok
2026-09-01 09:01 backup ok
2026-09-01 09:02 backup ok
ana@server:~/work$ tail -2 backup.log
2026-09-24 09:58 backup ok
2026-09-24 09:59 backup ok
ana@server:~/work$ grep -c ok backup.log
240
```

- O **`cat`** imprime o arquivo inteiro. Serve para um curto, como a lista de clientes de quatro linhas.
- O **`wc -l`** conta as linhas antes: o log tem **240**. Ninguém lê 240 linhas para saber se o backup
  de ontem rodou.
- O **`head`** mostra o começo e o **`tail`** o fim. O `tail -2` respondeu a pergunta de verdade, os dois
  últimos backups, em duas linhas.
- O **`grep -c ok`** contou as linhas que têm `ok`: todas as 240. Um log em que essa conta é menor que o
  número de linhas tem uma falha, e o `grep` sem `-c` imprimiria quais linhas.

Mais dois para trabalhos mais longos: o **`less`** abre um arquivo para rolar, buscar com `/` e sair com
`q`, e o **`tail -f`** continua imprimindo as linhas novas conforme um programa as escreve, que é como se
acompanha um log enquanto algo está sendo testado. A aula 17 usa os dois nos logs do próprio sistema.
