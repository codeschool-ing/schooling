---
title: O índice vetorial
version: 1
---

Uma tabela de vetores já pode ser buscada: ordenar as linhas pela distância à pergunta e pegar as
primeiras. O PostgreSQL faz isso calculando a distância a cada linha, o que para 137 pedaços não leva
tempo nenhum e para dez milhões leva tempo demais para esperar. Um **índice** torna a busca aproximada e
rápida, e as aulas 15 e 16 do `embeddings-vectors` mediram como: o que o HNSW constrói, o que `m`,
`ef_construction` e `ef_search` trocam, e como a revocação cai à medida que a velocidade sobe. Esta seção
só acrescenta o índice à tabela e confere que o planejador o usa.

```
ana@lab:~/rag$ psql -c "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"
CREATE INDEX
ana@lab:~/rag$ psql -c "SET enable_seqscan = off" -c "EXPLAIN (COSTS OFF) SELECT path FROM chunks ORDER BY embedding <=> (SELECT embedding FROM chunks LIMIT 1) LIMIT 3"
SET
                      QUERY PLAN                       
-------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Limit
           ->  Seq Scan on chunks chunks_1
   ->  Index Scan using chunks_embedding_idx on chunks
         Order By: (embedding <=> $0)
(6 rows)
```

**O `vector_cosine_ops` combina com o operador que a busca usa**, `<=>`, a distância de cosseno; um
índice construído para um operador é ignorado por uma consulta que ordena por outro, sem erro nenhum. O
plano mostra `Index Scan using chunks_embedding_idx`, ordenado pela distância de cosseno. O `SET
enable_seqscan = off` está ali porque com 130 linhas o planejador, com razão, prefere ler a tabela
direto; é um jeito de ver que o índice *pode* ser usado, não uma configuração para deixar ligada.

## Três fatos sobre o índice que importam para a recuperação

**Ele é aproximado.** O HNSW pode perder um vizinho mais próximo de verdade. Num corpus deste tamanho há
pouco para ele perder, e num grande a taxa de perda é o que o `ef_search` controla. Um teste de
recuperação que passa contra uma busca exata pode falhar contra o índice, e por isso a aula 8 roda seus
testes contra o mesmo índice que a produção usa.

**Ele interage com filtros.** Um `WHERE status = 'current'` combinado com um índice HNSW pode devolver
menos linhas do que o `LIMIT` pediu, porque o índice acha primeiro as linhas mais próximas e o filtro
joga algumas fora depois. A aula 17 do `embeddings-vectors` mostrou o PostgreSQL fazendo exatamente isso,
e a aula 14 deste curso encontra o problema de novo quando os filtros chegam.

**Ele é atualizado aos poucos.** Linhas inseridas depois que o índice existe entram nele à medida que
chegam; a execução noturna do `ingest.py` não precisa reconstruir nada. Linhas apagadas deixam marcas no
grafo que o `VACUUM` limpa, e numa tabela com muita rotatividade vale a pena agendá-lo.
