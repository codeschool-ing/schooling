---
title: Um escore z robusto
version: 1
---

O escore z falhou porque os dois ingredientes dele, a média e o desvio padrão, são puxados justamente pelos
valores que ele tenta achar. A solução é trocá-los por ingredientes robustos: a **mediana** para o centro,
e o **desvio absoluto mediano** para a dispersão.

## O MAD

O **desvio absoluto mediano**, ou **MAD** (da sigla em inglês), é a mediana das distâncias até a mediana:

1. ache a mediana;
2. calcule a distância de cada valor até ela, ignorando o sinal;
3. tire a mediana dessas distâncias.

Para as doze cestas com os dois erros, a mediana é R$ 68,20. As doze distâncias até ela, ordenadas, são
5,9, 5,9, 18,2, 20,4, 26,8, 32,6, 36,3, 49,7, 50,0, 55,3, 1.479,3 e 2.057,8. A mediana delas, no meio da sexta
e da sétima, é **R$ 34,45**.

Os dois erros produziram as duas distâncias enormes do fim, e a mediana das distâncias as ignorou, assim
como a mediana dos valores faz.

## O escore z modificado

A versão robusta do escore z, muitas vezes chamada de **escore z modificado**, é

```localised
z modificado = 0,6745 × (valor − mediana) ÷ MAD
```

O 0,6745 faz o escore z modificado coincidir com o comum quando os dados são normais: em dados normais, o
MAD vale cerca de 0,6745 desvio padrão. Uma regra comum, proposta por Boris Iglewicz e David Hoaglin, aponta
valores com escore z modificado além de **±3,5**.

Para os dois erros:

| valor | escore z | escore z modificado |
|---|---|---|
| R$ 2.126,00 | 2,52 | 40,29 |
| R$ 1.547,50 | 1,69 | 28,96 |

Os escores z comuns não apontaram nada. Os modificados põem os dois erros a dezenas de unidades, muito além
de 3,5. As cestas comuns, enquanto isso, ficam pequenas: R$ 95,00 tem z modificado de 0,52 e R$ 12,90, de
−1,08.

## Nos dados limpos

Sem os erros, as doze cestas corretas têm a mesma mediana, R$ 68,20, e o mesmo MAD, R$ 34,45, porque nenhum
dos dois dependia dos dois valores que mudaram. A maior cesta, R$ 212,60, tem z modificado de 2,83:
incomum, mas dentro de 3,5, então não é apontada. Isso bate com o que a aula 1 mostrou: H-1048 era um pedido
grande de Barão Geraldo, o bairro mais distante da Horta, e não um erro.

## A planilha não tem função de MAD

Nenhuma das planilhas comuns tem um MAD pronto, mas ele cabe numa fórmula, com os dados em A2:A13:

```localised
=MED(ABS(A2:A13 - MED(A2:A13)))      34,45
```

Ela trabalha sobre um intervalo inteiro de uma vez, então precisa ser inserida como **fórmula matricial**,
com Ctrl+Shift+Enter, nas planilhas que não fazem isso sozinhas. Inserida assim, o LibreOffice Calc devolveu
34,45 para as doze cestas com os dois erros. Inserida como fórmula comum, devolveu um erro, que é o sintoma a
reconhecer.
