---
title: O banco de dados
version: 1
---

O `Server-Timing` pôs quase toda a consulta a um espetáculo no banco, e o `top` mostrou o servidor
ocupando os processadores. A consulta é a que conta os assentos vendidos:

```sql
SELECT count(*) FROM bookings WHERE show_id = ?
```

Um banco de dados diz como pretende rodar uma consulta antes de rodá-la. No SQLite isso é o
`EXPLAIN QUERY PLAN`, e o `sqlite3`, instalado na aula 1, pergunta pela linha de comando:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"
QUERY PLAN
`--SCAN bookings
```

**`SCAN bookings` quer dizer que toda linha da tabela é lida**, todas as quase trezentas mil, para
contar as que pertencem a um espetáculo, e isso acontece a cada requisição. Nada nisso está errado
no sentido que um teste funcional consegue ver: a contagem está certa. Ela é lenta na proporção do
tamanho da tabela, e a tabela cresce toda vez que alguém reserva.

A cura para uma varredura que só quer poucas linhas é um **índice**: uma cópia ordenada de uma coluna com um ponteiro para cada linha. Com ele, as linhas de um espetáculo são achadas como
uma palavra num dicionário, sem ler o resto. Crie um sobre `show_id`, peça o plano de novo e
consulte um espetáculo:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_by_show ON bookings (show_id)"
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"
QUERY PLAN
`--SEARCH bookings USING COVERING INDEX bookings_by_show (show_id=?)
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=0.2, pay;dur=0.0, total;dur=0.5
```

O plano agora diz `SEARCH bookings USING COVERING INDEX bookings_by_show (show_id=?)`. `SEARCH`
quer dizer que ele vai direto às linhas que quer; `COVERING` quer dizer que o índice sozinho tem
tudo o que a consulta precisa, então a tabela nem é lida. O tempo de banco de uma requisição caiu
de 10.2 ms para 0.2 ms.

## A mesma carga, depois

Uma requisição é uma pista. A afirmação que importa é a que vale sob carga, então rode os mesmos
oito workers pelos mesmos doze segundos:

```
ana@nft:~/boxoffice$ python3 measure.py 8 12 | head -4
8 workers, 13.0 s: 8532 requests, 656.4 per second
status: 200 x8532
ms          count    mean  median     p90     p95     p99     max
all          8532    11.4     8.6    13.6    15.7    23.7  1047.2
```

| | antes | depois |
|---|---|---|
| requisições por segundo | 183.5 | 656.4 |
| mediana | 41.4 ms | 8.6 ms |
| p95 | 74.2 ms | 15.7 ms |
| p99 | 92.5 ms | 23.7 ms |

**Cerca de três vezes e meia a vazão, e um p95 quase cinco vezes menor**, com uma linha de SQL.
Esse é o tamanho comum de um índice que falta, e por isso ele é a primeira coisa a procurar quando
o banco domina o tempo. Todo banco tem a sua forma do plano: `EXPLAIN` no MySQL, `EXPLAIN ANALYZE`
no PostgreSQL, que também roda a consulta e informa o que ela fez de verdade.

Um número da nova execução não se encaixa: o máximo, 1047.2 ms, mais de quarenta vezes o p99. Uma
requisição esperou cerca de um segundo, e o banco não pode ter causado isso, já que toda consulta
agora leva uma fração de milissegundo. "Rede e infraestrutura" descobre para onde foi esse
segundo.

Um índice não é de graça. Ele ocupa espaço em disco, e toda reserva agora grava a linha e a
entrada do índice. **Numa tabela lida muito mais do que escrita, como esta, a troca vale a pena.** Numa tabela escrita o tempo todo e quase nunca lida, pode ser o contrário, e um teste de
carga das escritas é como você descobre. Num projeto de verdade o índice iria para o esquema, onde
todo banco novo o recebe. Aqui ele vive só na sua cópia do arquivo, e `python3 seed.py` monta o
banco de novo sem ele, que é como você recupera a versão lenta.
