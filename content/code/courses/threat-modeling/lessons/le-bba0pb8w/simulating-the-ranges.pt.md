---
title: Simulando as faixas
version: 1
---

Multiplicar duas faixas não dá uma faixa que alguém consiga usar, porque os extremos raramente
acontecem juntos. O que funciona é **simulação**: imaginar muitos anos, e em cada um sortear uma
frequência e um conjunto de perdas a partir das faixas, somar, e olhar como os anos ficam juntos.
Isso se chama simulação de **Monte Carlo**, e é como as análises FAIR são calculadas na prática.

O `fair.py` faz isso para os nove riscos da aula 9, em umas cinquenta linhas e com a biblioteca
padrão:

```schooling-example
{"language": "python", "file": "fair.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Simulate ten thousand years of the risks in risks.csv, from their 90% ranges.\"\"\"\nimport csv\nimport math\nimport random\n\nYEARS = 10_000\nrng = random.Random(2026)   # a fixed seed: the same years on every run\n\n", "note": "Dez mil anos simulados, e um gerador aleatório com semente fixa: uma simulação que dá números diferentes a cada execução não pode ser citada numa aula, nem num relatório."}, {"code": "def lognormal(low, high):\n    \"\"\"A lognormal whose 5th and 95th percentiles are low and high.\"\"\"\n    mu = (math.log(low) + math.log(high)) / 2\n    sigma = (math.log(high) - math.log(low)) / (2 * 1.645)\n    return rng.lognormvariate(mu, sigma)\n\n", "note": "Uma faixa de 90% vira uma distribuição lognormal: 1,645 desvio-padrão de cada lado do meio cobrem 90%, medidos no logaritmo do valor."}, {"code": "def events(rate):\n    \"\"\"How many events happen in one year, at an average of rate per year.\"\"\"\n    n, p, limit = 0, rng.random(), math.exp(-rate)\n    while p > limit:\n        n, p = n + 1, p * rng.random()\n    return n\n", "note": "Quantos eventos acontecem num ano a uma dada taxa média: uma contagem de Poisson, sorteada multiplicando números aleatórios até ficarem abaixo de e elevado a menos a taxa."}, {"code": "\nrisks = list(csv.DictReader(open(\"risks.csv\")))\nyears = []\nfor _ in range(YEARS):\n    year = {}\n    for r in risks:\n        n = events(lognormal(float(r[\"per_year_low\"]), float(r[\"per_year_high\"])))\n        year[r[\"id\"]] = sum(lognormal(float(r[\"loss_low\"]), float(r[\"loss_high\"])) for _ in range(n))\n    years.append(year)", "note": "A cada ano, para cada risco: sortear uma taxa da faixa de frequência, sortear quantos eventos acontecem nessa taxa, e sortear uma perda para cada evento da faixa de perda."}, {"code": "\n\ndef percentile(values, p):\n    return sorted(values)[int(p * len(values))]\n\n\nprint(f\"{'':4} {'mean R$':>10} {'any loss':>9} {'1 year in 10':>13} {'1 in 100':>11}\")\nfor r in risks:\n    v = [y[r[\"id\"]] for y in years]\n    print(f\"{r['id']:4} {sum(v) / YEARS:10,.0f} {sum(x > 0 for x in v) / YEARS:9.1%} \"\n          f\"{percentile(v, 0.9):13,.0f} {percentile(v, 0.99):11,.0f}\")\ntotal = [sum(y.values()) for y in years]\nprint(f\"{'all':4} {sum(total) / YEARS:10,.0f} {sum(x > 0 for x in total) / YEARS:9.1%} \"\n      f\"{percentile(total, 0.9):13,.0f} {percentile(total, 0.99):11,.0f}\")", "note": "Por risco e para todos juntos: a média, a parcela de anos com alguma perda, e a perda no pior ano em dez e em cem."}, {"code": "\nprint(\"\\nchance that one year's total loss is more than\")\nfor limit in (100_000, 250_000, 500_000, 1_000_000):\n    print(f\"  R$ {limit:>9,}  {sum(x > limit for x in total) / YEARS:6.1%}\")", "note": "Quatro pontos da curva de excedência de perdas: a chance de o total de um ano ser maior que cada valor."}]}
```

Dez mil anos simulados, com semente fixa para que toda execução dê os mesmos anos:

```
(.venv) ana@vm:~/tm/portal-model$ python3 fair.py
        mean R$  any loss  1 year in 10    1 in 100
T01      10,969     40.4%        34,314      98,263
T02      11,375     97.4%        23,292      43,928
T03     119,050     25.1%       403,311   1,548,742
T07      31,347     22.6%       107,558     413,584
T08       6,623     77.9%        16,893      38,557
T10       4,959     61.7%        13,652      30,517
T11       3,419     77.9%         8,634      18,542
T13      33,871      7.1%             0     790,053
T14      19,765      9.9%             0     411,848
all     241,376    100.0%       645,467   1,899,724
```

