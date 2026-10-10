---
title: Uma regra de reposição
version: 1
---

O depósito de Contagem manda carretéis de mangueira de jardim para as nove lojas e para os clientes
online. O Caio Barreto, diretor de operações, quer uma regra que a equipe siga sem perguntar a
ninguém: **quando o estoque cair a um certo número, peça mais.** Esse número é o ponto de pedido, e é
a análise prescritiva mais simples que existe.

## A ideia

Um pedido demora para chegar, então tem de sair enquanto ainda há estoque suficiente para cobrir a
espera. Se o depósito expede 18 carretéis por dia e o fornecedor leva 7 dias, um pedido feito com
126 carretéis na prateleira chega bem quando o último sai, mas só se nada der errado. Entregas
atrasam, e alguns dias vendem mais que outros. Então a regra acrescenta uma folga, o **estoque de
segurança**:

ponto de pedido = demanda média diária × (prazo de entrega + dias de segurança)

Os dias de segurança são uma escolha, e o Caio a tirou do histórico: no último ano, a entrega mais
atrasada do fornecedor chegou com quatro dias de atraso. Quatro dias de segurança cobrem o pior
atraso visto até agora.

## Na planilha

Acrescente uma aba. Digite os carretéis expedidos em 14 dias de setembro de 2025, a partir de A1:

| | A | B |
|---|---|---|
| 1 | Dia | Carretéis |
| 2 | 1 | 15 |
| 3 | 2 | 19 |
| 4 | 3 | 17 |
| 5 | 4 | 22 |
| 6 | 5 | 16 |
| 7 | 6 | 18 |
| 8 | 7 | 20 |
| 9 | 8 | 14 |
| 10 | 9 | 19 |
| 11 | 10 | 21 |
| 12 | 11 | 17 |
| 13 | 12 | 18 |
| 14 | 13 | 16 |
| 15 | 14 | 20 |

Abaixo deles, de A16 a A20, digite `Média`, `Maior`, `Prazo`, `Dias de segurança` e
`Ponto de pedido`. Em B18 digite `7` e em B19 `4`. Depois:

```localised
=ARRED(MÉDIA(B2:B15);0)      18
=MÁXIMO(B2:B15)      22
=B16*(B18+B19)      198
```

**O ponto de pedido é 198 carretéis.** Sete dias de demanda são 126 deles e o estoque de segurança é
o resto, 72. O maior dia, 22, está ali para manter a média honesta: uma variação de 14 a 22 é normal
para esse produto, e nenhum dia isolado está longe o bastante para sugerir um erro nos dados.

## Quando o prazo muda

