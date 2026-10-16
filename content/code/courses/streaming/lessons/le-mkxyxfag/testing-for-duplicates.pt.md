---
title: Testando um consumidor contra duplicatas
version: 1
---

**O teste para um consumidor que se diz idempotente é rodá-lo duas vezes sobre a mesma entrada e
comparar o que ele deixa para trás.** Se a segunda execução muda alguma coisa, a afirmação é falsa. É
um teste curto, e ele pega o defeito que mais importa nesta lição, porque uma duplicata em produção é
invisível até alguém contar a prateleira.

A entrada é o tópico, que guarda o que recebeu, então relê-lo sai de graça. A saída é o que o
consumidor grava; aqui, as linhas de `stock`, despejadas num arquivo depois de cada execução e
comparadas com `diff`, que não imprime nada quando dois arquivos são iguais.

## O destino com deduplicação

```
ubuntu@stream:~/work$ rm stock.db
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt
ubuntu@stream:~/work$ python stock_sink.py --dedup --replay
applied 0 sales, skipped 40 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt
ubuntu@stream:~/work$ diff run1.txt run2.txt && echo identical
identical
```

A segunda execução não aplicou nada e os dois despejos são iguais: o `diff` não imprimiu nada, então o
`echo` rodou e imprimiu `identical`.

## O destino sem ids

O mesmo teste contra a versão que só subtrai:

```
ubuntu@stream:~/work$ rm stock.db
ubuntu@stream:~/work$ python stock_sink.py --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run1.txt
ubuntu@stream:~/work$ python stock_sink.py --replay
applied 40 sales, skipped 0 already seen
ubuntu@stream:~/work$ python -m sqlite3 stock.db "SELECT * FROM stock ORDER BY book" > run2.txt
ubuntu@stream:~/work$ diff run1.txt run2.txt && echo identical
1,8c1,8
< ('bk-01', 90)
< ('bk-02', 97)
< ('bk-03', 97)
< ('bk-04', 91)
< ('bk-05', 92)
< ('bk-06', 87)
< ('bk-07', 87)
< ('bk-08', 88)
---
> ('bk-01', 80)
> ('bk-02', 94)
> ('bk-03', 94)
> ('bk-04', 82)
> ('bk-05', 84)
> ('bk-06', 74)
> ('bk-07', 74)
> ('bk-08', 76)
```

O `diff` imprime todas as linhas, porque o estoque de todo livro mudou: `bk-01` de 90 para 80,
`bk-06` de 87 para 74. **O teste falha no primeiro segundo**, exatamente no defeito que de outro jeito
apareceria como uma prateleira que discorda do site.

## O que mais o teste deveria fazer

Rodar duas vezes sobre a mesma entrada é o mínimo. As falhas que as lições 7 e 8 mostraram são cada uma
mais um caso para a mesma comparação:

- **uma queda no meio**: parar o consumidor num ponto dentro de um lote, começar de novo e comparar
  com uma execução que nunca parou. As duas execuções com `--crash-after` desta lição são esse teste
  feito à mão;
- **uma duplicata na entrada**: gravar o mesmo evento duas vezes no tópico, como faria uma nova
  tentativa do produtor, e comparar com a saída da entrada sem ela;
- **reordenação**: para um destino que guarda versões, entregar uma versão antiga depois de uma nova e
  conferir que a nova continua.

Cada um são poucas linhas no framework de testes que a equipe usar, e cada um falha alto num
consumidor que de outro jeito ficaria errado por algumas cópias de um livro, em silêncio, para sempre.
A lição 16 volta ao reprocessamento, que é esta mesma releitura feita de propósito em produção.
