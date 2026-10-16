---
title: Dinheiro em cada corte
version: 1
---

A aula 10 julgou o modelo em cinco cortes e achou mais dinheiro em 0,2, não no 0,278 que os custos
apontavam. Antes de perguntar por quê, desenhe o quadro inteiro: **o valor líquido em cada corte**,
nos meses de teste, a partir das chances que a aula 10 salvou. Se o `scores.csv` não estiver em
`~/ml`, rode de novo o `scores.py` da aula 10; leva alguns segundos. Salve isto como `sweep.py`:

```python
# sweep.py
import pandas as pd

from feira import CREDIT, KEPT, SAVED, net_value

scores = pd.read_csv("scores.csv")
print(f"break-even cut: {CREDIT / (SAVED * KEPT):.3f}")
print("cut     sent   net value")
for cut in [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]:
    send = scores["chance"] >= cut
    print(f"{cut:<5.2f} {send.sum():6,}  R$ {net_value(scores['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python sweep.py
break-even cut: 0.278
cut     sent   net value
0.05   5,405  R$  -76,520
0.10   2,589  R$    1,848
0.15   1,695  R$   17,592
0.20   1,167  R$   23,448
0.25     853  R$   22,904
0.30     598  R$   19,280
0.35     439  R$   16,856
0.40     331  R$   14,840
0.45     248  R$   11,536
0.50     194  R$    9,088
```

Desenhados a cada centésimo em vez de a cada vigésimo, os mesmos números formam um morro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 580 360\" role=\"img\" data-fig=\"l11-value-curve\" aria-label=\"Valor líquido nos meses de teste contra o corte, de 0,05 a 0,5. A curva começa bem abaixo de zero, sobe íngreme até um topo largo e plano entre cerca de 0,17 e 0,27, e desce devagar até cerca de R$ 9.000 em 0,5. Uma linha tracejada marca o corte de equilíbrio, 0,278, logo à direita do topo.\"><path d=\"M92.0 300.0 L550.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M142.9 300.0 L142.9 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"142.9\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,1</text><path d=\"M244.7 300.0 L244.7 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"244.7\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M346.4 300.0 L346.4 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"346.4\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,3</text><path d=\"M448.2 300.0 L448.2 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"448.2\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M550.0 300.0 L550.0 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,5</text><text x=\"321.0\" y=\"331.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">corte: mandar crédito acima desta chance</text><path d=\"M92.0 24.0 L92.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M88.0 300.0 L92.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 80.000</text><path d=\"M92.0 249.8 L550.0 249.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 249.8 L92.0 249.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"249.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 60.000</text><path d=\"M92.0 199.6 L550.0 199.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 199.6 L92.0 199.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"199.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 40.000</text><path d=\"M92.0 149.5 L550.0 149.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 149.5 L92.0 149.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"149.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 20.000</text><path d=\"M92.0 99.3 L550.0 99.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 99.3 L92.0 99.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"99.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M92.0 49.1 L550.0 49.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 49.1 L92.0 49.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"49.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 20.000</text><text x=\"92.0\" y=\"10.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">valor líquido, seis meses</text><path d=\"M92.0 99.3 L550.0 99.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M92.0 291.3 L97.1 247.7 L102.2 213.9 L107.3 182.4 L112.4 162.7 L117.4 146.2 L122.5 134.1 L127.6 122.5 L132.7 113.0 L137.8 101.7 L142.9 94.6 L148.0 88.7 L153.1 83.8 L158.2 77.9 L163.2 72.5 L168.3 66.7 L173.4 62.9 L178.5 59.7 L183.6 57.0 L188.7 57.5 L193.8 55.1 L198.9 52.2 L204.0 50.5 L209.0 49.7 L214.1 46.9 L219.2 45.5 L224.3 45.1 L229.4 44.0 L234.5 41.4 L239.6 39.4 L244.7 40.4 L249.8 41.8 L254.8 41.4 L259.9 41.7 L265.0 41.2 L270.1 40.8 L275.2 39.5 L280.3 38.6 L285.4 40.0 L290.5 40.7 L295.6 41.8 L300.6 42.1 L305.7 42.8 L310.8 44.0 L315.9 44.5 L321.0 45.6 L326.1 46.0 L331.2 47.7 L336.3 47.9 L341.4 49.0 L346.4 50.9 L351.5 52.5 L356.6 52.4 L361.7 53.0 L366.8 53.0 L371.9 54.6 L377.0 54.1 L382.1 54.9 L387.2 55.1 L392.2 56.5 L397.3 57.0 L402.4 57.1 L407.5 57.3 L412.6 58.4 L417.7 59.1 L422.8 59.1 L427.9 59.7 L433.0 59.5 L438.0 59.2 L443.1 60.6 L448.2 62.0 L453.3 62.6 L458.4 63.8 L463.5 64.1 L468.6 65.1 L473.7 65.1 L478.8 65.6 L483.8 65.7 L488.9 66.9 L494.0 69.1 L499.1 70.3 L504.2 70.8 L509.3 71.9 L514.4 72.1 L519.5 73.3 L524.6 73.3 L529.6 74.1 L534.7 74.9 L539.8 75.9 L544.9 76.9 L550.0 76.5\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M323.8 300.0 L323.8 26.5\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"323.8\" y=\"18.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">equilíbrio 0,278</text><circle cx=\"550.0\" cy=\"76.5\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"542.0\" y=\"64.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o padrão, 0,5</text></svg>", "caption": "Um topo plano, uma descida suave à direita e um penhasco à esquerda: um corte baixo demais custa muito mais que um alto demais.", "same": ["R$ 0"]}
```

Três coisas nele importam mais do que onde fica o topo.

**O topo é plano.** Todo corte entre cerca de 0,17 e 0,27 faz entre R$ 21.400 e R$ 23.900. Uma
diferença de alguns centésimos no corte vale algumas centenas de reais, e o bootstrap da aula 2 não
separaria a maioria delas. Discutir 0,20 contra 0,23 é discutir dentro do ruído.

**Os lados são íngremes, e não são iguais.** À direita, o modelo manda menos créditos e perde mais
gente que sai, então o dinheiro escorre devagar: 0,5 ainda faz R$ 9.088. À esquerda ele despenca. Em
0,1 os créditos alcançam tanta gente que fica que o programa mal se paga, e em 0,05 ele perde
R$ 76.520. **Um corte baixo demais sai muito mais caro que um alto demais**, porque quem fica supera
quem sai em quinze para um.

**0,5 nunca foi uma escolha.** É o que o `predict` usa quando ninguém diz outra coisa, e quer dizer
"mande crédito quando sair for mais provável que ficar". Nada nos custos da Feira em Casa diz isso.
Aqui ele deixa R$ 14.360 dos R$ 23.448 dos seis meses na mesa, e outro crédito ou outro preço
levaria o melhor corte para outro lugar de novo.

Então a pergunta desta aula não é "qual o melhor corte", que os meses de teste só respondem depois
do fato. É **de onde o corte deve vir antes de alguém saber**, e o candidato óbvio é a linha de
equilíbrio que a aula 2 tirou dos custos. Essa linha depende de uma suposição: que uma chance de
0,278 quer dizer o que diz. A próxima seção confere.
