---
title: Buscando com ORDER BY
version: 1
---

Uma busca de vizinhos mais próximos em SQL não é um comando especial. É um `ORDER BY` comum sobre
uma distância, com um `LIMIT`: ordene todas as linhas pela distância entre o vetor delas e o da
pergunta, e fique com as primeiras. O pgvector fornece a distância como um operador entre dois
vetores, e todo o resto é o SQL que você já escreve.

## A busca

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import sys\nimport psycopg\nfrom pgvector.psycopg import register_vector\nfrom minilm import embed\n\nq = embed(sys.argv[1])[0]",
      "note": "A pergunta chega como primeiro argumento e vira vetor com o mesmo modelo dos artigos."
    },
    {
      "code": "with psycopg.connect() as conn:\n    register_vector(conn)\n    rows = conn.execute(\n        \"SELECT id, title, embedding <=> %(q)s AS distance FROM articles\"\n        \" ORDER BY embedding <=> %(q)s LIMIT 3\", {\"q\": q}).fetchall()",
      "note": "Uma consulta faz a busca: ordena todas as linhas pela distância de cosseno até a pergunta e fica com três. `%(q)s` é um parâmetro nomeado, então o vetor é enviado uma vez e usado duas."
    },
    {
      "code": "for id, title, distance in rows:\n    print(f\"{distance:.3f}  {1 - distance:.3f}  {id}  {title}\")",
      "note": "A distância, a similaridade que ela representa (um menos a distância), o id e o título."
    }
  ],
  "output": "ana@lab:~/emb$ python search.py \"how do I get my money back\"\n0.554  0.446  h18  Returning a gift\n0.562  0.438  h15  When your refund arrives\n0.601  0.399  h22  Charged twice for one order"
}
```

São as notas que a aula 1 imprimiu para a mesma pergunta, `0.446` para o artigo do presente e
`0.438` para o de reembolso, agora encontradas entre os 40 artigos em vez de seis escolhidos a dedo.
Na central de ajuda inteira um terceiro artigo se junta a eles: **Charged twice for one order**
("cobrado duas vezes pelo mesmo pedido"), com `0.399`, que também trata de receber dinheiro de
volta. O programa manda um vetor e recebe três linhas. Os 40 vetores dos artigos nunca saíram do
banco.

## Três operadores nas mesmas linhas

A aula 2 apresentou os três operadores em dois vetores pequenos: `<->` para a distância L2, `<=>`
para a distância de cosseno e `<#>` para o produto interno com o sinal trocado. Aqui eles estão nas
três linhas que a busca acabou de achar, com o vetor da pergunta tirado da tabela `queries`:

```sql
SELECT a.id,
       a.embedding <-> q.embedding AS l2,
       a.embedding <=> q.embedding AS cosine_distance,
       a.embedding <#> q.embedding AS negative_inner_product
FROM articles a, queries q
WHERE q.id = 'q01'
ORDER BY a.embedding <=> q.embedding
LIMIT 3;
```

```
ana@lab:~/emb$ psql -f ops.sql
 id  |         l2         |  cosine_distance   | negative_inner_product 
-----+--------------------+--------------------+------------------------
 h18 |  1.053030789742982 | 0.5544369486309908 |   -0.44556307792663574
 h15 | 1.0605979050079148 | 0.5624339282512665 |    -0.4375660717487335
 h22 | 1.0960301201990503 | 0.6006410777950922 |    -0.3993588984012604
(3 rows)
```

**Os três põem as linhas na mesma ordem**, e para vetores de comprimento 1 sempre vão pôr, porque
cada um é função do mesmo cosseno. O produto interno negativo é a distância de cosseno menos um,
então para h18 ele é a similaridade que `search.py` imprimiu, `0.446`, com o sinal trocado. A
distância L2 é a raiz quadrada do dobro da distância de cosseno. Confira a primeira linha à mão e os
últimos dígitos discordam um pouco: `0.5544369486309908` menos um não dá exatamente
`-0.44556307792663574`, porque o pgvector soma os produtos em precisão simples e os dois operadores
terminam a conta de jeitos diferentes. Arredonde para exibir, nunca para comparar.

O sinal de `<#>` é o que pega as pessoas. **Todo operador devolve um número em que menor quer dizer
mais perto**, porque as varreduras de índice do PostgreSQL percorrem uma ordem de baixo para cima.
Então `ORDER BY embedding <#> q` está certo, e uma similaridade lida a partir dele precisa ter o
sinal trocado. Este curso usa `<=>`, que vira similaridade com uma subtração.

## Um join é uma busca para cada linha

Como os vetores ficam em tabelas, uma busca pode ser parte de uma consulta maior. A tabela `queries`
guarda as 24 perguntas de teste com seus próprios vetores e os artigos que o curso julgou
relevantes, e um único comando pode buscar os artigos para cada pergunta e ficar com os erros:

```sql
SELECT q.id, q.text, top.id AS first, q.relevant
FROM queries q
CROSS JOIN LATERAL (
    SELECT a.id FROM articles a
    ORDER BY a.embedding <=> q.embedding
    LIMIT 1
) AS top
WHERE NOT top.id = ANY (q.relevant)
ORDER BY q.id;
```

```
ana@lab:~/emb$ psql -f recall.sql
 id  |             text              | first | relevant  
-----+-------------------------------+-------+-----------
 q01 | how do I get my money back    | h18   | {h15,h14}
 q08 | send books to another country | h16   | {h10}
 q17 | where is my parcel right now  | h09   | {h08}
 q19 | my order came in pieces       | h09   | {h13}
 q21 | discount for a classroom set  | h04   | {h05}
(5 rows)
```

`CROSS JOIN LATERAL` é o que faz isso funcionar. Uma subconsulta lateral pode se referir à linha à
qual está ligada, então para cada pergunta `q` ela roda a busca com `q.embedding` e devolve o artigo
mais próximo. O `WHERE` de fora fica com as perguntas cujo primeiro artigo não é um dos relevantes.

**Voltaram cinco linhas, então 19 das 24 perguntas puseram um artigo relevante em primeiro.** Isso é
o recall em 1, a medida que a aula 3 construiu, calculado aqui sem que um único vetor saísse do
PostgreSQL. Vale ler os erros: *my order came in pieces* ("meu pedido chegou em pedaços") achou h09,
o pacote que nunca chegou, em vez de h13, um pedido que chega em vários pacotes.

Nada no join é específico de vetores. A mesma busca `LATERAL` pode ficar ao lado de um join com uma
tabela de pedidos, de um `WHERE` sobre uma data ou de um `GROUP BY` por categoria, e o planejador
cuida de tudo num comando só. É esse o argumento que a última seção desta aula faz para manter os
vetores onde o resto dos dados já está.
