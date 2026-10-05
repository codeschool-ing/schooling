---
title: Supabase
version: 1
---

O Supabase é uma plataforma hospedada construída em volta de um banco PostgreSQL. Cada projeto
recebe um banco inteiro, e o pgvector é uma das extensões que ele oferece, então tudo das últimas
três seções funciona lá sem mudança: o mesmo tipo de coluna, os mesmos operadores, o mesmo
`CREATE INDEX`. O que muda é o jeito como uma aplicação costuma chegar até ele. **Um cliente do
Supabase não manda SQL.** Ele conversa por HTTPS com uma API que o Supabase gera a partir do seu
esquema, e essa API sabe filtrar e ordenar por colunas, mas não tem como dizer
`ORDER BY embedding <=> $1`.

**O Supabase não foi executado nesta aula.** É um serviço hospedado e esta máquina não o alcança. O
SQL abaixo é PostgreSQL puro e rodou, no banco do laboratório; o Python que o chama pela rede é
mostrado a partir da documentação do Supabase e não foi executado.

## A busca vira uma função

A resposta documentada é pôr a busca dentro de uma função SQL e chamar a função pela API. O guia de
busca semântica do Supabase a chama de `match_documents`. Aqui está o mesmo formato com a tabela
desta aula, rodado no laboratório:

```schooling-example
{
  "language": "sql",
  "file": "match.sql",
  "parts": [
    {
      "code": "CREATE FUNCTION match_articles(\n    query_embedding vector(384),\n    match_threshold float,\n    match_count int\n)\nRETURNS TABLE (id text, title text, similarity float)\nLANGUAGE sql STABLE",
      "note": "Uma função que recebe o vetor da consulta, uma similaridade mínima e um número máximo de linhas, e devolve uma tabela. É o formato que o guia de busca semântica do Supabase usa, com os nomes de tabela e coluna desta aula."
    },
    {
      "code": "AS $$\n    SELECT a.id, a.title, 1 - (a.embedding <=> query_embedding)\n    FROM articles a\n    WHERE a.embedding <=> query_embedding < 1 - match_threshold\n    ORDER BY a.embedding <=> query_embedding\n    LIMIT match_count;\n$$;",
      "note": "O corpo é a consulta de `search.py` com uma condição a mais: uma distância abaixo de um menos o limiar é uma similaridade acima dele."
    },
    {
      "code": "SELECT * FROM match_articles(\n    (SELECT embedding FROM queries WHERE id = 'q01'), 0.4, 3);",
      "note": "Chamada a partir do SQL com o vetor guardado de q01, que é a pergunta feita a `search.py`."
    }
  ],
  "output": "ana@lab:~/emb$ psql -f match.sql\nCREATE FUNCTION\n id  |          title           |     similarity     \n-----+--------------------------+--------------------\n h18 | Returning a gift         | 0.4455630513690092\n h15 | When your refund arrives | 0.4375660717487335\n(2 rows)"
}
```

**A função pediu três linhas e devolveu duas.** h22, *Charged twice for one order*, teve `0.399` em
`search.py`, logo abaixo do limiar de 0,4, então o `WHERE` a descartou. Um limiar ao lado da
quantidade é o que a aula 16 defende, e esta função tem os dois.

`LANGUAGE sql STABLE` diz ao PostgreSQL que a função só lê, o que deixa o planejador tratá-la como a
consulta que está dentro dela. A função é esquema comum: vai numa migração junto com a tabela, e muda
quando a consulta muda.

Na aplicação, a chamada nomeia a função e passa os argumentos como JSON. O vetor viaja como um array
JSON de 384 números e chega como `vector`, porque esse é o tipo do parâmetro:

```python
import os
from supabase import create_client
from minilm import embed

supabase = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_KEY"])
q = embed("how do I get my money back")[0]

result = supabase.rpc("match_articles", {
    "query_embedding": q.tolist(),
    "match_threshold": 0.4,
    "match_count": 3,
}).execute()
for row in result.data:
    print(row["id"], row["title"], row["similarity"])
```

O programa transformaria a pergunta em vetor do lado de quem chama, com o mesmo modelo dos artigos
guardados, exatamente como `search.py` fez. O Supabase guarda e busca; ele não escolhe o modelo nem
confere se os dois vetores vieram do mesmo. E o `384` no tipo do parâmetro não é a verificação que
parece ser. O PostgreSQL ignora o tamanho escrito no parâmetro de uma função, então um vetor de outro
tamanho entra na função e só é recusado um passo depois, pelo operador:

```
ana@lab:~/emb$ psql -c "SELECT * FROM match_articles(array_fill(0.1::real, ARRAY[256])::vector, 0.4, 3)"
ERROR:  different vector dimensions 384 and 256
```

**A coluna recusou um vetor errado na entrada; a função só o recusa na comparação.** De um jeito ou
de outro, um vetor das 256 dimensões do WordLlama não pode ser comparado com os artigos, e de um
jeito ou de outro dois modelos com a mesma dimensão passariam.

## A segurança em nível de linha decide o que uma busca enxerga

A API pode ser acessada de um navegador, e um navegador tem qualquer chave que a página recebeu.
Então a fronteira não pode ficar no cliente. A documentação do Supabase recomenda **segurança em
nível de linha** (row-level security) em toda tabela que a API expõe: uma política na tabela,
imposta pelo próprio PostgreSQL, que decide quais linhas cada requisição pode ler. O guia dele de
recuperação com permissões usa exatamente isso para manter os documentos de um usuário fora das
buscas de outro.

A política alcança o interior de `match_articles` também. Uma função SQL roda, por padrão, com os
direitos de quem a chama, o `SECURITY INVOKER` do PostgreSQL, então as linhas que a função ordena já
são as linhas que quem chamou pode ver. Uma função declarada `SECURITY DEFINER` roda com os direitos
do dono e pula as políticas de quem chama, o que transforma uma função de busca num jeito de
contorná-las.

Duas chaves importam. A chave **anon** é feita para o navegador e está sujeita às políticas. A chave
**service_role** ignora a segurança em nível de linha por completo, então ela fica num servidor e
nunca numa página. A aula 17 constrói uma política de segurança em nível de linha para duas lojas no
PostgreSQL do laboratório e mostra a mesma consulta devolvendo a cada loja só os próprios artigos.
