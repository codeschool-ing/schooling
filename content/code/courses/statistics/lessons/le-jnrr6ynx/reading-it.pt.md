---
title: Lendo um p-valor
version: 1
---

O p-valor se liga diretamente à regra de decisão da aula 13:

> **Rejeite a hipótese nula quando o p-valor estiver abaixo de α.**

Essa regra dá exatamente as mesmas decisões que comparar a estatística de teste com o valor crítico. Para o
teste do sistema de rotas, p = 0,165 está acima de 0,05, então a nula não é rejeitada; para a envasadora,
p = 0,0009 está abaixo de 0,05, então é rejeitada.

O p-valor carrega mais que a decisão, porém. O valor crítico dizia só "além da linha ou não". O p-valor diz
quanto além, ou quanto aquém.

## Uma escala de surpresa

P-valores menores significam dados que seriam mais surpreendentes se a nula fosse verdadeira:

| p-valor | sob a nula, dados tão extremos acontecem |
|---|---|
| 0,165 | cerca de uma vez em seis |
| 0,05 | uma vez em vinte |
| 0,01 | uma vez em cem |
| 0,0009 | cerca de uma vez em mil |

Um hábito útil é ler um p-valor como essa frase, e não como uma nota de corte.

## Não há precipício em 0,05

Um p-valor de 0,049 e um de 0,051 são, para qualquer efeito prático, a mesma evidência. Para os 24 graus de
liberdade do teste do sistema de rotas, eles correspondem a estatísticas t de −1,722 e −1,700: uma diferença
de 0,02 erro padrão. Um lado da linha é chamado de "significativo" e o outro não, e o rótulo os faz parecer
muito mais diferentes do que são.

Por isso um bom relatório dá o **p-valor exato**, não só "p < 0,05" ou "não significativo". Quem lê p = 0,06
sabe que os dados chegaram perto; quem lê "não significativo" pode achar que não chegaram nem perto.

## P-valores muito pequenos

Um p-valor nunca é exatamente zero, e um software que imprime "p = 0,000" arredondou. Informe "p < 0,001". E
um p-valor minúsculo não é um efeito grande: a aula 22 mostra uma diferença de uma fração de minuto no tempo
de entrega produzindo um p-valor menor que qualquer um desta aula, porque a amostra era enorme.
