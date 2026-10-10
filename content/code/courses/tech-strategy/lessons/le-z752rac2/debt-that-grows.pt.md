---
title: A dívida que cresce
version: 1
---

A planilha de retorno trata os juros como uma constante: 31 horas nesta sprint, 31 na próxima, 31
daqui a um ano. **Algumas dívidas cobram mais a cada sprint**, porque código novo continua sendo
construído em cima delas, e para essas o retorno da planilha é o caso otimista, não o esperado.

## Por que os juros sobem

O travamento das reservas de assento é o exemplo. Cada funcionalidade que encosta numa reserva — um
tipo novo de ingresso, uma mudança no fluxo do checkout, uma tela do aplicativo da Bilheteria — é
escrita em volta dos travamentos de linha. Cada uma vira mais uma coisa para ensaiar e revisar, e
mais uma coisa para manter funcionando no dia em que os travamentos finalmente forem removidos. Os
contornos são pagos em juros, e cada um aumenta os juros que vêm depois dele.

Quando o Davi mediu a dívida das reservas de novo algumas sprints depois, os juros tinham crescido
cerca de 2 horas por sprint. Partindo de 31, são 33 na sprint seguinte, 35 na outra, e 57 na sprint
14 — quase o dobro de onde começaram.

## Deixar ou pagar

Deixar a dívida custa os seus juros toda sprint, e o total acumulado sobe. Pagá-la custa as 320
horas do principal, uma vez. **A sprint em que o total acumulado de juros passa de 320 é a sprint em
que deixar a dívida já custou mais do que pagá-la teria custado.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Um gráfico de linhas das horas pagas contra as sprints de 0 a 14. Uma linha âmbar reta em 320 horas é o custo de pagar a dívida de uma vez. Uma linha tracejada, juros fixos de 31 horas por sprint, cruza essa linha depois da sprint 11. Uma linha cheia, juros que sobem 2 horas por sprint, cruza depois da sprint 9, em 351 horas, e chega a 616 horas na sprint 14.\"><path d=\"M76 300.0 L680 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"304.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M76 260.0 L80 260.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><path d=\"M76 220.0 L80 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"224.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M76 180.0 L80 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"184.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300</text><path d=\"M76 140.0 L80 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"144.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M76 100.0 L80 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"104.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">500</text><path d=\"M76 60.0 L80 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"72\" y=\"64.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><text x=\"80.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"122.9\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"165.7\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"208.6\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"251.4\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"294.3\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"337.1\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"380.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"422.9\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"465.7\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"508.6\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"551.4\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><text x=\"594.3\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"637.1\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">13</text><text x=\"680.0\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><text x=\"380.0\" y=\"344\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">sprints a partir de hoje</text><text x=\"50\" y=\"24\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">horas pagas até agora</text><path d=\"M80.0 172.0 L680.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><polyline points=\"80.0,300.0 122.9,287.6 165.7,275.2 208.6,262.8 251.4,250.4 294.3,238.0 337.1,225.6 380.0,213.2 422.9,200.8 465.7,188.4 508.6,176.0 551.4,163.6 594.3,151.2 637.1,138.8 680.0,126.4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></polyline><polyline points=\"80.0,300.0 122.9,287.6 165.7,274.4 208.6,260.4 251.4,245.6 294.3,230.0 337.1,213.6 380.0,196.4 422.9,178.4 465.7,159.6 508.6,140.0 551.4,119.6 594.3,98.4 637.1,76.4 680.0,53.6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><circle cx=\"465.7\" cy=\"159.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"551.4\" cy=\"163.6\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"455.7\" y=\"147.6\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">depois da sprint 9: 351 h</text><text x=\"561.4\" y=\"193.6\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">depois da sprint 11: 341 h</text><rect x=\"90\" y=\"44\" width=\"300\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><path d=\"M100 58 L132 58\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"140\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deixar, juros subindo 2 h por sprint</text><path d=\"M100 80 L132 80\" stroke=\"var(--paper-dim)\" stroke-width=\"2.5\" stroke-dasharray=\"6 4\"></path><text x=\"140\" y=\"84\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deixar, juros fixos de 31 h</text><path d=\"M100 102 L132 102\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"140\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pagar de uma vez: 320 h</text></svg>", "caption": "A dívida da reserva de assentos, deixada ou paga. Onde uma linha de juros cruza as 320 horas da correção, deixar a dívida já custou mais do que pagá-la teria custado — duas sprints antes quando os juros sobem."}
```

Com os juros fixos, o total acumulado é de 310 horas depois da sprint 10 e de 341 depois da sprint
11, então ele cruza o principal depois da sprint 11. Com os juros subindo 2 horas por sprint, são 304
depois da sprint 8 e 351 depois da sprint 9: ele cruza **depois da sprint 9**, duas sprints — um mês
— antes.

A distância continua aumentando depois disso. Na sprint 14 os juros fixos teriam somado 434 horas
(31 × 14), e os que sobem, 616. A diferença é de 182 horas, R$ 27.300 a R$ 150, gastos com nada além
de esperar.

## Monte na sua planilha

Acrescente outra aba e dê a ela três colunas. A linha 2 guarda a primeira sprint; da linha 3 em
diante, cada linha soma 2 horas aos juros de cima e soma os novos juros ao total acumulado:

| | A | B | C |
|---|---|---|---|
| 1 | Sprint | Juros (h) | Pago até agora (h) |
| 2 | 1 | 31 | `=B2` |
| 3 | 2 | `=B2+2` | `=C2+B3` |

Preencha A até 14 e copie B3 e C3 para baixo até a linha 15. A coluna C deve mostrar 31, 64, 99 e
assim por diante, e a linha 10 — a sprint 9 — é a primeira a passar de 320, com 351. Troque o 2 de B3
por 0 e copie para baixo de novo, e o primeiro valor acima de 320 vai para a linha 12, a sprint 11.
Essa única célula é toda a diferença entre as duas linhas da figura.

## O que uma dívida que cresce muda

**Uma dívida que cresce pode ser combatida parando o crescimento, além de pagando o principal.** Os
juros sobem porque código continua sendo construído em cima da dívida, então tudo o que freia a
construção freia a subida. A estratégia da Coreto na aula 1 faz as duas coisas. O time de Reservas
revisa toda mudança no código das reservas de assento, o que reduz o número de contornos novos, e os
dois primeiros trimestres do time vão para o caminho das reservas, começando por remover os
travamentos, o que paga o principal. A regra de
revisão valeria a pena mesmo se a remoção atrasasse.

O principal também costuma crescer. Cada contorno é mais uma coisa que a correção precisa tratar,
então as 320 horas de hoje viram mais se o trabalho esperar. A planilha mantém o principal fixo para
simplificar, o que faz esperar parecer mais barato do que é.

Meça mais de uma vez. Uma única medição de juros não mostra tendência; medir a mesma dívida um
trimestre depois diz quais dívidas estão crescendo, e essas sobem na lista seja qual for o retorno
que mostram hoje.

Compare com a réplica de relatórios. Ninguém constrói nada novo em cima dela, então os seus juros
ficam em 4 horas por sprint, e o seu retorno de 50 sprints quer dizer o mesmo no ano que vem que
agora. **Uma dívida fixa pode esperar pelo seu retorno; uma que cresce fica mais cara de deixar a
cada sprint**, e essa diferença merece um lugar no registro ao lado dos dois números.
