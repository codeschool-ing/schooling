---
title: Onde o modelo errou
version: 1
---

Um modelo pessimista demais no geral ainda pode errar em direções diferentes para pessoas diferentes, e
o número geral esconde isso. A pergunta é a que a aula 20 fez sobre idade, feita agora para todo grupo:
para cada valor de uma coluna, o que o modelo disse e o que aconteceu? A razão entre os dois é o número
útil. Abaixo de 1, saiu menos gente do que o modelo disse; acima de 1, saiu mais. Salve isto como
`where.py`:

```python
# where.py
import pandas as pd

from feira import load_churn

scores = pd.concat(pd.read_csv(f"scores/2026-0{m}.csv", parse_dates=["snapshot"]) for m in [1, 2, 3])
labels = pd.read_csv("data/churn_2026_labels.csv", parse_dates=["snapshot"])
rows = scores.merge(labels, on=["customer_id", "snapshot"]).merge(
    load_churn("data/churn_2026.csv"), on=["customer_id", "snapshot"])

for col in ["plan", "city"]:
    g = rows.groupby(col, observed=True)
    table = pd.DataFrame({"subscribers": g.size(), "chance": g["chance"].mean(),
                          "left": g["churned"].mean()})
    table["left / chance"] = table["left"] / table["chance"]
    print(table.round(3).sort_values("left / chance").to_string(), end="\n\n")
```

```
ana@lab:~/ml$ python where.py
             subscribers  chance   left  left / chance
plan                                                  
monthly              496   0.108  0.058          0.541
fortnightly         5714   0.053  0.041          0.776
weekly              6944   0.070  0.058          0.831

                subscribers  chance   left  left / chance
city                                                     
Rio de Janeiro         2497   0.089  0.056          0.631
Campinas               1890   0.056  0.039          0.694
São Paulo              5292   0.059  0.043          0.727
Belo Horizonte         1776   0.059  0.066          1.124
Curitiba               1699   0.057  0.064          1.124
```

A maioria dos grupos fica entre 0,6 e 0,8, o pessimismo geral da seção anterior espalhado de forma
bastante uniforme. Dois tipos de linha se destacam.

**O plano mensal, em 0,541.** O modelo deu a esses 496 assinantes uma chance média de 0,108, e 5,8%
saíram: o modelo disse quase o dobro do que aconteceu. É o artefato que a aula 19 achou, agora com preço.
Toda coluna de plano é zero para eles, então o modelo os lê como um plano para o qual não tem peso, e um
tempo de casa curto por cima faz deles os assinantes mais novos e voláteis de qualquer plano. **As
entradas avisaram sobre este no dia 1º de fevereiro**, quando o `inputs.py` mostrou um valor nunca visto
no treino.

**Curitiba e Belo Horizonte, em 1,124.** Toda outra cidade ficou bem abaixo da sua chance; estas duas
ficaram acima. Saiu mais gente delas do que o modelo disse, num trimestre em que o modelo estava
superestimando todo o resto. Isso não é ruído de um mês. A taxa mensal delas, posta contra as outras três
cidades ao longo de todo o histórico, fica assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 340\" role=\"img\" data-fig=\"l22-cities\" aria-label=\"Parte mensal dos assinantes que saíram, de julho de 2024 a março de 2026, em duas linhas: Curitiba e Belo Horizonte juntas, e as outras três cidades. Ao longo de 2025 as duas linhas se cruzam várias vezes entre cerca de 0,03 e 0,08, subindo juntas depois do aumento de preço de setembro. A partir de janeiro de 2026, à direita de uma linha tracejada onde terminam os dados do modelo, as duas cidades ficam acima das outras todo mês: 0,058 contra 0,045, 0,064 contra 0,041 e 0,073 contra 0,050.\"><path d=\"M70.0 280.0 L560.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 280.0 L70.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul 2024</text><path d=\"M217.0 280.0 L217.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"217.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan 2025</text><path d=\"M364.0 280.0 L364.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"364.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul 2025</text><path d=\"M511.0 280.0 L511.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"511.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan 2026</text><path d=\"M70.0 30.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 280.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,02</text><path d=\"M70.0 208.6 L560.0 208.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 208.6 L70.0 208.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"208.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,04</text><path d=\"M70.0 137.1 L560.0 137.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 137.1 L70.0 137.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"137.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,06</text><path d=\"M70.0 65.7 L560.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 65.7 L70.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,08</text><text x=\"70.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">parte que saiu no mês</text><path d=\"M70.0 46.6 L94.5 91.5 L119.0 136.1 L143.5 151.0 L168.0 166.0 L192.5 152.0 L217.0 152.7 L241.5 157.7 L266.0 159.4 L290.5 148.4 L315.0 154.4 L339.5 183.1 L364.0 172.2 L388.5 163.8 L413.0 105.7 L437.5 95.5 L462.0 95.7 L486.5 120.9 L511.0 190.8 L535.5 205.3 L560.0 173.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 114.9 L94.5 167.9 L119.0 188.1 L143.5 182.0 L168.0 127.7 L192.5 130.0 L217.0 125.9 L241.5 152.1 L266.0 182.5 L290.5 235.1 L315.0 150.6 L339.5 156.2 L364.0 208.3 L388.5 200.9 L413.0 69.5 L437.5 137.3 L462.0 135.8 L486.5 184.0 L511.0 143.9 L535.5 124.0 L560.0 90.5\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M498.8 280.0 L498.8 37.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"498.8\" y=\"29.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fim dos dados do modelo</text><text x=\"525.7\" y=\"80.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Curitiba + BH</text><text x=\"525.7\" y=\"223.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">as outras três</text></svg>", "caption": "Duas cidades se afastam das outras em janeiro, e nada do que o modelo lê se mexeu com elas.", "same": ["Curitiba + BH"]}
```

Ao longo de 2025 as duas linhas se revezam no topo. A partir de janeiro elas se separam, e ficam
separadas. Perguntada sobre isso, a equipe de retenção soube na hora: **um concorrente começou a entregar
em Curitiba e Belo Horizonte em janeiro**, com um preço de lançamento. Saiu no noticiário local. Não está
em nenhuma coluna do `churn.csv`.

E é por isso que o `inputs.py` não viu nada. A coluna de cidade ficou em 0,001: a mesma parte dos
assinantes morava em cada cidade, como sempre. **O que mudou foi o que morar lá queria dizer para alguém
ficar ou não.** As entradas eram as mesmas; a resposta às mesmas entradas era outra. Nenhuma conferência
das entradas consegue ver isso, porque não há nada nas entradas para ver. Só as respostas mostram, um mês
depois, e só se alguém dividir o erro por grupo.
