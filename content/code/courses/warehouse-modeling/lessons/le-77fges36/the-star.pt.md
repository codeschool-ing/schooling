---
title: A estrela
version: 1
---

A lição 2 construiu uma tabela fato e quatro dimensões, e ligou cada dimensão à tabela fato por uma
chave. Desenhe isso com a tabela fato no meio e você tem uma **estrela**: um centro com pontas, e nada
além das pontas.

**A forma é a definição.** Um esquema estrela é uma tabela fato e dimensões que estão, cada uma,
exatamente a uma junção dela. Uma dimensão nunca se liga a outra dimensão. Tudo o que descreve um
livro, até o departamento, mora na `dim_book`; tudo o que descreve uma loja, até a região, mora na
`dim_shop`.

Duas consequências decorrem disso, e são o motivo de a estrela ser o padrão:

- **Toda consulta tem a mesma forma.** Comece pela tabela fato, ligue as dimensões que a pergunta
  menciona, filtre e agrupe pelas colunas delas, some as medidas. Quem escreveu uma consulta sobre uma
  estrela escreve a próxima sem diagrama.
- **O banco pode contar com a forma.** A tabela fato é grande e as dimensões são pequenas, então o
  plano é quase sempre o mesmo: ler as tabelas pequenas, montar uma tabela de busca para cada uma, e
  passar a grande por elas uma vez. Bancos analíticos são construídos em torno desse plano, e alguns
  reconhecem uma estrela pela forma e o escolhem sem que ninguém peça.

Um warehouse costuma ter várias estrelas, uma por processo de negócio. O da Ana tem cinco tabelas fato,
e a seção 09 é sobre as dimensões que elas compartilham. Às vezes se usa a palavra **constelação** para
isso, e ela não muda nada em cada estrela.
