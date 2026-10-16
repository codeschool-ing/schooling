---
title: O objetivo, e o orçamento que ele deixa
version: 1
---

Um objetivo é uma meta para o indicador numa janela: **99,9% das requisições funcionam, numa janela
móvel de 30 dias**. O número interessante é o que sobra. Se 99,9% precisam funcionar, 0,1% pode falhar,
e esse 0,1% é o **orçamento de erro**: a falha que a equipe combinou que é aceitável, e pode gastar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um gráfico do orçamento de erro restante em 30 dias, de 100% até zero. Com taxa de queima 1 a linha chega a zero exatamente no dia 30. Com 6 chega a zero no dia 5. Com 14,4 chega a zero depois de uns 2 dias.\"><defs><marker id=\"bud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 30 L70 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 220 L630 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"62\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"62\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"70.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"256.66666666666663\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"443.3333333333333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"630.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"630\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dias</text><path d=\"M70 30 L630.0 220\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"378.0\" y=\"119.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">queima 1: dura o mês</text><path d=\"M70 30 L163.3 220\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"169.33333333333331\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6: acaba em 5 dias</text><path d=\"M70 30 L108.9 220\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"114.88888888888889\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">14,4: acaba em uns 2 dias</text><text x=\"70\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">orçamento de erro restante, 99,9% em 30 dias</text></svg>", "caption": "A taxa de queima é a inclinação. Um alerta nela pergunta quando o mês acaba, não quão ruim está este minuto."}
```

Em requisições, às mil por minuto da loja: 43.200.000 requisições em 30 dias, das quais 43.200 podem
falhar. Em tempo, para uma queda que falha tudo: 0,1% de 30 dias são **43,2 minutos**. A tabela é a
mesma conta com outras metas:

| objetivo | orçamento em 30 dias, como tempo | requisições falhas a 1.000 por minuto |
|---|---|---|
| 99% | 7 h 12 min | 432.000 |
| 99,5% | 3 h 36 min | 216.000 |
| 99,9% | 43,2 min | 43.200 |
| 99,95% | 21,6 min | 21.600 |
| 99,99% | 4,3 min | 4.320 |

Cada nove divide o orçamento por dez, e o custo de conquistá-lo se multiplica: em 99,99%, um único
deploy que falha por cinco minutos gasta mais que o mês. **Escolha o objetivo mais baixo de que os
clientes não reclamariam**, não o mais alto que a equipe consegue imaginar; o objetivo é uma promessa,
e o orçamento é o que torna possível continuar lançando.

## Para que serve o orçamento

Um orçamento troca discussões por aritmética. Enquanto sobra orçamento, a equipe lança funcionalidades
e corre riscos: canários, migrações, experimentos. Quando ele acaba, vale a **política de orçamento**
combinada: os próximos releases são trabalho de confiabilidade, os deploys desaceleram, e a mudança
arriscada espera. Nenhum lado precisa vencer um debate sobre se o serviço é confiável o bastante; o
número diz.

A política só funciona se for escrita antes de ser necessária, assinada por quem decide as
prioridades, e seguida na primeira vez que morder. Um orçamento em que ninguém age é um painel.
