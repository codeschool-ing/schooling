---
title: Referências estruturadas, fórmulas que dizem o que querem dizer
version: 1
---

**Uma referência estruturada nomeia uma tabela e uma coluna em vez de dar um endereço.**
`Sales[Bags]` é a coluna `Bags` da tabela `Sales`: todas as linhas de dados, quantas forem, e nunca
o cabeçalho. Hoje são as mesmas células de `E2:E109`. A diferença aparece no dia em que a tabela
tiver 109 vendas, e enquanto isso a fórmula se lê como a pergunta que faz.

## As partes de uma tabela, pelo nome

```schooling-figure
{"svg": "<svg data-fig=\"l07-table\"></svg>", "caption": ""}
```

| referência | o que ela cobre |
|---|---|
| `Sales[Bags]` | as linhas de dados de uma coluna |
| `Sales[@Bags]`, ou `[@Bags]` dentro da tabela | o valor daquela coluna na própria linha da fórmula |
| `Sales[#Headers]` | a linha de cabeçalho |
| `Sales[#Totals]` | a linha de total, quando a tabela tem uma (seção 05) |
| `Sales[#All]` | tudo: cabeçalhos, dados e linha de total |
| `Sales` | as linhas de dados de todas as colunas |

No Excel em português, os marcadores entre colchetes também mudam de idioma: `#Headers` aparece como
`#Cabeçalhos`, `#Totals` como `#Totais` e `#All` como `#Tudo`. O nome da tabela e os nomes das
colunas, que são seus, não mudam.

Dentro da tabela o Excel tira o nome dela e escreve `[@Bags]`, porque a tabela é óbvia. Fora dela,
em qualquer planilha da pasta de trabalho, o nome é necessário e basta: uma tabela pertence à pasta
de trabalho, então `Sales[Bags]` não precisa de nome de planilha na frente, ao contrário de
`Sales!E2:E109`.

Você quase nunca digita essas referências. Comece uma fórmula, clique numa coluna da tabela, e o
Excel escreve a referência sozinho: clicar de E2 até E109 enquanto digita `=SOMA(` produz
`Sales[Bags]`.

## A aula 5, reescrita

Numa célula vazia de qualquer planilha:

```localised
=SUM(Sales[Bags])
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")
=ROWS(Sales[Sale])
```

respondem **591**, **38731** e **108**. A segunda é o primeiro `SOMASES` (`SUMIFS` no Excel em
inglês) da aula 5, e agora se lê quase como a frase que representa: *some a receita das vendas cujo
canal é Wholesale*. A terceira, `LINS` (`ROWS`), conta as linhas da tabela, que é o número com que
toda conferência da aula 1 começava, e vai continuar respondendo certo quando esse número mudar.

A grade `Report` da aula 5, se você a guardou, pode receber o mesmo tratamento:

```localised
=SUMIFS(Sales[Bags], Sales[Product], $A3, Sales[Date], ">="&B$2, Sales[Date], "<"&EDATE(B$2, 1))
```

dá os mesmos **116** do trimestre depois de preencher a grade. Não há `$` nas referências da tabela
porque elas não precisam de um para ficar no lugar quando **copiadas**. Precisam de cuidado quando
**arrastadas**: preencher uma referência estruturada para a direita com a alça de preenchimento a
move para a coluna seguinte, então `Sales[Bags]` em B3 vira `Sales[Price]` em C3. Copie e cole a
célula, ou escreva a coluna como `Sales[[Bags]:[Bags]]`, que fica onde está seja como for preenchida.

## Quando um endereço ainda é o certo

Uma referência estruturada aponta para uma tabela, então é a referência certa para dados. Um
endereço continua certo para uma célula avulsa que não faz parte de tabela nenhuma, como as datas do
cabeçalho da grade `Report`. A maior parte das fórmulas do resto do curso mistura as duas, e tudo
bem: a tabela nomeia os dados, e os endereços nomeiam as células em volta deles.
