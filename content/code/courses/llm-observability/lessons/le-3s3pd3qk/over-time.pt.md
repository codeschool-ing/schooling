---
title: Um custo que caiu pelo motivo errado
version: 1
---

Por dia, a semana parece uma boa notícia:

```
ana@lab:~/obs$ python bill.py --by day
day                requests    input  output  cost US$  per 1k  share  features
Mon 28                  200    46627    7594    0.1541    0.77  18.7%  help/order/summary
Tue 29                  210    48889    8259    0.1639    0.78  19.9%  help/order/summary
Wed 30                  207    51814    7772    0.1658    0.80  20.2%  help/order/summary
Thu 01                  208    51089    7742    0.1231    0.59  15.0%  help/order/summary
Fri 02                  224    39663    7039    0.1018    0.45  12.4%  help/order/summary
Sat 03                  153    21175    4117    0.0565    0.37   6.9%  help/order/summary
Sun 04                  143    21815    4140    0.0576    0.40   7.0%  help/order/summary
total                  1345   281072   46663    0.8228    0.61
```

O custo de mil pedidos caiu de 0,80 dólar na quarta para 0,37 no sábado. Quem acompanhasse essa linha
ficaria contente. Duas coisas diferentes a fizeram cair, e só uma delas é boa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Barras do custo de 1.000 pedidos em cada dia da semana reproduzida: 0,77, 0,78 e 0,80 dólar de segunda a quarta, 0,59 na quinta, 0,45 na sexta, 0,37 no sábado e 0,40 no domingo. Uma linha antes da quinta marca o corte de preço de 1º de outubro; uma linha dentro da sexta marca a versão de 2 de outubro às 10h.\"><path d=\"M80 210 L692 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 170 L86 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M80 130 L86 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M80 90 L86 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M80 50 L86 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><rect x=\"90\" y=\"56\" width=\"64\" height=\"154\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,77</text><text x=\"122\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon 28</text><rect x=\"176\" y=\"54\" width=\"64\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,78</text><text x=\"208\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue 29</text><rect x=\"262\" y=\"50\" width=\"64\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,80</text><text x=\"294\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed 30</text><rect x=\"348\" y=\"92\" width=\"64\" height=\"118\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,59</text><text x=\"380\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu 01</text><rect x=\"434\" y=\"120\" width=\"64\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"466\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,45</text><text x=\"466\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri 02</text><rect x=\"520\" y=\"136\" width=\"64\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"552\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,37</text><text x=\"552\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 03</text><rect x=\"606\" y=\"130\" width=\"64\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,40</text><text x=\"638\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M337 30 L337 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"333\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">corte de preço</text><path d=\"M460.667 30 L460.667 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"464.667\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">versão 2026.10.1</text><text x=\"380\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">US$ por 1.000 pedidos</text></svg>", "caption": "O custo por pedido caiu pela metade numa semana. Parte disso é a tabela de preços; a maior parte é o assistente respondendo menos."}
```

**A quinta-feira é a tabela de preços.** O preço do extract-1 caiu 25% em 1º de outubro, e o custo por
mil foi de 0,80 para 0,59, uma queda de 26%. Nada no assistente mudou; os tokens por pedido foram os
mesmos da quarta, dentro do ruído de um dia para o outro.

**A sexta e o fim de semana são a versão.** Na sexta às 10h o piso subiu, e dali em diante menos
trechos passaram por ele. A mesma semana separada por versão:

```
ana@lab:~/obs$ python bill.py --by release
release            requests    input  output  cost US$  per 1k  share  features
2026.09.4               879   212233   33434    0.6401    0.73  77.8%  help/order/summary
2026.10.1               466    68839   13229    0.1827    0.39  22.2%  help/order/summary
total                  1345   281072   46663    0.8228    0.61
```

Sob a `2026.10.1`, um pedido levou em média 148 tokens de entrada (68.839 sobre 466); sob a
`2026.09.4`, 241. Os prompts ficaram mais curtos porque levam menos fontes, e mais pedidos foram
recusados antes de qualquer prompt ser montado. **O assistente ficou mais barato porque responde
menos**, e a aula 5 descobre se os clientes perceberam.

## Separando preço de uso

Dois números, mantidos separados, são o que torna isso legível:

- **tokens por pedido**, que só mudam quando o sistema muda: o prompt, a recuperação, os hábitos do
  modelo, a mistura de funcionalidades;
- **preço por token**, que só muda quando a tabela de preços muda.

O custo por pedido é o produto dos dois, e uma mudança nele é sempre um, o outro, ou os dois. A coluna
de custo mostra os dois ao mesmo tempo e não sabe dizer qual; as colunas de tokens ao lado dela, que
nenhuma tabela de preços consegue mexer, sabem. **Registre tokens no span e calcule o dinheiro na hora
de ler**, como faz o `costs.py`, e os dois continuam separáveis enquanto os spans existirem.
