---
title: Quando uma tabela é o elemento certo
version: 1
---

**Uma tabela é para dados que têm duas dimensões**: cada valor fica no encontro de uma linha com uma coluna, e significa algo por causa das duas. Os horários do sebo são assim: *7 pm* sozinho não quer dizer nada, e quer dizer *de segunda a sexta, fecha* na sua linha e na sua coluna. Uma lista de preços, uma tabela de horários, uma comparação de três edições de um livro são tabelas. Uma lista de eventos não é: cada evento é uma coisa só, e o elemento certo é uma lista ou um conjunto de articles, aula 2.

## Tabelas não são para layout

Por uns dez anos, antes de o CSS conseguir montar uma página, as pessoas construíam sites inteiros com tabelas: uma linha para o cabeçalho, uma coluna para o menu, uma célula para o conteúdo. Você ainda vai encontrá-las em páginas antigas e, muitas vezes, em e-mails em HTML, porque muitos programas de e-mail davam mal suporte a layout em CSS. **Numa página web, uma tabela usada para layout é um erro**, pelo mesmo motivo da sopa de divs: ela diz uma coisa falsa. Um leitor de tela encontra uma tabela e oferece ao usuário a navegação de tabela, *linha 2, coluna 3*, por algo que na verdade é um menu e um artigo. E ela não se reorganiza: as colunas de uma tabela ficam lado a lado, então numa tela estreita a página transborda em vez de empilhar. As aulas 8 e 9 fazem o layout com Flexbox e Grid, que foram feitos para isso.

## O que um leitor de tela faz com uma tabela de verdade

A tabela é o elemento em que a árvore de acessibilidade mais acrescenta, porque as relações entre as células é que tornam os dados legíveis sem ver a grade. Quem anda pela tabela de horários célula por célula pode ouvir, em *7 pm*, *Monday to Friday, Closes, 7 pm*: a célula, mais os cabeçalhos da linha e da coluna. Isso só funciona se o HTML disser quais células são cabeçalhos, que é a próxima seção.
