---
title: Pré-filtragem
version: 1
---

A outra ordem é filtrar primeiro e buscar só no que passa. Isso é a **pré-filtragem**
(pre-filtering), e ela tem a propriedade que falta à pós-filtragem: **devolve k resultados sempre
que k linhas passam no filtro**, e eles são os k mais próximos dessas linhas. `pre_filter`, em
`store.py`, fez isso em três linhas, e achou três artigos em português onde a pós-filtragem não
achou nenhum.

O preço é o que a aula 11 pôs em toda busca exata: o tempo é proporcional ao número de linhas
buscadas. Quando o filtro é estreito, isso é um presente, porque o filtro já jogou fora a maior parte
da coleção. Quando o filtro deixa passar a maior parte das linhas, um pré-filtro é uma busca de força
bruta sobre quase tudo, sem índice para ajudar.

## Quanto custa, medido

`prefilter_cost.py` cria 200.000 vetores aleatórios, marca uma linha em 100 como `pt`, uma em 10 como
`es` e o resto como `en`, e mede uma consulta exata pré-filtrada para cada idioma:

```schooling-example
{
  "language": "python",
  "file": "prefilter_cost.py",
  "parts": [
    {
      "code": "import timeit\nimport numpy as np\n\nrng = np.random.default_rng(17)\nN = 200_000\nD = rng.standard_normal((N, 384), dtype=np.float32)\nD /= np.linalg.norm(D, axis=1, keepdims=True)\nrow = np.arange(N)\nlang = np.where(row % 100 == 0, \"pt\", np.where(row % 10 == 1, \"es\", \"en\"))\nq = D[7]",
      "note": "200.000 vetores aleatórios de comprimento 1, e um idioma para cada linha decidido pelo número dela: uma em 100 `pt`, uma em 10 `es`, o resto `en`."
    },
    {
      "code": "def pre_filter(value, k=10):\n    allowed = np.flatnonzero(lang == value)\n    scores = D[allowed] @ q\n    top = np.argpartition(-scores, k)[:k]\n    return allowed[top[np.argsort(-scores[top])]]",
      "note": "O pré-filtro como busca exata sobre as linhas que passam: `argpartition` acha os `k` melhores sem ordenar o resto, e só esses `k` são ordenados."
    },
    {
      "code": "for value in (\"pt\", \"es\", \"en\"):\n    seconds = min(timeit.repeat(lambda: pre_filter(value), number=1, repeat=20))\n    print(f\"lang = {value!r}: {np.sum(lang == value):7,} rows searched  {seconds * 1000:6.1f} ms\")",
      "note": "Meça uma consulta para um filtro que deixa 1% das linhas, um que deixa 10% e um que deixa 89%, o melhor de 20 execuções cada."
    }
  ],
  "output": "ana@lab:~/emb$ python prefilter_cost.py\nlang = 'pt':   2,000 rows searched     0.7 ms\nlang = 'es':  20,000 rows searched     4.5 ms\nlang = 'en': 178,000 rows searched    83.3 ms"
}
```

**Buscar nas 2.000 em português levou 0,7 ms; buscar nas 178.000 em inglês levou 83,3 ms.** O mesmo
código, a mesma máquina, mais de cem vezes o tempo para 89 vezes as linhas. Essa é a forma a
lembrar: o custo de um pré-filtro acompanha o tamanho do que passa.

Então as duas ordens falham em lugares opostos. **A pós-filtragem falha quando o filtro é
estreito**: devolve linhas de menos. **A pré-filtragem é lenta quando o filtro é largo**: é exata e
busca linhas demais. Um filtro que deixa passar 1% das linhas pede o pré-filtro, um que deixa passar
quase todas perde pouco com um pós-filtro, e os casos difíceis ficam no meio.

## Pré-filtragem dentro do PostgreSQL

O PostgreSQL decide a ordem sozinho, pelas estimativas de custo, e a seção de pós-filtragem o viu
escolher o índice e filtrar depois. Duas coisas o fazem mudar de ideia.

**Desligar o índice vetorial para a consulta** deixa ao planejador uma varredura que filtra todas as
linhas e depois ordena as que passam pela distância: um pré-filtro exato. A aula 16 usou `SET
enable_indexscan = off` com o mesmo objetivo, e é uma boa escolha quando você sabe que o filtro é
estreito.

**Um índice parcial** é um índice HNSW só sobre as linhas que passam numa condição, criado com um
`WHERE` no `CREATE INDEX`. O planejador o usa em consultas com a mesma condição, e como toda linha
dele já passa, não sobra nada para filtrar:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON messages USING hnsw (embedding vector_cosine_ops) WHERE lang = 'pt'"
CREATE INDEX
ana@lab:~/emb$ psql -f ten.sql
 query_row | pt | es 
-----------+----+----
         1 | 10 |  6
         2 | 10 |  3
         3 | 10 |  3
         4 | 10 |  2
         5 | 10 |  2
         6 | 10 |  4
         7 | 10 |  3
         8 | 10 |  3
(8 rows)
```

**Toda linha de consulta recebeu as suas 10 linhas em português.** A coluna do espanhol não mudou,
porque o índice novo só cobre `lang = 'pt'`; as consultas em espanhol continuam passando pelo índice
completo e pelo filtro dele. Um índice parcial é mais um índice para construir e manter atualizado
para cada valor que você der a ele, então ele combina com um campo de poucos valores que importam,
como um idioma ou um status, e não com um que tenha um valor por cliente. A seção sobre clientes
desta aula volta a isso.

O PostgreSQL também oferece o **particionamento**, uma tabela dividida pelo valor de uma coluna em
tabelas menores, cada uma com o próprio índice. Ele faz o mesmo trabalho numa escala maior, e não
foi executado aqui.
