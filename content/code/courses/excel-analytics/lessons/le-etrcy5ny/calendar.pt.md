---
title: Uma tabela calendário, uma linha para cada dia
version: 1
---

**`Sales[Date]` não é um calendário.** Ela guarda os 108 dias em que algo foi vendido, e nada sobre
os outros 622 dias de 2025 e 2026. Um relatório precisa desses dias também: um mês sem venda é um
mês que o relatório deve mostrar vazio, e não omitir, e as comparações da aula 16, como este ano
contra o mesmo período do ano passado, são calculadas sobre todos os dias de um período, com venda ou
sem. Então o modelo ganha uma quarta tabela, `Calendar`, com uma linha para cada dia e as colunas
pelas quais um relatório agrupa.

| coluna | guarda | para 15 de agosto de 2025 |
|---|---|---|
| `Date` | o dia, a chave | 2025-08-15 |
| `Year` | o ano | 2025 |
| `Month` | o mês como número, de 1 a 12 | 8 |
| `Month name` | o mês como nome curto | ago |
| `Quarter` | o trimestre | Q3 |

## Anos inteiros, do primeiro ao último

O calendário vai de **1º de janeiro de 2025 a 31 de dezembro de 2026**. Ele começa no primeiro dia
do primeiro ano com venda e termina no último dia do último ano, e não na última venda, que foi em 23
de junho de 2026. As funções de período do DAX, na aula 16, esperam anos inteiros, e um calendário
que parasse em junho faria de um ano de 2026 uma coisa diferente de um ano de 2025. O preço são seis
meses de 2026 sem venda nenhuma, e a aula 16 seção 05 mostra o que isso faz com uma comparação.

Quantas linhas isso dá, o Excel conta antes de você montar. Em qualquer célula vazia:

```localised
=DATA(2026;12;31)-DATA(2025;1;1)+1
```

responde **730**: uma data é uma contagem de dias, como a aula 1 seção 08 mostrou, então a diferença
entre duas delas é um número de dias, e o `+1` conta as duas pontas.

## Montando numa planilha

Crie uma planilha chamada `Calendar` e digite `Date` em A1. Em A2, digite a fórmula abaixo. Ela
**se espalha** (*spill*): uma fórmula preenche 730 células, de A2 a A731, com os dias em ordem.

```localised
=SEQUÊNCIA(730;1;DATA(2025;1;1);1)
```

Depois transforme em tabela:

1. Uma tabela do Excel não aceita uma fórmula que se espalha, então converta os dias em valores.
   Selecione A2:A731, copie e cole por cima com **Página Inicial › Colar › Colar Valores**. Dê à
   coluna um formato de data se ela mostrar números como 45658.
2. Clique em A1 e em **Inserir › Tabela**, com **Minha tabela tem cabeçalhos** marcada. Dê à tabela o
   nome `Calendar` em **Design da Tabela › Nome da Tabela**.
3. Digite os quatro cabeçalhos `Year`, `Month`, `Month name` e `Quarter` de B1 a E1 e, na linha 2 de
   cada um, uma fórmula. A tabela preenche cada uma pelas 730 linhas sozinha, como a aula 7 mostrou.

```localised
=ANO([@Date])
=MÊS([@Date])
=TEXTO([@Date];"mmm")
="Q"&INT((MÊS([@Date])+2)/3)
```

A última transforma os meses 1 a 3 em `Q1`, 4 a 6 em `Q2`, e assim por diante: somar 2 e dividir
por 3 põe cada mês no seu trimestre, e `INT` (o mesmo nome no Excel em inglês) descarta a fração.
`TEXTO` (`TEXT` no Excel em inglês) escreve o nome do mês no idioma em que o seu Excel está, então um
Excel em português escreve `ago` onde um em inglês escreve `Aug`. Os cabeçalhos ficam em inglês, como
os outros cabeçalhos dos dados.

**`SEQUÊNCIA` (`SEQUENCE` no Excel em inglês) pede o Excel 2021 ou o Microsoft 365**, as mesmas
versões do `PROCX`. Num Excel mais antigo, digite `2025-01-01` em A2 e use **Página Inicial ›
Preencher › Série**, escolha **Colunas**, incremento 1 e limite `2026-12-31`. O resto dos passos é
igual.

Se você seguiu as aulas 13 e 14, o Power Query monta a mesma coluna sem planilha nenhuma. Uma
consulta nula (**Dados › Obter Dados › De Outras Fontes › Consulta Nula**) com o código abaixo no
**Editor Avançado** cria os 730 dias, e o menu **Adicionar Coluna › Data** do editor acrescenta ano,
mês e trimestre:

```powerquery
let
    Days = List.Dates(#date(2025, 1, 1), 730, #duration(1, 0, 0, 0)),
    Calendar = Table.FromList(Days, Splitter.SplitByNothing(), {"Date"}),
    Typed = Table.TransformColumnTypes(Calendar, {{"Date", type date}})
in
    Typed
```

Por qualquer caminho, o resultado é uma tabela chamada `Calendar` com 730 linhas.

## No modelo, e marcada como tabela de datas

Carregue `Calendar` do jeito que a seção 04 carregou as outras três e desenhe a terceira relação, de
`Sales[Date]` para `Calendar[Date]`. O calendário é o lado um: cada dia aparece uma vez.

Depois diga ao modelo que este é o calendário dele. Na janela do Power Pivot, abra a guia `Calendar`
e escolha **Design › Marcar como Tabela de Datas** (*Mark as Date Table*), e então indique `Date`
como a coluna de data. O Excel confere que a coluna guarda datas, cada uma uma vez, sem nenhuma em
branco. Marcar é o que diz às funções de período da aula 16 por qual coluna caminhar, e que todo dia
de que elas precisam está lá.

**Uma data com hora não casa com nada no calendário.** As linhas do calendário são dias inteiros.
Uma venda registrada como `2025-08-15 14:30` é um número diferente de `2025-08-15`, e não se ligaria
a linha nenhuma. A sua `Sales[Date]` guarda só dias, e dados importados de um caixa ou de um site
muitas vezes não. A correção é ficar com o dia e descartar a hora: numa planilha, `INT` de uma data
com hora é a data, porque a hora é a fração depois do número inteiro; no Power Query, aula 14, é
mudar o tipo da coluna para **Data**.

## Nomes dos meses na ordem dos meses

Ponha `Calendar[Month name]` nas linhas de uma tabela dinâmica e os meses chegam em ordem
alfabética: `abr`, `ago`, `dez`, `fev`, `jan`, e assim por diante. São texto, e texto se ordena por
letra. O modelo pode ser avisado de que esta coluna se ordena por outra. Na guia `Calendar` da janela
do Power Pivot, clique em `Month name`, escolha **Página Inicial › Classificar por Coluna** (*Sort by
Column*) e ordene por `Month`. Daí em diante, toda tabela dinâmica põe `jan` primeiro e `dez` por
último, em todo relatório criado sobre o modelo.
