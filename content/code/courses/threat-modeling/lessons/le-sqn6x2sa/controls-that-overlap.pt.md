---
title: Controles que se sobrepõem
version: 1
---

A ordenação julgou cada controle **sozinho**, como se fosse o único comprado. Isso serve para
compará-los, e está errado para somá-los. **Três controles cortam a T03**, e não podem cada um levar
crédito pelos mesmos reais.

O C1 remove 80% da frequência da T03. O C2, o console na rede da clínica, remove 50% do que sobrou. O
C11, recepcionistas sem anotações clínicas, remove 30% do que sobrou depois disso. Aplicado em ordem,
cada um trabalha sobre um risco menor que o anterior:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-overlap\" aria-label=\"A perda esperada da T03 conforme controles são acrescentados um depois do outro. Sem nenhum: 75.000 reais por ano. Depois do C1, o segundo fator, que remove 80%: 15.000. Depois do C2, o console na rede da clínica, que remove metade do que sobrou: 7.500. Depois do C11, recepcionistas sem anotações, que remove 30% do que sobrou: 5.250. Sozinho, o C11 dizia economizar 22.500; acrescentado por último, economiza 2.250, menos que o custo de 3.500.\"><rect x=\"40.0\" y=\"30.0\" width=\"110.0\" height=\"180.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 75.000</text><text x=\"95.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nenhum controle</text><rect x=\"210.0\" y=\"30.0\" width=\"110.0\" height=\"144.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"210.0\" y=\"174.0\" width=\"110.0\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 15.000</text><text x=\"265.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C1, segundo fator</text><rect x=\"380.0\" y=\"174.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"380.0\" y=\"192.0\" width=\"110.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 7.500</text><text x=\"435.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C2, rede da clínica</text><rect x=\"550.0\" y=\"192.0\" width=\"110.0\" height=\"5.4\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"550.0\" y=\"197.4\" width=\"110.0\" height=\"12.6\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"187.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">R$ 5.250</text><text x=\"605.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">+ C11, papéis</text><path d=\"M30.0 210.0 L700.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"605.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C11 sozinho: R$ 22.500</text><text x=\"605.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">C11 por último: R$ 2.250</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">perda esperada da T03 por ano, com controles acrescentados em ordem</text></svg>", "caption": "Um controle vale o que ele remove do que sobrou. Julgado sozinho, o C11 valia dez vezes mais do que vale depois do C1 e do C2."}
```

O `prioritise.py` com uma lista de controles escreve o `risks.csv` como ele ficaria com esses
controles no lugar. Escrever numa pasta de rascunho, `after/`, e rodar lá o `risk.py` da aula 9
mostra a T03 depois do C1 e do C2:

```
(.venv) ana@vm:~/tm/portal-model$ mkdir after
(.venv) ana@vm:~/tm/portal-model$ python3 prioritise.py C1 C2 > after/risks.csv
(.venv) ana@vm:~/tm/portal-model$ cd after && python3 ../risk.py | grep T03
T03      0.03       250,000        7,500  10.4%
```

**Sobram R$ 7.500 por ano.** O C11 removeria 30% disso, R$ 2.250, e custa R$ 3.500. Julgado sozinho,
o C11 parecia R$ 22.500 de valor por R$ 3.500, uma razão de 6,4. Acrescentado depois dos dois
controles mais fortes, a razão dele fica em uns 0,6, e com estes números ele não vale a compra para a
T03.

### A regra

**Um controle vale o que ele remove do que sobra depois dos controles já escolhidos.** Então a ordem
da escolha importa, e o jeito honesto de montar um plano é guloso: pegar a melhor razão, recalcular o
valor de cada outro controle contra o que sobra, pegar de novo. Para uma lista de onze, isso se faz à
mão com o `prioritise.py` e o `risk.py`, como acima; para uma lista de cem, é um programa pequeno.

A ordenação independente continua útil, para uma coisa: **ela diz quais controles considerar
primeiro.** O que está errado é o total dos valores independentes, e um plano que os soma promete
mais do que entrega.
