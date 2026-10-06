---
title: O que uma entrada do dicionário guarda
version: 1
---

Um dicionário tem uma entrada por coluna, agrupada por tabela, e uma entrada por tabela. O que vai numa entrada é uma
lista pequena e razoavelmente assentada:

- **O significado**, numa frase que alguém de fora do time de dados consiga ler. "Vendas líquidas: bruto menos
  desconto, sem frete" em vez de "valor líquido".
- **A unidade**, sempre que houver: centavos, dias, exemplares, porcentagem. Um número sem unidade é a fonte mais comum
  de um erro de cem vezes.
- **O que valores vazios e especiais significam.** A chave 0 é "não identificado"; a chave de data 0 é "ainda não"; um
  `days_to_ship` vazio quer dizer que o pedido não foi enviado. Cada um foi uma decisão numa lição anterior, e quem lê
  não consegue adivinhar.
- **Como pode ser somado**: aditivo, semiaditivo, ou de jeito nenhum, a distinção da lição 2 escrita onde quem escreve o
  `SUM` vai ver.
- **De onde vem**, pelo menos até o sistema e a coluna de origem; é o começo da linhagem.
- **Se descreve uma pessoa**, e quão diretamente. É a classificação da seção 9.

A entrada de uma tabela acrescenta a coisa mais importante de todas: **o grão**, uma frase dizendo o que é uma linha.
A lição 4 gastou uma lição inteira explicando por quê.

Ao lado do dicionário costuma existir um **glossário de negócio**: uma lista dos termos que o negócio usa, como vendas
líquidas, recebimentos ou cliente ativo, cada um com sua definição e um dono. São dois documentos diferentes, ligados
entre si. O glossário diz o que "vendas líquidas" significa para a empresa; o dicionário diz qual coluna guarda isso.
As três receitas da lição 11 eram um glossário faltando, com um dicionário faltando embaixo.
