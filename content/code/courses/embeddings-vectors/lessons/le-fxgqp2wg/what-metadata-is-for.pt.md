---
title: Para que servem os metadados
version: 1
---

Um vetor responde a uma pergunta: *sobre o que é este texto?* A maior parte das buscas reais faz uma
segunda ao mesmo tempo: artigos sobre devolução *em português*; mensagens como esta *da última
semana*; documentos sobre o contrato *que este usuário tem permissão de ler*. A segunda pergunta tem
uma resposta exata, e um vetor é a ferramenta errada para ela. Essa resposta vem dos **metadados**:
campos comuns guardados ao lado do vetor e testados com comparações comuns.

Todo artigo da central de ajuda leva três desses campos: um idioma, uma categoria e a data da
última atualização.

```
ana@lab:~/emb$ jq -r .lang data/help.jsonl | sort | uniq -c
     37 en
      3 pt
ana@lab:~/emb$ jq -r .category data/help.jsonl | sort | uniq -c
      7 account
      6 ebooks
      6 orders
      6 payments
      7 returns
      8 shipping
```

## Os campos de que uma busca costuma precisar

Os campos que aparecem sempre se dividem em alguns tipos, e cada um é uma condição que nenhuma
quantidade de semelhança consegue substituir:

| campo | a pergunta que ele responde |
|---|---|
| idioma | este leitor consegue ler? |
| categoria, produto, seção | é o tipo de coisa que ele está procurando? |
| data | está atual, ou dentro do período pedido? |
| preço, estoque, disponibilidade | dá para comprar? |
| cliente (tenant), dono, permissões | **ele tem permissão de ver isso?** |

A última linha é de outra natureza, e a última seção desta aula trata dela. Um idioma errado é um
resultado ruim. Uma linha da conta de outro cliente é um vazamento.

**Por que não deixar o vetor carregar isso?** O atalho tentador é escrever o campo no texto antes
de transformá-lo em vetor, *Language: Portuguese. Como devolver um livro*, e torcer para a busca
resolver. A aula 1 mostrou quanto vale essa esperança: o all-MiniLM-L6-v2 avaliou *How to return a
book* contra a própria tradução em português como dois textos sem relação. Semelhança é questão de
grau, e *isto está em português* tem resposta sim ou não. Um filtro dá a resposta exata toda vez.

## Guardados ao lado do vetor

A aula 11 descreveu um registro como um id, um vetor e seus metadados, e todo banco das aulas 12 a
14 os guarda assim: os `metadatas` do Chroma, as colunas do LanceDB, o payload do Qdrant, as colunas
comuns do PostgreSQL. Guarde os campos com tipo (uma data como data, um preço como número) para que
um filtro possa compará-los, e guarde-os no mesmo registro do vetor para que filtro e busca possam
rodar numa só requisição.

A pergunta que o resto desta aula responde é como os dois rodam juntos, porque há duas ordens para
fazer isso, e elas não dão os mesmos resultados.
