---
title: As quatro métricas DORA
version: 1
---

As medidas de entrega mais usadas do setor vêm de um único programa de pesquisa. O grupo **DevOps Research and Assessment**, o DORA, ouviu dezenas de milhares de profissionais de tecnologia a partir de 2014 nos relatórios anuais *State of DevOps*, e Nicole Forsgren, Jez Humble e Gene Kim resumiram as conclusões em *Accelerate* (2018) — o livro que a aula 8 citou sobre aprovação de mudanças. O Google comprou o DORA em 2018, e os relatórios continuam.

A pesquisa concluiu que quatro medidas, tomadas juntas, separam as organizações que entregam software bem das que não entregam, e que as melhores também se saem melhor em resultados organizacionais como lucratividade e participação de mercado.

## Dois pares

- **Frequência de deploy** — com que frequência o time implanta em produção.
- **Lead time de mudanças** — quanto tempo uma mudança commitada leva para chegar à produção.
- **Taxa de falha de mudanças** — que proporção dos deploys causa uma falha que precisa de correção.
- **Tempo de restauração do serviço** — quanto tempo leva para se recuperar de uma falha dessas. Desde o relatório de 2023 se chama *tempo de recuperação de deploy com falha* (failed deployment recovery time).

Os dois primeiros medem **vazão**, quão rápido as mudanças fluem. Os dois últimos medem **estabilidade**, com que frequência elas causam dano. A conclusão central da pesquisa é que os dois pares **não se trocam um pelo outro**: as organizações que fazem deploy com mais frequência também falham menos e se recuperam mais rápido, porque mudanças pequenas e frequentes são mais fáceis de testar, de entender e de desfazer.

## O março do time Agenda

