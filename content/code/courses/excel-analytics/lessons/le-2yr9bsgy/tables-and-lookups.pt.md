---
title: Buscas entre tabelas
version: 1
---

**Uma busca escrita com referências estruturadas nomeia a coluna que devolve, então sobrevive às
mudanças que quebram uma escrita com número de coluna.** A aula 4 buscou preços e nomes em
`Products` por endereço. Com três tabelas, a mesma busca pode dizer *o custo unitário do produto
desta linha* com todas as letras, e continuar dizendo isso depois que alguém reorganizar `Products`.

## Uma coluna de custo, por busca

Quanto custou à Café Serra torrar os sacos vendidos? `Sales` conhece os sacos e `Products` conhece o
custo de um saco, então cada venda precisa de uma busca. Digite `Cost` em **I1**, o primeiro
cabeçalho vazio ao lado da tabela. A tabela cresce para incorporar a coluna, como a seção 04 mostrou
para linhas. Em **I2** digite:

```localised
=[@Bags]*PROCX([@Product]; Products[Code]; Products[Unit cost])
```

Leia em voz alta: *os sacos desta linha, vezes o custo unitário do produto cujo código é o produto
desta linha*. É uma coluna calculada, então preenche as 108 linhas de uma vez, e I2 responde
**854**: 14 sacos de `CER1K` a R$ 61. Depois, fora da tabela:

```localised
=SOMA(Sales[Cost])
=SOMA(Sales[Revenue])-SOMA(Sales[Cost])
```

**30390** de custo e **21104** de margem bruta, cerca de **41%** dos R$ 51.494 de receita. Tome isso
como estimativa, não como contabilidade. `Unit cost` guarda o custo de um saco hoje, e as vendas de
2025 foram torradas pelo custo da época, que estas tabelas não registram.

## Por que não PROCV

O mesmo custo pode ser buscado com o `PROCV` (`VLOOKUP` no Excel em inglês) da aula 4, apontado para
a tabela inteira:

```localised
=PROCV([@Product]; Products; 7; FALSO)
```

Na linha 2 ele responde **61**, como o `PROCX` (`XLOOKUP`). Apontá-lo para `Products` em vez de
`Products!A2:G7` já ajuda: um produto acrescentado à tabela é encontrado sem editar a fórmula. O que
ele ainda carrega é o **7**, a posição de `Unit cost` contada a partir da esquerda.

Experimente o que isso custa. Na planilha `Products`, clique com o botão direito no cabeçalho
`Grams`, escolha **Inserir › Colunas da Tabela à Esquerda** e chame a coluna nova de `Supplier`.
`Unit cost` agora é a oitava coluna. O `PROCV` da linha 2 responde **118**, que é o preço de tabela
de `CER1K`, a coluna que passou para o sétimo lugar. Nenhum erro, só um número diferente e errado. O
`PROCX` da coluna `Cost` continua respondendo 854 na linha 2 e **30390** no total, porque
`Products[Unit cost]` nomeia a coluna, onde quer que ela esteja agora.

Aperte **Ctrl+Z** para tirar a coluna `Supplier` de novo.

## O que as tabelas deixam para o resto do curso

A coluna `Cost` era para esta seção. As aulas seguintes trabalham com as oito colunas que a aula 2
deixou, e as aulas 15 e 16 relacionam as tabelas num modelo de dados em vez de copiar valores de uma
para outra com buscas. Clique com o botão direito no cabeçalho `Cost` e escolha **Excluir › Colunas
da Tabela**.

O que fica são três tabelas: `Sales`, com suas oito colunas e 108 linhas, `Products` e `Customers`.
Confira o tamanho com `=LINS(Sales[Sale])`, que deve responder 108, e salve. Daqui em diante, as
fórmulas deste curso nomeiam as tabelas em vez dos endereços, e as tabelas dinâmicas da aula 10, as
listas suspensas da aula 8 e as consultas da aula 13 partem todas delas.
