---
title: Superada, ou sorte
version: 1
---

O modelo fez R$ 21.672 nos meses de teste e a regra perdeu R$ 576. Parece decisivo, e ainda é um
conjunto de teste só: 24.257 linhas que por acaso eram o segundo semestre de 2025. **Outros seis
meses, com outros assinantes, dariam outros números**, e a pergunta que importa é se a diferença
sobreviveria a isso.

O `statistics` respondia a esse tipo de pergunta com um intervalo, e a ferramenta que dispensa
fórmula é o **bootstrap**: sorteie um novo conjunto de teste do mesmo tamanho a partir do real, com
reposição, meça as duas políticas nele, e faça isso mil vezes. A dispersão das mil diferenças é o
quanto a diferença se mexe quando só a sorte muda.

Um detalhe separa um bootstrap correto de um tranquilizador. As linhas do `churn.csv` não são
independentes: o mesmo assinante aparece uma vez por mês, e as linhas dele sobem e descem juntas.
Então este programa reamostra **assinantes**, levando todas as linhas de cada um. Salve-o como
`beaten.py`; ele lê as notas que o `first_model.py` salvou:

```schooling-example
{
  "language": "python",
  "file": "beaten.py",
  "parts": [
    {
      "code": "# beaten.py\nimport numpy as np\nimport pandas as pd\n\nfrom feira import CREDIT, KEPT, SAVED, net_value\n\ntest = pd.read_csv(\"first_model_scores.csv\")",
      "note": "As notas salvas pelo `first_model.py`, para nada ser ajustado de novo."
    },
    {
      "code": "model = test[\"chance\"] >= CREDIT / (SAVED * KEPT)\nrule = (test[\"skips_90d\"] >= 3) & (test[\"complaints_90d\"] >= 1)\nprint(f\"model R$ {net_value(test['churned'], model):,.0f}, \"\n      f\"rule R$ {net_value(test['churned'], rule):,.0f}\")\n",
      "note": "As duas políticas em comparação, cada uma como uma coluna de sim ou não: a do modelo, na linha de equilíbrio, e a regra que o `rule.py` escolheu."
    },
    {
      "code": "rng = np.random.default_rng(0)\nrows = test.groupby(\"customer_id\").indices          # each subscriber's rows\npeople = list(rows)\ngaps = []",
      "note": "**Reamostre pessoas, não linhas.** `indices` liga cada assinante às posições das linhas dele. Um assinante aparece até seis vezes nos meses de teste, e essas linhas não são sorteios independentes; reamostrar linhas fingiria que são e estreitaria demais o intervalo."
    },
    {
      "code": "for _ in range(1000):\n    drawn = rng.choice(len(people), len(people))      # subscribers, with replacement\n    idx = np.concatenate([rows[people[i]] for i in drawn])\n    t = test.iloc[idx]\n    gaps.append(net_value(t[\"churned\"], model.iloc[idx]) - net_value(t[\"churned\"], rule.iloc[idx]))",
      "note": "Mil conjuntos de teste imaginários, cada um do tamanho do real, sorteados dele com reposição. Em cada um, as mesmas duas políticas são medidas e a diferença guardada."
    },
    {
      "code": "low, high = np.percentile(gaps, [2.5, 97.5])\nprint(f\"model minus rule, 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}\")\nprint(f\"resamples where the rule won: {np.mean(np.array(gaps) < 0):.1%}\")",
      "note": "Os 95% do meio dessas diferenças são o intervalo, e a parte abaixo de zero é quantas vezes a regra teria saído na frente."
    }
  ]
}
```

```
ana@lab:~/ml$ python beaten.py
model R$ 21,672, rule R$ -576
model minus rule, 95% of resamples between R$ 18,416 and R$ 25,944
resamples where the rule won: 0.0%
```

**Em mil reamostras, a regra nunca saiu na frente**, e os 95% do meio das diferenças vão de uns
R$ 18.400 a R$ 25.900. A diferença não é sorte. As reamostras caem assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l02-bootstrap\" aria-label=\"Um histograma de 1.000 diferenças bootstrap entre o modelo e a regra, todas positivas, centradas perto de R$ 22.212, com a linha do zero bem à esquerda de todas as barras.\"><path d=\"M60.0 30.0 L60.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 200.0 L60.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 165.3 L610.0 165.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 165.3 L60.0 165.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"165.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M60.0 130.6 L610.0 130.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 130.6 L60.0 130.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"130.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M60.0 95.9 L610.0 95.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 95.9 L60.0 95.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"95.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><path d=\"M60.0 61.2 L610.0 61.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 61.2 L60.0 61.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"61.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">reamostras</text><path d=\"M335.0 200.0 L335.0 197.2 L352.2 197.2 L352.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M352.2 200.0 L352.2 194.4 L369.4 194.4 L369.4 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M369.4 200.0 L369.4 176.4 L386.6 176.4 L386.6 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M386.6 200.0 L386.6 152.1 L403.8 152.1 L403.8 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M403.8 200.0 L403.8 107.7 L420.9 107.7 L420.9 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M420.9 200.0 L420.9 61.9 L438.1 61.9 L438.1 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M438.1 200.0 L438.1 52.2 L455.3 52.2 L455.3 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M455.3 200.0 L455.3 89.0 L472.5 89.0 L472.5 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M472.5 200.0 L472.5 123.0 L489.7 123.0 L489.7 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M489.7 200.0 L489.7 168.8 L506.9 168.8 L506.9 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M506.9 200.0 L506.9 187.5 L524.1 187.5 L524.1 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M524.1 200.0 L524.1 195.8 L541.2 195.8 L541.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M60.0 200.0 L610.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 200.0 L60.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M197.5 200.0 L197.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"197.5\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 8.000</text><path d=\"M335.0 200.0 L335.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"335.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 16.000</text><path d=\"M472.5 200.0 L472.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"472.5\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 24.000</text><path d=\"M610.0 200.0 L610.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"610.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 32.000</text><text x=\"335.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">modelo menos regra, em reais</text><path d=\"M60.0 200.0 L60.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"68.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem diferença</text></svg>", "caption": "Mil conjuntos de teste reamostrados. A diferença muda milhares de reais de um para outro, e nunca chega a zero. As barras da outra cor são os 5% fora do intervalo.", "same": ["R$ 0"]}
```

Ler isso do jeito certo importa. O intervalo **não** diz que o modelo vai fazer entre esses dois
valores no próximo semestre: o próximo semestre tem os seus assinantes e, como a aula 22 mostra, as
suas surpresas. Ele diz que, *em dados como estes*, a diferença entre as duas políticas é muito maior
que o ruído de medi-la. É tudo o que um conjunto de teste pode prometer, e basta para decidir.

## Quando a diferença é pequena

O caso a vigiar é o contrário: dois modelos a poucas centenas de reais um do outro, com um intervalo
que cruza o zero. Aí o relato honesto é que **o teste não consegue separá-los**, e a escolha entre
eles se faz por outra coisa: qual é mais simples, mais barato de rodar, mais fácil de explicar. As
aulas 8 e 9 encontram exatamente isso, quando um modelo ajustado supera um não ajustado por menos do
que a largura deste intervalo.
