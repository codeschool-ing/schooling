---
title: Quem fala, quem conserta, quem decide
version: 1
---

**Durante um incidente, quem está consertando não deveria ser também quem explica.** Cada minuto que
um engenheiro passa respondendo "o que está acontecendo?" num chat é um minuto a menos descobrindo, e
cada atualização escrita por alguém no meio da depuração sai na linguagem da depuração. Separar os
papéis é a mudança que mais melhora a comunicação de um incidente.

## Sexta, 6 de março

Às 19:09 de uma sexta, o horário de maior movimento da Marola, o checkout começou a falhar para quase
todos os clientes. Durou até 19:41: **32 minutos e cerca de 1.350 checkouts com falha.** A aula 15
trata do que causou isso e do que se aprendeu. Esta aula trata do que foi dito, e a quem, enquanto
acontecia e nos dias seguintes.

## Os papéis

A ideia vem do combate a incêndios. Nos anos 1970, depois de incêndios florestais na Califórnia em
que vários órgãos combateram o mesmo fogo sem uma estrutura comum, os bombeiros criaram o **Incident
Command System** (sistema de comando de incidentes): uma pessoa no comando, com papéis bem separados
abaixo dela. As operações de software pegaram a ideia emprestada, e o livro *Site Reliability
Engineering*, do Google, tornou essa versão conhecida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma comandante do incidente, Bruna, que coordena e decide, acima de três papéis: o líder de operações, Lucas, que diagnostica e corrige; a líder de comunicação, Lívia, que escreve toda atualização; e o escriba, Diego, que mantém a linha do tempo.\"><defs><marker id=\"incroles-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">comandante do incidente</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruna: coordena, decide</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">líder de operações</text><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lucas: diagnostica, corrige</text><path d=\"M360 78 L120 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><rect x=\"260\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">líder de comunicação</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lívia: toda atualização</text><path d=\"M360 78 L360 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><rect x=\"500\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">escriba</text><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego: a linha do tempo</text><path d=\"M360 78 L600 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a combinação a evitar: operações e comunicação na mesma pessoa</text></svg>", "caption": "Os papéis em 6 de março. Quem comanda não depura, e quem corrige o sistema não é quem o explica."}
```

| papel | faz | na Marola, em 6 de março |
|---|---|---|
| **comandante do incidente** | coordena, decide, mantém todo mundo apontado para o mesmo objetivo; não depura | Bruna, a engenheira de plantão, que declarou o incidente às 19:19 |
| **líder de operações** | trabalha no sistema: diagnostica, mitiga, conserta | Lucas, do time de plataforma |
| **líder de comunicação** | escreve todas as atualizações, internas e externas, em horários definidos | Lívia, que entrou às 19:22 |
| **escriba** | mantém a linha do tempo: o que foi visto, o que foi tentado, quando | Diego, que já estava no canal |

Num incidente pequeno, uma pessoa pode acumular dois papéis. **A única combinação a evitar é
operações e comunicação na mesma pessoa**: as atualizações param quando o problema está mais difícil,
que é justamente quando as pessoas mais querem notícias.

::: track tech-lead
As aulas 13 e 14 de `delivery-metrics`, mais cedo na sua trilha, montaram níveis de severidade, o
comandante do incidente e a linha do tempo como processo de um time. Esta aula senta na cadeira do
líder de comunicação e fica nela.
:::

::: track *
A aula 8 de `process-management` trata da gestão de incidentes como o ITIL a descreve, como um
processo. Esta aula ocupa uma cadeira desse processo, a do líder de comunicação, e fica nela.
:::

## Um canal

Às 19:19, Bruna abriu um canal só para o incidente e postou uma linha no canal de engenharia:
"Incidente no checkout, toda a discussão em #inc-0306." **Tudo sobre o incidente fica num lugar só**:
assim a linha do tempo fica completa, quem trabalha nele não precisa ler quatro conversas, e quem
quer saber o que está acontecendo sabe onde olhar sem perguntar.