O time fez **24 deploys** nos 20 dias úteis de março. Três desses deploys causaram falhas que precisaram de correção, restauradas em 45, 50 e 180 minutos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l13-dora\" aria-label=\"Quatro blocos em dois pares. Vazão: frequência de deploy de 1,2 por dia, 24 deploys em 20 dias úteis; lead time de mudanças de 6 horas, a mediana do commit à produção. Estabilidade: taxa de falha de mudanças de 12,5%, 3 de 24 deploys precisaram de correção; tempo de restauração de 50 minutos, a mediana das três falhas.\"><text x=\"170.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">vazão: quão rápido as mudanças fluem</text><text x=\"510.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">estabilidade: com que frequência causam dano</text><rect x=\"14.0\" y=\"36.0\" width=\"156.0\" height=\"180.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"92.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">frequência de deploy</text><text x=\"92.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--phosphor)\">1,2 por dia</text><text x=\"92.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">24 deploys em 20 dias úteis</text><rect x=\"180.0\" y=\"36.0\" width=\"156.0\" height=\"180.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"258.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lead time de mudanças</text><text x=\"258.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--phosphor)\">6 horas</text><text x=\"258.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">mediana, do commit à produção</text><rect x=\"346.0\" y=\"36.0\" width=\"156.0\" height=\"180.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"424.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">taxa de falha de mudanças</text><text x=\"424.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--amber)\">12,5%</text><text x=\"424.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">3 de 24 deploys pediram correção</text><rect x=\"512.0\" y=\"36.0\" width=\"156.0\" height=\"180.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"590.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tempo de restauração</text><text x=\"590.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--amber)\">50 minutos</text><text x=\"590.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">mediana das três falhas</text></svg>", "caption": "Os quatro números DORA do time Agenda em março de 2026. Dois dizem quão rápido as mudanças chegam aos usuários e dois dizem com que frequência causam dano; ler um par sem o outro premia um time por quebrar coisas rápido ou por nunca entregar."}
```

Estes são os vinte e quatro deploys do time em março, em ordem. Digite-os numa folha nova com os cabeçalhos na linha 1, para que os deploys fiquem nas linhas 2 a 25 — horas do commit à produção na coluna B, um 1 na coluna C para deploy com falha, e os minutos de restauração na coluna D:

| Deploy | Horas de lead time | Falhou | Minutos para restaurar |
|---|---|---|---|
| 1 | 3 | 0 |  |
| 2 | 5 | 0 |  |
| 3 | 26 | 0 |  |
| 4 | 4 | 0 |  |
| 5 | 7 | 0 |  |
| 6 | 22 | 1 | 45 |
| 7 | 6 | 0 |  |
| 8 | 2 | 0 |  |
| 9 | 30 | 0 |  |
| 10 | 8 | 0 |  |
| 11 | 5 | 0 |  |
| 12 | 4 | 0 |  |
| 13 | 49 | 0 |  |
| 14 | 6 | 1 | 180 |
| 15 | 3 | 0 |  |
| 16 | 21 | 0 |  |
| 17 | 9 | 0 |  |
| 18 | 4 | 0 |  |
| 19 | 27 | 0 |  |
| 20 | 5 | 0 |  |
| 21 | 7 | 1 | 50 |
| 22 | 70 | 0 |  |
| 23 | 6 | 0 |  |
| 24 | 4 | 0 |  |

Com eles no lugar, nas fórmulas de uma planilha em português, o LibreOffice devolveu:

```localised
=CONT.NÚM(B2:B25)/20                1,2
=MED(B2:B25)                        6
=SOMA(C2:C25)/CONT.NÚM(B2:B25)      0,125
=MED(D2:D25)                        50
=CONT.SE(B2:B25;">24")              5
```

Em inglês as funções são `COUNT`, `MEDIAN`, `SUM` e `COUNTIF`.

## Lendo o lead time

A mediana de **6 horas** descreve bem uma mudança típica. A média, 13,88 horas, é puxada para cima por algumas longas, a mesma assimetria que a aula 3 encontrou nos tempos de ciclo, e por isso a mediana é o número a citar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 280\" role=\"img\" data-fig=\"l13-lead-times\" aria-label=\"Vinte e quatro pontos, um por deploy em março de 2026, cada um nas horas que sua mudança levou do commit à produção. A maioria fica abaixo de 10 horas; cinco ficam acima de 24 horas, a mais longa em 70. Uma linha marca a mediana de 6 horas. Três pontos estão marcados como deploys que falharam em produção.\"><path d=\"M70.0 40.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 220.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 162.4 L600.0 162.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 162.4 L70.0 162.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"162.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><path d=\"M70.0 104.8 L600.0 104.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 104.8 L70.0 104.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"104.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">48</text><path d=\"M70.0 47.2 L600.0 47.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 47.2 L70.0 47.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"47.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">72</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">horas do commit à produção</text><path d=\"M70.0 220.0 L600.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M91.2 220.0 L91.2 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"91.2\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M197.2 220.0 L197.2 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"197.2\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M324.4 220.0 L324.4 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"324.4\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M451.6 220.0 L451.6 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"451.6\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M578.8 220.0 L578.8 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"578.8\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><text x=\"335.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">deploys em março de 2026, em ordem</text><path d=\"M70.0 162.4 L600.0 162.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"600.0\" y=\"154.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um dia</text><path d=\"M70.0 205.6 L600.0 205.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"600.0\" y=\"196.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">mediana de 6 horas</text><circle cx=\"91.2\" cy=\"212.8\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"112.4\" cy=\"208.0\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"133.6\" cy=\"157.6\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"154.8\" cy=\"210.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"176.0\" cy=\"203.2\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"197.2\" cy=\"167.2\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"218.4\" cy=\"205.6\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"239.6\" cy=\"215.2\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"260.8\" cy=\"148.0\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"282.0\" cy=\"200.8\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"303.2\" cy=\"208.0\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"324.4\" cy=\"210.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"345.6\" cy=\"102.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"366.8\" cy=\"205.6\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"388.0\" cy=\"212.8\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"409.2\" cy=\"169.6\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"430.4\" cy=\"198.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"451.6\" cy=\"210.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"472.8\" cy=\"155.2\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"494.0\" cy=\"208.0\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"515.2\" cy=\"203.2\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"536.4\" cy=\"52.0\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"557.6\" cy=\"205.6\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"578.8\" cy=\"210.4\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"450.0\" cy=\"20.0\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"460.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falhou em produção</text></svg>", "caption": "A mediana de 6 horas é um resumo justo de uma mudança típica; as cinco mudanças que esperaram mais de um dia são onde está a próxima melhoria, e vale lê-las uma a uma."}
```

As cinco mudanças que levaram **mais de um dia** são onde olhar em seguida. Se foram as que esperaram uma aprovação semanal, o argumento da aula 8 sobre mudanças padrão se aplica; se esperaram uma revisão de código na sexta à tarde, o remédio está nos hábitos do próprio time.

## O que os quatro números não dizem

As métricas DORA medem o **pipeline de entrega**: de uma mudança commitada a uma mudança rodando em produção. Elas não dizem nada sobre se a coisa certa foi construída, se os usuários estão satisfeitos, ou quanto tempo uma ideia esperou antes de alguém commitar código para ela. Um time pode ter números DORA excelentes e um produto que ninguém usa. Elas medem uma capacidade, valiosa, e a pesquisa nunca afirmou mais que isso.
