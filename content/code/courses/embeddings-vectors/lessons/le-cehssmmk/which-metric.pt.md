---
title: Qual medida usar
version: 1
---

Três medidas apareceram nesta aula: o produto escalar, a similaridade de cosseno e a distância L2.
É fácil tratar a escolha como questão de gosto, ou pegar a que soa mais precisa. **A escolha é do
modelo.** Ele foi treinado para deixar alguma medida alta para textos que andam juntos, e a
documentação dele diz qual. O all-MiniLM-L6-v2 foi treinado para similaridade de cosseno, e como ele
devolve vetores normalizados, o produto escalar e a L2 dão a mesma ordem que o cosseno, como
`euclid.py` mostrou.

Então a regra é curta. Use a medida com que o modelo foi treinado. Se os vetores estão normalizados,
ou se você os normaliza, qualquer uma das três ordena igual, e o **produto escalar**, chamado de
**produto interno** (*inner product*) na maioria das bibliotecas, é o mais barato de calcular.

## Similaridades e distâncias

Bancos e bibliotecas de vetores em geral ordenam do menor para o maior, porque são construídos em
torno de distâncias. Cada medida chega, portanto, numa de duas formas, e o nome diz qual:

| medida | como similaridade (maior é mais perto) | como distância (menor é mais perto) |
|---|---|---|
| cosseno | similaridade de cosseno, de −1 a 1 | **distância de cosseno** = 1 − similaridade de cosseno, de 0 a 2 |
| produto escalar | produto interno | produto interno negativo |
| L2 | — | distância L2, ou o quadrado dela |

A extensão `pgvector` do PostgreSQL tem um operador para cada distância, e os dois vetores do
começo desta aula mostram os três:

```schooling-example
{
  "language": "sql",
  "file": "metrics.sql",
  "parts": [
    {
      "code": "CREATE EXTENSION vector;",
      "note": "A extensão é instalada no banco uma vez. A aula 14 começa daqui."
    },
    {
      "code": "SELECT '[2,1,2]'::vector <-> '[1,2,2]' AS l2_distance,\n       '[2,1,2]'::vector <=> '[1,2,2]' AS cosine_distance,\n       '[2,1,2]'::vector <#> '[1,2,2]' AS negative_inner_product;",
      "note": "Os mesmos dois vetores do papel, escritos como literais `vector`, e uma coluna por operador."
    }
  ]
}
```

```
ana@lab:~/emb$ psql -f metrics.sql
CREATE EXTENSION
    l2_distance     |   cosine_distance   | negative_inner_product 
--------------------+---------------------+------------------------
 1.4142135623730951 | 0.11111111111111116 |                     -8
(1 row)
```

`<->` é a distância L2, 1,414 como no papel. `<=>` é a distância de cosseno: 1 − 0,8889, impressa
como `0.11111111111111116` por causa do arredondamento nos últimos dígitos. E `<#>` devolve **−8**,
o produto interno com o sinal trocado, para que ordenar do menor para o maior ponha o melhor
resultado em primeiro. Esqueça o sinal e uma consulta que ordena ao contrário devolve o pior artigo
da tabela. A aula 14 escreve esses operadores em consultas de verdade.

Outras ferramentas usam outras palavras para as mesmas três. O FAISS chama o produto escalar de `IP`
e tem tipos de índice separados para `L2`; o Chroma e o hnswlib dão ao espaço de uma coleção o nome
`cosine`, `ip` ou `l2` e devolvem uma distância em todos os casos, então um número menor é um
resultado melhor. A aula 12 põe as distâncias do Chroma ao lado dos cossenos de onde elas vieram.
Antes de ordenar um resultado ou pôr um limite nele, descubra qual dos dois tipos de número você
tem nas mãos.
