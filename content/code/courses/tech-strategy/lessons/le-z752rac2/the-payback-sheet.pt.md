---
title: A planilha de retorno
version: 1
---

Com um principal e um juro para cada dívida, uma divisão responde ao que uma lista de dívidas nunca
responde: **quantas sprints até que quitar a dívida tenha se pagado**. Esse é o retorno, o principal
dividido pelos juros. Esta é a primeira planilha do curso em que você calcula, então abra a planilha
que você preparou na aula 1 e acrescente uma aba nova.

## A planilha

Digite o cabeçalho e as quatro dívidas. As colunas D e E ficam vazias por enquanto.

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Dívida | Principal (h) | Juros (h/sprint) | Retorno (sprints) | Juros por ano (R$) |
| 2 | Reservas de assento | 320 | 31 | | |
| 3 | Gerador de PDF | 120 | 6 | | |
| 4 | Suíte ponta a ponta instável | 80 | 14 | | |
| 5 | Réplica antiga de relatórios | 200 | 4 | | |

Em D2, o retorno da dívida das reservas de assento, arredondado a uma casa decimal:

```localised
D2      =ARRED(B2/C2;1)      10,3
```

Agora copie D2 para baixo até D5. No LibreOffice, selecione D2 e arraste o quadradinho do canto
inferior direito até a linha 5; as referências acompanham cada linha:

```localised
D3      =ARRED(B3/C3;1)      20
D4      =ARRED(B4/C4;1)      5,7
D5      =ARRED(B5/C5;1)      50
```

A planilha mostra 20 e 50 sem decimal, porque arredondar a uma casa não deixou nada depois da
vírgula. Em E2, quanto os juros das reservas custam num ano — horas por sprint, vezes 26 sprints,
vezes R$ 150:

```localised
E2      =C2*26*150      120900
```

Copie E2 para baixo até E5 do mesmo jeito. As outras três dão 23400, 54600 e 15600.

## Três perguntas que a planilha responde

**Qual dívida se paga primeiro?** Pergunte à planilha em vez de ler a coluna de cima a baixo:

```localised
=ÍNDICE(A2:A5;CORRESP(MÍNIMO(D2:D5);D2:D5;0))      Suíte ponta a ponta instável
```

`MÍNIMO` acha o menor retorno, `CORRESP` acha em que linha ele está e `ÍNDICE` devolve o nome dessa
linha. A suíte custa 80 horas e devolve 14 por sprint, então se paga em 5,7 sprints — menos de doze
semanas.

Quanto as quatro custam juntas, toda sprint?

```localised
=SOMA(C2:C5)*150      8250
```

São R$ 8.250 por sprint, ou 55 horas de engenharia. E num ano:

```localised
=SOMA(E2:E5)      214500
```

**R$ 214.500 por ano, por quatro dívidas que ninguém decidiu pagar.** Em horas são 1.430 (55 × 26),
cerca de quatro quintos de um ano de engenheiro de 1.760 horas, gastos sem aparecer em linha nenhuma
do orçamento.

## Lendo a coluna de retorno

| dívida | principal (h) | retorno (sprints) |
|---|---|---|
| Suíte ponta a ponta instável | 80 | 5,7 |
| Reservas de assento | 320 | 10,3 |
| Gerador de PDF | 120 | 20 |
| Réplica antiga de relatórios | 200 | 50 |

Ordenada pelo principal, a lista começava pela suíte e terminava pelas reservas de assento. Ordenada
pelo retorno, a dívida das reservas sobe para segundo e a réplica cai para o fim. Cinquenta sprints
são quase dois anos (50 ÷ 26 = 1,9), e **uma dívida que leva dois anos para se pagar é uma dívida
para deixar quieta**, a não ser que algo fora da planilha force o trabalho. A aula 6 descreve como
esse algo se parece.

## O que a planilha não decide

O retorno põe a suíte em primeiro, e a estratégia da Coreto põe a dívida das reservas em primeiro.
Os dois podem estar certos, porque respondem a perguntas diferentes. O retorno conta horas. A dívida
das reservas também carrega o risco de uma grande abertura de vendas falhar, o que custa casas de
espetáculo, e que o diagnóstico da aula 1 nomeou como o desafio em torno do qual a estratégia inteira
foi construída.

**Então a planilha informa a estratégia e não a anula.** Ela diz que a suíte é barata e se paga rápido,
então quem cuida dos testes pode corrigi-la junto com o trabalho nas reservas. Diz que o gerador de
PDF vale a pena só quando um time já estiver trabalhando naquele código. E diz que a réplica pode
esperar, o que vale a pena ter por escrito na próxima vez que alguém propuser reconstruí-la porque
parece velha.

Duas suposições ficam embaixo de todo retorno da planilha, e as duas merecem ser conferidas antes de
citar um:

- que quitar o principal elimina os juros por inteiro — uma correção feita pela metade muitas vezes
  elimina só uma parte, e a planilha então exagera o retorno;
- que os juros ficam onde estão enquanto você espera. A próxima seção é sobre a dívida cujos juros
  não ficam.
