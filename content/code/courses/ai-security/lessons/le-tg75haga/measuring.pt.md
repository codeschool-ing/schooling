---
title: Medir uma pré-seleção grupo a grupo
version: 1
---

Dezesseis perfis mostram o mecanismo e são poucos demais para medir qualquer coisa. A medição é feita
sobre a saída real da pré-seleção em muitas decisões, junto com um rótulo dizendo quais decisões
estavam certas. No laboratório, o `data/shortlist-v1.csv` é essa tabela: 312 candidatos, a região de
cada um, se um revisor depois os julgou capazes de fazer o trabalho (`good`) e se a pré-seleção os
escolheu. **As contagens foram escritas pelo curso**, a partir de uma tabela em
`guardlab/fairness.py`, para que as métricas tenham algo sobre o que discordar.

```
ana@lab:~/guard$ head -3 data/shortlist-v1.csv
applicant,region,good,shortlisted
fr-0001,Sudeste,1,1
fr-0002,Sudeste,1,1
ana@lab:~/guard$ guard fairness data/shortlist-v1.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.35   0.60   0.10       0.86
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   0.62   below the four-fifths line (0.80)
  TPR gap           -0.20
  FPR gap           -0.10
  precision gap     +0.00
```

## Cinco taxas, e a pergunta que cada uma responde

Cada coluna é uma taxa dentro de um grupo, e cada uma responde a uma pergunta diferente:

| coluna | de quem | a pergunta que responde |
|---|---|---|
| `base` | todos do grupo | quantos eram bons: a taxa de base |
| `selected` | todos do grupo | quantos a lista escolheu |
| `TPR` | os bons | dos que podiam fazer o trabalho, quantos foram pré-selecionados |
| `FPR` | os que não eram bons | dos que não podiam, quantos foram pré-selecionados mesmo assim |
| `precision` | os pré-selecionados | dos que o cliente viu, quantos podiam fazer o trabalho |

Leia a linha do Nordeste contra a do Sudeste com essas perguntas em mente.

**Seleção.** 35% dos candidatos do Nordeste são pré-selecionados contra 56% dos do Sudeste, e a razão
entre os dois é 0.62. A *regra dos quatro quintos* marca uma razão abaixo de 0.80 como impacto
adverso. Ela vem de diretrizes que reguladores de emprego dos Estados Unidos publicaram em 1978, e não
é lei no Brasil. Mesmo onde se aplica, é uma regra prática. Ainda assim é o primeiro filtro mais usado,
e 0.62 está bem abaixo dela. Exigir que as taxas de seleção sejam iguais se chama **paridade
demográfica**.

**TPR.** Dos freelancers do Nordeste que podiam fazer o trabalho, 60% foram pré-selecionados; dos do
Sudeste, 80%. A diferença de −0.20 é o bônus de CEP do substituto aparecendo no agregado: um bom
freelancer no Nordeste fica de fora duas vezes mais, 40% contra 20%. Exigir que essa diferença seja
zero se chama **igualdade de oportunidades**.

**Precisão.** 0.86 nas duas. Das pessoas que um cliente vê, a mesma parcela consegue fazer o trabalho,
more onde morar. Exigir isso se chama **paridade preditiva**, e por ela a lista é justa.

Essa última linha é o que torna isto difícil. **Um cliente olhando a precisão vê uma lista justa; um
freelancer olhando a TPR vê uma injusta.** Os dois leem a mesma tabela corretamente. A métrica com que
um relatório abre decide o que o relatório conclui, e essa escolha costuma ser feita sem ninguém
perceber que era uma escolha.

## O grupo que a tabela se recusa a medir

O Norte tem 12 candidatos, e a ferramenta não imprime taxa nenhuma para ele. Com 6 candidatos bons, um
pré-selecionado a mais ou a menos move a TPR em 0.17, então qualquer diferença que ela mostrasse seria
quase toda acaso. O corte de 30 é o mesmo que a análise de itens desta própria plataforma usa antes de
julgar uma questão.

Recusar é melhor do que imprimir um número que ninguém deveria ler, e ainda assim é um achado: **o
grupo medido pior costuma ser o grupo com mais a perder com um modelo ruim**, que é a linha de
representação da seção anterior. O remédio é coletar mais decisões antes de concluir qualquer coisa
sobre o Norte, e não tirar a região do relatório porque a linha dela está vazia.
