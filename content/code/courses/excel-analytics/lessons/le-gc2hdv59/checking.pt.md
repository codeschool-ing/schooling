---
title: Conferindo uma medida com SOMASES
version: 1
---

**Uma medida se confere calculando a mesma célula de outro jeito, e as duas precisam bater até o
real.** Uma medida pode estar bem escrita, aceita por **Verificar Fórmula DAX**, formatada, e errada:
uma relação faltando, um filtro removido que devia ter ficado, uma data que não casa com nenhuma
linha do calendário. Nada disso produz erro. Cada um produz um número, e o único jeito de pegá-lo é
um segundo número em que você confia por outra razão.

Para este modelo, esse segundo número é o `SOMASES` (`SUMIFS` no Excel em inglês) da aula 5. Ele lê
a planilha, não o modelo, e não tem nada em comum com uma medida além das linhas. Bater quer dizer que
as relações, os filtros e a medida fizeram o que você queria.

## Cinco células, de dois jeitos

Escolha células das tabelas dinâmicas desta aula, anote de que cada uma trata e calcule-a na
planilha. Digite estas fórmulas em quaisquer células vazias; elas nomeiam a planilha `Sales`, então
funcionam de qualquer lugar da pasta.

```localised
=SOMASES(Sales!H2:H109;Sales!G2:G109;"Online";Sales!B2:B109;">="&DATA(2026;1;1))
=SOMASES(Sales!H2:H109;Sales!B2:B109;">="&DATA(2025;1;1);Sales!B2:B109;"<"&DATA(2025;7;1))
=SOMASES(Sales!H2:H109;Sales!B2:B109;">="&DATA(2026;1;1);Sales!B2:B109;"<"&DATA(2026;4;1))
=CONT.SES(Sales!B2:B109;">="&DATA(2026;1;1))
=SOMA(Sales!H2:H109)
```

| fórmula | responde | a medida, na célula | valor da medida |
|---|---|---|---|
| a primeira | **4.295** | `Total Revenue`, linha `Online`, coluna `2026` | 4.295 |
| a segunda | **17.789** | `Revenue LY`, 2026, segmentação nos meses 1 a 6 | 17.789 |
| a terceira | **12.139** | `Revenue YTD`, março de 2026 | 12.139 |
| a quarta | **36** | `Sales Count`, coluna `2026` | 36 |
| a quinta | **51.494** | `Total Revenue`, total geral | 51.494 |

As fórmulas foram executadas numa planilha com os seus dados, e as medidas foram calculadas a partir
das mesmas linhas aplicando as definições delas, como a seção 02 explicou: **nenhuma das duas colunas
de números veio do Excel**, e as duas batem nas cinco. Na sua pasta, as medidas vêm do Power Pivot e as
fórmulas do Excel, e elas devem bater entre si e com esta tabela.

Cada par testa uma coisa diferente. O primeiro testa uma medida, uma relação e um filtro numa coluna
de fatos ao mesmo tempo. O segundo é o que testa `SAMEPERIODLASTYEAR`: a fórmula nomeia o primeiro
semestre de 2025 com todas as letras, e a medida precisa chegar lá movendo as datas de 2026. O
terceiro testa `TOTALYTD` do mesmo jeito. O quarto testa `COUNTROWS` e a relação com o calendário. O
quinto testa que nada se perdeu em lugar nenhum: se `Total Revenue` sem filtro não é a soma da coluna,
falta uma linha no modelo, e a aula 15 seção 04 diz onde procurar.

Com `Sales` sendo a tabela do Excel da aula 7, `Sales[Revenue]`, `Sales[Channel]` e `Sales[Date]`
podem substituir os três intervalos, e as respostas são as mesmas; os intervalos estão impressos
aqui para que a fórmula funcione também numa pasta em que a tabela nunca foi criada.

## Quando não batem

Uma diferença é informação, e aponta para uma lista curta de causas, quase todas vistas na aula 15:

- **toda linha da tabela dinâmica mostra o mesmo número**: falta uma relação, aula 15 seção 05;
- **a medida fica abaixo da fórmula, em datas**: alguns valores de `Sales[Date]` não casam com
  nenhuma linha do calendário, porque trazem hora ou caem fora de 2025 e 2026, aula 15 seção 06;
- **o total geral diverge e as linhas não**: uma segmentação ou um filtro da tabela dinâmica ainda
  está ativo, e a fórmula não sabe nada dele;
- **uma média diverge**: um lado divide somas e o outro tira a média dos preços, seção 03;
- **uma fatia ou uma medida "online" diverge**: o filtro que `CALCULATE` trocou ou removeu não é o
  que você queria, seção 04.

**Confira uma célula de toda medida nova antes que alguém a leia.** Leva um minuto, e uma medida num
painel é lida por gente que nunca vai abrir o modelo para ver por que ela diz o que diz.
