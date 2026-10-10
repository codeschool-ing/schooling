---
title: CONT.SES, quantas linhas passam
version: 1
---

**`CONT.SES` (`COUNTIFS` no Excel em inglês) conta linhas, nunca o que está nelas.** É o
`SOMASES` sem nada para somar: os mesmos pares de intervalo e condição, e a resposta é quantas
linhas passaram em todos. A armadilha é ler essa contagem como quantidade. Pergunte quantas vendas
online houve e quantos sacos elas venderam, e você precisa de duas funções diferentes:

```localised
=CONT.SES(G2:G109; "Online")
=SOMASES(E2:E109; G2:G109; "Online")
```

A primeira responde **47**, a segunda **149**. Quarenta e sete vendas, 149 sacos. Um relatório que
pusesse 47 sob um título dizendo *sacos* erraria por um fator de três, e nada no número pareceria
estranho.

Como toda venda tem um canal, as contagens dividem as linhas como os totais dividiram:
`Wholesale` dá **38** e `Shop` **23**, e 47 + 38 + 23 são as 108 vendas que você conferiu na aula 1.

## Contando com duas condições

Quantas vendas do atacado foram de dez sacos ou mais?

```localised
=CONT.SES(G2:G109; "Wholesale"; E2:E109; ">=10")
```

**22** das 38. A condição `">=10"` é uma comparação escrita como texto, entre aspas, que a seção 05
explica junto com o resto da linguagem das condições. Troque por `"<10"` e a resposta é **16**, e
22 + 16 dá 38 de novo: uma condição e o seu oposto dividem um grupo exatamente, o que dá uma
conferência da própria condição.

## Uma contagem que diz algo sobre o negócio

```localised
=CONT.SES(C2:C109; "C00")
```

responde **70**. Setenta das 108 vendas foram para `C00`, o cliente de balcão e web sem cadastro,
então a maioria das vendas é pequena e anônima, enquanto 38 vendas do atacado trazem três quartos
da receita. Contar linhas é como você descobre como é uma linha típica, e aqui ela não se parece em
nada com as linhas que trazem o dinheiro.

## Contando as células vazias

A condição `""` casa com uma célula vazia, e `"<>"` com qualquer célula que não esteja vazia. Na
planilha `Customers`, numa célula vazia como **J2**,

```localised
=CONT.SES(D2:D12; "")
=CONT.SES(D2:D12; "<>")
```

respondem **1** e **10**: um cliente não tem cidade, `C00`, e dez têm. As duas somam os 11 clientes,
então nenhuma célula da coluna ficou de fora das duas. É a mesma pergunta que `CONTAR.VAZIO`
(`COUNTBLANK`) respondeu na aula 1, feita numa forma que aceita mais condições.

## O que CONT.SES não conta

Ela conta linhas, então não diz quantos clientes **diferentes** compraram online: um cliente com
seis vendas são seis linhas que passam. Contar valores distintos pede outra ferramenta, e a aula 16
tem uma. `CONT.SE` (`COUNTIF`), sem o S final, também existe e, ao contrário de `SOMASE`, mantém a
mesma ordem de argumentos do plural, então é inofensiva; ainda assim este curso escreve `CONT.SES`
o tempo todo.
