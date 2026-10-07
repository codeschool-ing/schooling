---
title: Aquecendo um cache frio
version: 1
---

Toda correção até aqui supunha que existia uma cópia, ou que tinha acabado de existir. **Um cache que
começa vazio**, um servidor novo, um reinício do Memcached, um `FLUSHALL` por engano, não tem cópia
velha para servir nem nada para atualizar antes. Toda página popular é um estouro ao mesmo tempo, e o
banco recebe todos.

**Aquecer** enche o cache antes de os visitantes chegarem, e a parte importante é a palavra *antes*:

```schooling-example
{"language": "python", "file": "warm.py", "parts": [{"code": "import sys\nimport time\n\nimport catalogue\nfrom bookcache import get_book\n\nstart = time.perf_counter()\nfor book_id in map(int, sys.argv[1:]):\n    get_book(book_id)\nms = (time.perf_counter() - start) * 1000\nprint(f\"warmed {len(sys.argv) - 1} books in {ms:.0f} ms, {catalogue.queries} queries, one at a time\")\n", "note": "Busca os livros nomeados na linha de comando, um por vez."}]}
```

```
ana@web:~/work$ redis-cli FLUSHALL && redis-cli DBSIZE
OK
0
ana@web:~/work$ python3 warm.py $(seq 1 12)
warmed 12 books in 1455 ms, 12 queries, one at a time
ana@web:~/work$ python3 stampede.py 50 bookcache --keep
bookcache, readers at once: 50, database queries: 0, 15 ms
```

O cache começou vazio. O `warm.py` buscou os doze livros, **um por vez**, em cerca de um segundo e meio;
depois cinquenta leitores encontraram o livro 2 esperando e o banco não respondeu a nenhum. Um por vez é
a questão: doze consultas em sequência são uma carga que o banco mal nota, e as mesmas doze como um
estouro de visitantes de verdade são a carga que esta aula vem evitando.

Quais páginas aquecer é uma pergunta que a própria história da loja responde:

- **As páginas mais lidas**, pelo log de acesso: os logs da aula 1 já nomeiam toda URL e quantas vezes
  ela foi pedida.
- **O que um deploy está para invalidar**, quando o número de versão da aula 10 está para mudar: aqueça
  as chaves da próxima versão, depois mude a versão.
- **Não tudo.** Aquecer um milhão de itens raramente lidos enche a memória de valores que ninguém quer,
  e uma política de despejo vai jogá-los fora de novo.

E onde aquecer não é possível, **deixe o tráfego entrar devagar**: um servidor novo posto no
balanceador com peso baixo, o `weight=` da aula 2, enche o cache a partir de um fio e não de uma
enxurrada.
