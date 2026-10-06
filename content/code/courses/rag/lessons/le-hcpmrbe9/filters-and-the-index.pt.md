---
title: Filtros e o índice vetorial
version: 1
---

Toda busca deste curso foi exata: o PostgreSQL compara a pergunta com cada linha que passa no `WHERE`
e devolve as mais próximas. Com os 137 pedaços da Marginalia isso é instantâneo. Com algumas centenas
de milhares, uma equipe acrescenta o índice HNSW que `embeddings-vectors` construiu, e o índice muda o
comportamento de um filtro. A aula 5 avisou disso e a aula 6 deixou para aqui.

O `index.py` roda uma busca restrita aos documentos da equipe financeira, 8 pedaços dos 137, pedindo
cinco, primeiro como varredura exata e depois com o planejador instruído a usar o índice:

```
ana@lab:~/rag$ psql -qc "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"
ana@lab:~/rag$ python index.py "When does an order get held for manual fraud review?"
sequential scan on : 5 of 5
sequential scan off: 3 of 5
ana@lab:~/rag$ psql -qc "DROP INDEX chunks_embedding_idx"
```

**Cinco linhas na exata, três pelo índice.** O índice não conhece o filtro. Ele percorre o grafo até
as poucas dezenas de vetores mais próximos, 40 por padrão no pgvector 0.6 (`hnsw.ef_search`), e o
PostgreSQL aplica o `WHERE` a esses; quando só alguns deles são pedaços do financeiro, só alguns
voltam, por mais que existam. Nada avisa da falta. A busca devolve menos linhas que o `LIMIT` pediu, e
o leitor recebe uma resposta mais magra por um motivo que nenhum registro vai mostrar.

Filtros de permissão pioram isso em relação a filtros de status, porque são mais estritos exatamente
onde importa: o leitor que pode ver um público pequeno é aquele cujos resultados o índice deixa com
fome. Três remédios, na ordem em que vale recorrer a eles:

- **Busca exata num subconjunto pequeno.** Quando o filtro deixa alguns milhares de linhas, uma
  varredura exata delas é rápida, e dá para conduzir o planejador até ela. Os 8 pedaços do financeiro
  nunca precisaram de índice.
- **Um índice parcial por público**: `CREATE INDEX … WHERE audience = 'finance'`, para que a busca do
  financeiro percorra um grafo que só contém pedaços do financeiro.
- **Um pgvector mais novo.** A versão 0.8 acrescentou varreduras iterativas no índice, que continuam
  percorrendo o grafo até linhas suficientes passarem no filtro. O laboratório fixa a 0.6.0, e essa
  configuração não existe nela.

Seja qual for o remédio, a verificação é a da aula 8, rodada com o índice no lugar: uma revocação
medida numa tabela sem índice não diz nada sobre a indexada.
