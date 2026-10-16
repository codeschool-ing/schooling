---
title: Por que não `LIKE`
version: 1
---

A primeira caixa de busca da maioria das aplicações é uma consulta `LIKE`:
`WHERE name ILIKE '%' || :words || '%'`. Ela acha linhas cujo texto contém as letras digitadas, e para
uma tela interna usada por gente que sabe os nomes exatos ela basta. Para clientes ela falha de jeitos que
eles percebem na hora:

| o cliente digita | o que o `ILIKE` faz | o que ele esperava |
| --- | --- | --- |
| `cafe` | não acha nenhum `Café`, porque `e` não é `é` | o café |
| `cafés` | não acha `Café`, porque o plural tem uma letra a mais | o café |
| `café torrado` | acha só nomes com essas duas palavras juntas, nessa ordem | qualquer coisa com as duas |
| `cafe torado` | nada; uma letra errada não combina | o café, com um "você quis dizer" |
| `café` | quarenta linhas, na ordem em que a tabela as devolver | as mais relevantes primeiro |

Ela também é lenta em escala. Um padrão que começa com `%` não usa um índice comum, então toda busca lê
toda linha: o banco ocupado da aula 16, na página que os clientes mais usam.

Um **motor de busca** é feito para a outra coluna dessa tabela. Ele **analisa** o texto, tanto quando o
guarda quanto quando busca, para `cafés`, `Café` e `cafe` virarem o mesmo termo. Ele mantém um **índice
invertido**, de cada termo para os documentos que o contêm, então uma busca lê só os documentos que
combinam. Ele os **ordena** por relevância. Tolera **erros de digitação**. E conta os resultados por
categoria, faixa de preço ou marca na mesma requisição, os filtros ao lado dos resultados, chamados
**facetas**.

O próprio PostgreSQL vai parte do caminho, com `tsvector`, `to_tsquery` e as extensões `unaccent` e
`pg_trgm`, e para um catálogo pequeno isso pode ser tudo de que uma loja precisa. Esta aula usa um motor
dedicado, porque é o que as lojas maiores usam e porque vê-lo rodar explica o que os recursos do banco
estão imitando.
