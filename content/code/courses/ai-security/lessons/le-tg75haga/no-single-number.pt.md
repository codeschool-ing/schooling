---
title: Consertar uma diferença abre outra
version: 1
---

O conserto óbvio para uma razão de seleção de 0.62 é pré-selecionar mais candidatos do Nordeste até as
taxas baterem. O `data/shortlist-v2.csv` é a lista da Tarefa depois dessa mudança: um limiar mais baixo
para o Nordeste, escolhido para que a mesma parcela de cada região seja pré-selecionada. Como antes,
as contagens foram escritas pelo curso.

```
ana@lab:~/guard$ guard fairness data/shortlist-v2.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.56   0.80   0.32       0.71
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   1.00
  TPR gap           +0.00
  FPR gap           +0.12
  precision gap     -0.14
```

A razão de seleção é 1.00 e a diferença de TPR é zero: um bom freelancer é pré-selecionado 80% das
vezes em qualquer das regiões. Dois outros números andaram para o lado errado. A diferença de FPR foi
de −0.10 para +0.12, e a precisão no Nordeste caiu de 0.86 para 0.71. **Um cliente agora vê uma lista
do Nordeste em que mais de um candidato em quatro não consegue fazer o trabalho**, contra cerca de um
em sete do Sudeste. Os clientes vão perceber, e quem sai ferido são os freelancers do Nordeste, cuja
lista começa a parecer pouco confiável.

## Por que não dá para tudo ser igual

A causa está na coluna `base`, que nenhuma mudança na lista consegue mover: 60% dos candidatos do
Sudeste são bons, e 50% dos do Nordeste. Alexandra Chouldechova provou em 2017 que, quando as taxas de
base diferem, **nenhum classificador que comete erros consegue ter precisão, TPR e FPR iguais entre os
grupos ao mesmo tempo**, e Jon Kleinberg, Sendhil Mullainathan e Manish Raghavan provaram um parente
próximo disso para scores de risco em 2016. Iguale dois e o terceiro cede. A versão 1 manteve a
precisão igual e pagou em TPR; a versão 2 comprou TPR e pagou em precisão e FPR. Nenhuma das duas é um
bug da lista. É aritmética.

Essa aritmética supõe que as taxas de base são verdadeiras. Aqui elas vêm do julgamento de um revisor,
que é a linha de medição da primeira seção: se os revisores avaliam com mais dureza o trabalho vindo
do Nordeste, o 0.50 já é parte do viés, e igualar contra ele o cristaliza.

## Escolher é o trabalho

Então a pergunta que uma equipe precisa responder não é qual lista é justa, e sim **qual erro ela
aceita menos que caia de forma desigual**. Nomeie os dois erros pelo lado de quem os sofre:

- um **falso negativo** é um bom freelancer que nunca aparece, e perde o trabalho e a renda;
- um **falso positivo** é um cliente a quem mostram alguém que não consegue fazer o trabalho, e perde
  tempo.

Para um recurso que decide quem consegue trabalho, muitas equipes decidem que o erro do freelancer é
o mais grave e mantêm a diferença de TPR perto de zero, aceitando uma diferença de precisão e avisando
os clientes. Outra equipe pode decidir diferente. O que torna qualquer das duas defensável é a escolha
estar **registrada com os números dela**, no mesmo documento que a aula 12 chamou de RIPD: a métrica
escolhida, o motivo, as diferenças medidas, a data, e quando serão medidas de novo. É isso também que
um pedido de revisão pelo art. 20 da LGPD vai querer ver.

## O conserto para onde a medição aponta

As duas versões tratam o sintoma mexendo em limiares. A medição desta aula veio de um scorer com bônus
para CEPs do Sudeste, e a causa é esse bônus. Se um CEP tem algo a fazer no score depende do trabalho.
Para um logo feito à distância, não tem nada, e o conserto certo é o scorer parar de lê-lo. Para um
trabalho que exige alguém no local, a distância até o cliente é um requisito real, e a característica
honesta é a própria distância, não *"fica no Sudeste"*. A próxima seção é o teste que acha uma causa
como essa, uma decisão de cada vez.
