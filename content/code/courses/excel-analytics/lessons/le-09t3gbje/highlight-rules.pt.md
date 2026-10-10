---
title: As regras prontas, e o que cada uma testa de fato
version: 1
---

**Uma formatação condicional é uma regra que decide a aparência de uma célula pelo valor que ela
guarda, e a aparência muda sempre que o valor muda.** Pintar uma célula de amarelo à mão é um
recado que fica parado quando o número embaixo dele muda; uma regra é uma pergunta que a planilha
refaz a cada recálculo. A aula 1, seção 07, disse que cor não é dado. A regra é o jeito de contornar
isso: os dados ficam nas células, e a cor é calculada a partir deles.

Tudo fica em **Página Inicial › Formatação Condicional** (**Home › Conditional Formatting** no Excel
em inglês). Os dois primeiros grupos desse menu são regras prontas, e vale experimentar cada uma na
coluna `Revenue` da tabela `Sales`.

## Realçar Regras das Células: comparar com um valor

Selecione `Sales[Revenue]`, H2:H109, e escolha **Realçar Regras das Células › É Maior do que**
(**Highlight Cells Rules › Greater Than**). Digite `1000`, mantenha o formato sugerido e **OK**. Toda
venda acima de R$ 1.000 agora está colorida. Uma fórmula as conta:

```localised
=CONT.SE(Sales[Revenue]; ">1000")
```

**18** vendas. O mesmo grupo tem **É Menor do que**, **Está Entre**, **É Igual a**, **Texto que
Contém**, **Uma Data que Ocorre** e **Valores Duplicados**. O último é uma conferência rápida de uma
chave: ponha em `Sales[Sale]` e nada fica colorido, porque nenhum código de venda aparece duas vezes.
Em `Sales[Customer]` quase tudo fica, porque um cliente compra muitas vezes. É a diferença que a
aula 1, seção 06, fez entre chave e ponteiro, vista em cor.

## Regras de Primeiros/Últimos: comparar com os outros valores

**Regras de Primeiros/Últimos** (**Top/Bottom Rules**) compara cada célula com o resto do intervalo
em vez de com um número digitado. Limpe a primeira regra (**Formatação Condicional › Limpar Regras ›
Limpar Regras das Células Selecionadas**) e experimente **10 Primeiros Itens** (**Top 10 Items**) na
mesma coluna. Conte as células coloridas: são 11, não 10.

```localised
=MAIOR(Sales[Revenue]; 10)
=CONT.SE(Sales[Revenue]; ">="&MAIOR(Sales[Revenue]; 10))
```

A décima maior receita é **1.456**, e duas vendas têm exatamente essa receita. **A regra colore todo
valor pelo menos tão grande quanto o décimo, então um empate na fronteira colore os dois.** Uma lista
"dos 10 maiores" tirada das cores teria 11 linhas, e ninguém saberia qual tirar.

**Acima da Média** (**Above Average**) é a outra regra que as pessoas usam, e ela diz menos do que
parece:

```localised
=MÉDIA(Sales[Revenue])
=CONT.SE(Sales[Revenue]; ">"&MÉDIA(Sales[Revenue]))
```

A venda média é de **R$ 476,80**, e só **37** das 108 vendas estão acima dela. Alguns pedidos de
atacado de R$ 1.000 ou mais puxam a média para cima, então a maioria das vendas fica abaixo. "Acima
da média" não é "a melhor metade", e em dados com esse formato fica mais perto de "o terço de cima".

## O que essas regras não fazem

Toda regra pronta colore **a célula que ela testa**. Para colorir uma venda inteira, as oito células
da linha, por causa do que o `Channel` dela diz, o teste tem de estar numa coluna e a cor em outra.
Isso pede uma fórmula, que é a próxima seção.