Em março de 2026 o fornecedor avisou que as entregas passariam a levar 10 dias em vez de 7. A regra
é uma fórmula, então a correção é uma célula: digite `10` em B18, e B20 vira 252. **O perigo é a regra
que ninguém atualiza.** Com o ponto antigo de 198 e um prazo de dez dias, o estoque está em 18
carretéis quando uma entrega no prazo chega: um dia de vendas, em vez de quatro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma linha dos carretéis em estoque ao longo de seis semanas. Ela cai 18 por dia a partir de 396. Toda vez que chega ao ponto de pedido de 198, uma linha tracejada, sai um pedido de 360. Com sete dias de prazo, a entrega chega com 72 carretéis ainda na prateleira, o estoque de segurança. Uma segunda linha, para dez dias de prazo e o mesmo ponto de pedido, está em 18 carretéis, um dia de vendas, quando cada entrega chega.\" data-fig=\"l09-stock\"><path d=\"M60.0 260.0 L700.0 260.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 186.7 L700.0 186.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"190.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M60.0 113.3 L700.0 113.3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"117.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M60.0 40.0 L700.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><text x=\"60.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"166.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"273.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><text x=\"380.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">21</text><text x=\"486.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">28</text><text x=\"593.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">35</text><text x=\"700.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">42</text><text x=\"380.0\" y=\"298.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias</text><path d=\"M60.0 187.4 L700.0 187.4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><text x=\"66.0\" y=\"181.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ponto de pedido: 198</text><path d=\"M60.0 114.8 L75.2 121.4 L90.5 128.0 L105.7 134.6 L121.0 141.2 L136.2 147.8 L151.4 154.4 L166.7 161.0 L181.9 167.6 L197.1 174.2 L212.4 180.8 L227.6 187.4 L242.9 194.0 L258.1 200.6 L273.3 207.2 L288.6 213.8 L303.8 220.4 L319.0 227.0 L334.3 233.6 L349.5 240.2 L364.8 246.8 L380.0 253.4 L380.0 121.4 L395.2 128.0 L410.5 134.6 L425.7 141.2 L441.0 147.8 L456.2 154.4 L471.4 161.0 L486.7 167.6 L501.9 174.2 L517.1 180.8 L532.4 187.4 L547.6 194.0 L562.9 200.6 L578.1 207.2 L593.3 213.8 L608.6 220.4 L623.8 227.0 L639.0 233.6 L654.3 240.2 L669.5 246.8 L684.8 253.4 L684.8 121.4 L700.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 3\"></path><path d=\"M60.0 114.8 L75.2 121.4 L90.5 128.0 L105.7 134.6 L121.0 141.2 L136.2 147.8 L151.4 154.4 L166.7 161.0 L181.9 167.6 L197.1 174.2 L212.4 180.8 L227.6 187.4 L242.9 194.0 L258.1 200.6 L273.3 207.2 L288.6 213.8 L303.8 220.4 L319.0 227.0 L334.3 233.6 L334.3 101.6 L349.5 108.2 L364.8 114.8 L380.0 121.4 L395.2 128.0 L410.5 134.6 L425.7 141.2 L441.0 147.8 L456.2 154.4 L471.4 161.0 L486.7 167.6 L501.9 174.2 L517.1 180.8 L532.4 187.4 L547.6 194.0 L562.9 200.6 L578.1 207.2 L593.3 213.8 L608.6 220.4 L623.8 227.0 L639.0 233.6 L639.0 101.6 L654.3 108.2 L669.5 114.8 L684.8 121.4 L700.0 128.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M227.6 221.4 L227.6 193.4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M227.6 193.4 L231.5 201.5 L223.7 201.5 Z\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M532.4 221.4 L532.4 193.4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M532.4 193.4 L536.3 201.5 L528.5 201.5 Z\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"233.6\" y=\"231.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido de 360</text><path d=\"M70.0 18.0 L94.0 18.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"100.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prazo de 7 dias: mínimo de 72</text><path d=\"M390.0 18.0 L414.0 18.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 3\"></path><text x=\"420.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prazo de 10 dias, mesmo ponto: mínimo de 18</text></svg>", "caption": "A regra de reposição em seis semanas. O ponto de 198 deixa quatro dias de folga quando o fornecedor leva sete dias. Quando o fornecedor passa a levar dez e ninguém muda o ponto, sobra um dia, e qualquer entrega atrasada esvazia a prateleira."}
```

E o histórico diz que as entregas atrasam até quatro dias. Com 198 carretéis a prateleira cobre 11
dias; um prazo de dez dias mais quatro de atraso precisa de 14. **A prateleira ficaria vazia por três
dias, uns 54 carretéis de vendas perdidas**, e nenhum deles apareceria nos dados de venda, porque uma
venda que não acontece não deixa cupom. Essa é a armadilha que a aula 8 descreveu, e aqui ela é todo
o custo de uma célula deixada sem mudar.

Então uma regra de reposição é uma fórmula mais as suas entradas, e as entradas precisam de dono.
Alguém tem de perceber quando o fornecedor muda o prazo, e a regra tem de mostrar as entradas com que
foi calculada, para que um leitor veja que 7 não é mais verdade.