### Lendo a tabela

**A média é maior que o produto da aula 9, em todos os riscos.** O melhor palpite da T03 dava R$
75.000 por ano; a simulação dá R$ 119.050. Nada está errado. As faixas são assimétricas, com caudas
longas para a direita: o pior caso da T03 é um milhão de reais, o melhor é sessenta mil, e o melhor
palpite de um quarto de milhão fica mais perto de baixo. Uma média sobre a faixa inteira inclui a
cauda, e a cauda é cara. **O total vai de R$ 139.400 para R$ 241.376**, e a diferença é a incerteza
que os melhores palpites escondiam.

**"Any loss" é a chance de pelo menos um evento num ano.** A T02 acontece em 97,4% dos anos; a T13
em 7,1%. É a última seção da aula 9, agora para todos os riscos.

**"1 year in 10" é a perda que um ano ruim alcança**: em 10% dos anos, a T03 custa R$ 403.311 ou
mais. Para a T13 e a T14 essa coluna é zero, porque elas acontecem em menos de um ano a cada dez; o
ano ruim delas está na última coluna, R$ 790.053 e R$ 411.848 um ano em cem. A coluna que a média
escondia é a que esta tabela acrescenta.

**A última linha são os nove juntos**, e é a que interessa ao daniel: num ano em cada dez, a Vereda
perde R$ 645.467 ou mais com esses nove riscos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-years\" aria-label=\"Os 10.000 anos simulados do fair.py, pela perda total em passos de R$ 100.000. A maioria dos anos perde menos de R$ 300.000, e as barras caem para a direita com uma cauda longa. A média é R$ 241.376; um ano em dez perde R$ 645.467 ou mais.\"><rect x=\"60.0\" y=\"30.0\" width=\"36.0\" height=\"180.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"100.0\" y=\"163.5\" width=\"36.0\" height=\"46.5\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"181.9\" width=\"36.0\" height=\"28.1\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"180.0\" y=\"190.9\" width=\"36.0\" height=\"19.1\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"220.0\" y=\"195.6\" width=\"36.0\" height=\"14.4\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"260.0\" y=\"199.9\" width=\"36.0\" height=\"10.1\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"300.0\" y=\"202.4\" width=\"36.0\" height=\"7.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"340.0\" y=\"204.9\" width=\"36.0\" height=\"5.1\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"380.0\" y=\"205.5\" width=\"36.0\" height=\"4.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"420.0\" y=\"206.0\" width=\"36.0\" height=\"4.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"460.0\" y=\"207.4\" width=\"36.0\" height=\"2.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"207.2\" width=\"36.0\" height=\"2.8\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"540.0\" y=\"208.1\" width=\"36.0\" height=\"1.9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"580.0\" y=\"208.4\" width=\"36.0\" height=\"1.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"620.0\" y=\"209.0\" width=\"36.0\" height=\"1.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"660.0\" y=\"203.8\" width=\"36.0\" height=\"6.2\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M60.0 210.0 L700.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 mil</text><text x=\"260.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">500 mil</text><text x=\"460.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1000 mil</text><text x=\"678.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1,5 mi+</text><path d=\"M156.6 232.0 L156.6 244.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"156.6\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">média R$ 241.376</text><path d=\"M318.2 232.0 L318.2 244.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"322.2\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1 ano em 10: R$ 645.467</text><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cada barra conta os anos cujo total caiu naquele passo</text></svg>", "caption": "O ano médio não existe: a maioria dos anos custa menos que a média, e alguns custam várias vezes mais."}
```

### O que a simulação supõe

Três coisas, e vale conhecer cada uma porque cada uma pode estar errada:

- **Formas lognormais.** Cada faixa vira uma distribuição lognormal cujos percentis 5 e 95 são as
  pontas da faixa. Ela serve para quantidades que não podem ser negativas e têm cauda longa para a
  direita, o que descreve a maioria das perdas. É uma escolha de modelagem, não um fato.
- **Independência.** Os riscos são sorteados separadamente a cada ano. Na realidade alguns andam
  juntos: uma conta da equipe roubada por phishing (T03) e um PDF preparado (T14) chegam os dois pelo
  e-mail das clínicas, e um ano ruim para um é mais provavelmente um ano ruim para o outro. Ignorar
  isso deixa a cauda do total mais fina do que deveria.
- **As faixas estão certas.** A simulação é exatamente tão boa quanto os intervalos de 90% de que ela
  parte. Ela não cria conhecimento; mostra o que as estimativas implicam quando tomadas juntas.
