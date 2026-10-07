---
title: O que o leitor paga por um modelo normalizado
version: 1
---

O relatório da lição 1 pediu ao banco operacional a receita por ano e departamento. Precisou de seis
tabelas: pedidos, itens, livros, e a tabela de categorias três vezes, um apelido por nível da árvore.
Sobre a estrela, a mesma pergunta precisou de três.

Toda junção que um modelo obriga um leitor a escrever tem três custos, e só um deles é velocidade:

- **Conhecimento.** Alguém precisa saber que o departamento fica dois pais acima da categoria de um
  livro, que a tabela de categorias se liga a si mesma, e que alguns galhos têm só dois níveis. Cada um
  desses é um fato sobre o esquema que mora na cabeça de alguém ou num documento que ninguém lê.
- **Correção.** Toda junção é um lugar para errar a condição. Ligar `categories` uma vez em vez de duas
  dá a subcategoria onde se queria o departamento, e os totais parecem perfeitamente razoáveis.
- **Tempo.** Uma junção é trabalho para o banco: uma tabela hash montada, uma busca para cada linha. Em
  tabelas dimensão pequenas num motor colunar esse trabalho é pequeno; a seção 06 mede quão pequeno.

**Desnormalizar move esses custos de cada consulta para a carga.** A carga descobre o departamento de
cada livro uma vez, corretamente, e o escreve na linha do livro. Toda consulta depois disso lê uma
coluna.

Esse é o argumento inteiro das dimensões da estrela, e é um argumento sobre quem paga. No banco
operacional, os escritores são muitos e os leitores poucos, então a segurança dos escritores vence. No
warehouse, o escritor é um programa e os leitores são todo mundo, então a conveniência dos leitores
vence.
