---
title: Um custo que caiu pelo motivo errado
version: 2
---

Por dia, a semana parece uma boa notícia:

```
ana@dev:~/obs$ python bill.py --by day
day                requests    input  output  cost US$  per 1k  share  features
Mon 28                   46     9704    1420    0.0308    0.67  21.5%  help/order/summary
Tue 29                   47     9996    1382    0.0311    0.66  21.7%  help/order/summary
Wed 30                   45    10037    1607    0.0247    0.55  17.2%  help/order/summary
Thu 01                   55     8356    1112    0.0192    0.35  13.4%  help/order/summary
Fri 02                   48     6137    1138    0.0160    0.33  11.2%  help/order/summary
Sat 03                   36     4631     662    0.0109    0.30   7.6%  help/order/summary
Sun 04                   34     4379     684    0.0107    0.31   7.4%  help/order/summary
total                   311    53240    8005    0.1434    0.46
```

O custo de mil pedidos caiu de 0,67 dólar na segunda para 0,30 no sábado. Quem acompanhasse essa
linha ficaria contente. Duas coisas diferentes a fizeram cair, e só uma delas é boa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Barras do custo de 1.000 pedidos em cada dia da semana reproduzida: 0,67 e 0,66 dólar na segunda e na terça, 0,55 na quarta, 0,35 na quinta, 0,33 na sexta, 0,30 no sábado e 0,31 no domingo. Uma linha antes da quarta marca o corte de preço de 30 de setembro; uma linha dentro da quinta marca a versão de 1º de outubro às 10h.\"><path d=\"M80 210 L692 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 170 L86 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M80 130 L86 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M80 90 L86 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M80 50 L86 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><rect x=\"90\" y=\"76\" width=\"64\" height=\"134\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,67</text><text x=\"122\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon 28</text><rect x=\"176\" y=\"78\" width=\"64\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,66</text><text x=\"208\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue 29</text><rect x=\"262\" y=\"100\" width=\"64\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,55</text><text x=\"294\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed 30</text><rect x=\"348\" y=\"140\" width=\"64\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,35</text><text x=\"380\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu 01</text><rect x=\"434\" y=\"144\" width=\"64\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"466\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,33</text><text x=\"466\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri 02</text><rect x=\"520\" y=\"150\" width=\"64\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"552\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,30</text><text x=\"552\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 03</text><rect x=\"606\" y=\"148\" width=\"64\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,31</text><text x=\"638\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M251 30 L251 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"247\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">corte de preço</text><path d=\"M374.7 30 L374.7 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"378.7\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">versão 2026.10.1</text><text x=\"380\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">US$ por 1.000 pedidos</text></svg>", "caption": "O custo por pedido caiu pela metade numa semana. Parte disso é a tabela de preços; a maior parte é o assistente respondendo menos."}
```

**A quarta-feira é a tabela de preços.** O preço do `llama3.2:3b` caiu 25% em 30 de setembro, e o
custo por mil foi de 0,66 para 0,55, uma queda de 17%. Nada no assistente mudou. A queda é menor que
a do preço porque os pedidos de quarta por acaso foram um pouco mais longos, 36 tokens de saída cada
contra 29 na terça: o ruído de um dia para o outro numa semana de quarenta e poucos pedidos por dia.

**A quinta em diante é a versão.** Na quinta às 10h o piso subiu, e dali em diante menos trechos
passaram por ele. O custo por mil caiu para 0,35, e ficou lá. A mesma semana separada por versão:

```
ana@dev:~/obs$ python bill.py --by release
release            requests    input  output  cost US$  per 1k  share  features
2026.09.4               150    31790    4645    0.0910    0.61  63.5%  help/order/summary
2026.10.1               161    21450    3360    0.0524    0.33  36.5%  help/order/summary
total                   311    53240    8005    0.1434    0.46
```

Sob a `2026.10.1`, um pedido levou em média 133 tokens de entrada (21.450 sobre 161); sob a
`2026.09.4`, 212. Os prompts ficaram mais curtos porque levam menos fontes, e mais pedidos foram
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
