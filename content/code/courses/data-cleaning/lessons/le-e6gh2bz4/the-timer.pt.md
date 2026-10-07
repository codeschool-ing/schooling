---
title: O cronômetro que para em duas horas
version: 1
---

**456 entregas da frota própria não têm tempo, e nada nas suas linhas explica isso.** Esta seção as
segue como uma analista seguiria, só com os arquivos, e depois — porque isto é um laboratório —
confere a conclusão contra a resposta.

## O que os tempos registrados dizem

```schooling-example
{
  "language": "python",
  "file": "own_fleet.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "own = orders[(orders[\"courier\"] == \"propria\") & (orders[\"status\"] != \"cancelled\")].copy()\n",
      "note": "Os entregadores da própria empresa, sem os pedidos cancelados: ali nada foi entregue, então nada deveria ter sido cronometrado."
    },
    {
      "code": "own[\"missing\"] = own[\"delivery_minutes\"].isna()\nown[\"minutes\"] = pd.to_numeric(own[\"delivery_minutes\"])\n",
      "note": "Uma marca para o vazio e o tempo como número. `to_numeric` deixa um vazio como `NaN`, que o `describe()` pula."
    },
    {
      "code": "print(f\"own-fleet deliveries: {len(own)}, without a time: {own['missing'].sum()}\")\nprint(own[\"minutes\"].describe().round(1).to_string())\n",
      "note": "Quantos, quantos sem tempo, e o resumo dos tempos que existem."
    }
  ]
}
```

```
ana@lab:~/clean$ python own_fleet.py
own-fleet deliveries: 15314, without a time: 456
count    14858.0
mean        59.4
std         21.1
min         12.0
25%         44.0
50%         56.0
75%         72.0
max        119.0
```

O meio desta distribuição é comum: metade das entregas leva menos de 56 minutos, três quartos menos
de 72. A ponta não é. **A entrega mais longa registrada tem 119 minutos, em 14.858 entregas**, e a
coluna de tempos tem uma cauda à direita — a aula 2 mostrou a mesma forma nos totais dos pedidos —
que deveria ir afinando aos poucos, não parar um minuto antes de um número redondo. Contando as
entregas perto do topo:

```
ana@lab:~/clean$ psql -c "SELECT delivery_minutes::int / 10 * 10 AS from_minute, count(*) FROM raw.orders WHERE courier = 'propria' AND delivery_minutes IS NOT NULL GROUP BY 1 ORDER BY 1 DESC LIMIT 4"
 from_minute | count 
-------------+-------
         110 |   309
         100 |   471
          90 |   784
          80 |  1092
(4 rows)
```

309 entregas entre 110 e 119 minutos, e depois nada a partir de 120. Uma cauda que ainda tem
trezentas entregas de espessura uma faixa antes de acabar foi cortada, não afinou.

## Com o que os vazios se alinham

Separando os vazios pela hora do dia, com os pedidos do aplicativo porque os horários deles são
locais (os do site estão em UTC, e a aula 7 os converte):

```schooling-example
{
  "language": "python",
  "file": "by_hour.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "app = orders[(orders[\"channel\"] == \"app\") & (orders[\"courier\"] == \"propria\")\n             & (orders[\"status\"] != \"cancelled\")].copy()\n",
      "note": "Só as entregas da frota própria feitas pelo aplicativo: o aplicativo escreve hora local, então a hora sai direto do texto."
    },
    {
      "code": "app[\"hour\"] = app[\"ordered_at\"].str[11:13]\napp[\"evening\"] = app[\"hour\"].isin([\"18\", \"19\", \"20\"])\n",
      "note": "Os caracteres 11 e 12 de `2025-01-01 07:00:30` são a hora. Das seis às nove da noite é o pico."
    },
    {
      "code": "rate = app.groupby(\"evening\")[\"delivery_minutes\"].apply(lambda m: m.isna().mean() * 100)\n",
      "note": "A fração sem tempo em cada um dos dois grupos."
    },
    {
      "code": "rate.index = [\"other hours\", \"18:00 to 20:59\"]\nprint(\"% without a time\")\nprint(rate.round(1).to_string())\n",
      "note": "Rótulos que um leitor entende, e o resultado."
    }
  ]
}
```

```
ana@lab:~/clean$ python by_hour.py
% without a time
other hours       1.5
18:00 to 20:59    6.0
```

Quatro vezes a taxa à noite. **Lido sozinho, isso parece MAR**: os vazios dependem da hora, a hora
está no arquivo, então preencha os vazios da noite com outras entregas da noite e o problema está
resolvido. E essa seria a conclusão errada. Entregas à noite são mais lentas — o trânsito é pior —
então mais delas cruzam a linha, qualquer que seja, que esvazia o campo. A hora não causa o vazio;
ela prevê o valor que causa.

**As duas leituras não se distinguem de dentro do dado.** Um vazio que depende da hora e um vazio que
depende de uma entrega lenta que a hora torna mais provável produzem a mesma tabela. A pista que as
separa é o teto: um máximo de 119 e uma cauda cortada reta. Ana leva isso ao time de operações, que
conhece o aplicativo dos entregadores: **o cronômetro para em duas horas e não salva nada**, de
propósito, para que um entregador que esquece de fechar uma entrega não registre uma de nove horas.

Isso é MNAR na forma mais pura: todo valor de 120 ou mais falta, e só esses.

## Conferindo contra a resposta

Nenhum dado real vem com os valores que perdeu. Este laboratório vem, porque o gerador escreveu todo
tempo real de entrega em `truth/` antes de esvaziar o campo. Lê-lo é o que você nunca consegue fazer
no trabalho, e mostra o que os vazios escondiam:

```python
import pandas as pd

truth = pd.read_csv("/var/lib/clean-data/truth/orders.csv")
real = truth.loc[truth["what"] == "minutes", "value"]
unseen = real[real >= 120]
print(f"deliveries the timer never recorded: {len(unseen)}")
print(f"their real times: {unseen.min()} to {unseen.max()} minutes")
print(f"mean of the recorded times: {real[real < 120].mean():.1f}")
print(f"mean of all the real times: {real.mean():.1f}")
seen = real[real < 120]
print(f"late (90 minutes or more), as recorded: {(seen >= 90).mean() * 100:.1f}%")
print(f"late (90 minutes or more), really:      {(real >= 90).mean() * 100:.1f}%")
```

```
ana@lab:~/clean$ python truth_minutes.py
deliveries the timer never recorded: 456
their real times: 120 to 223 minutes
mean of the recorded times: 59.4
mean of all the real times: 61.9
late (90 minutes or more), as recorded: 10.5%
late (90 minutes or more), really:      13.2%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l03-ceiling\" aria-label=\"Um histograma dos tempos reais de 15314 entregas da frota própria, em faixas de dez minutos de 0 a 230, como o gerador do laboratório os conhece. Toda barra abaixo de 120 minutos foi registrada. As 456 entregas de 120 minutos ou mais, uma cauda fina até 223, nunca foram registradas, porque o cronômetro para em duas horas.\"><path d=\"M70.0 50.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 250.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 187.6 L690.0 187.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 187.6 L70.0 187.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"187.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1000</text><path d=\"M70.0 125.2 L690.0 125.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 125.2 L70.0 125.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"125.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2000</text><path d=\"M70.0 62.8 L690.0 62.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 62.8 L70.0 62.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"62.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3000</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">entregas</text><path d=\"M70.0 250.0 L690.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L70.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M150.9 250.0 L150.9 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.9\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M231.7 250.0 L231.7 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"231.7\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M312.6 250.0 L312.6 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"312.6\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M393.5 250.0 L393.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"393.5\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><path d=\"M474.3 250.0 L474.3 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"474.3\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><path d=\"M555.2 250.0 L555.2 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"555.2\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">180</text><path d=\"M636.1 250.0 L636.1 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.1\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">210</text><text x=\"380.0\" y=\"281.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tempo real de entrega, minutos</text><rect x=\"97.0\" y=\"247.4\" width=\"27.0\" height=\"2.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"123.9\" y=\"207.9\" width=\"27.0\" height=\"42.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"150.9\" y=\"131.4\" width=\"27.0\" height=\"118.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"177.8\" y=\"71.4\" width=\"27.0\" height=\"178.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"204.8\" y=\"80.0\" width=\"27.0\" height=\"170.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"231.7\" y=\"102.7\" width=\"27.0\" height=\"147.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"258.7\" y=\"147.5\" width=\"27.0\" height=\"102.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"285.7\" y=\"181.8\" width=\"27.0\" height=\"68.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"312.6\" y=\"201.1\" width=\"27.0\" height=\"48.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"339.6\" y=\"220.7\" width=\"27.0\" height=\"29.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"366.5\" y=\"230.7\" width=\"27.0\" height=\"19.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.5\" y=\"240.0\" width=\"27.0\" height=\"10.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"420.4\" y=\"243.3\" width=\"27.0\" height=\"6.7\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"447.4\" y=\"245.3\" width=\"27.0\" height=\"4.7\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"474.3\" y=\"247.8\" width=\"27.0\" height=\"2.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"501.3\" y=\"248.1\" width=\"27.0\" height=\"1.9\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"528.3\" y=\"248.7\" width=\"27.0\" height=\"1.3\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"555.2\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"582.2\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"609.1\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"636.1\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"663.0\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M393.5 250.0 L393.5 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"393.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o cronômetro para</text><text x=\"541.7\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">456 nunca registradas</text></svg>", "caption": "Desenhado a partir do arquivo de verdade do laboratório, que nenhum dado real tem. No arquivo de pedidos, tudo à direita da linha é simplesmente um vazio."}
```

A média muda só de 59,4 para 61,9 minutos, porque 456 entregas são 3% do total. **A fração de
entregas atrasadas muda de 10,5% para 13,2%**: um quarto a mais de atrasos do que os tempos
registrados mostram, e um relatório de atrasos é exatamente o relatório que alguém lê para decidir se
a frota precisa de mais entregadores. Uma analista que preenchesse os vazios com a média, ou os
descartasse, teria informado uma frota mais rápida do que ela é, com cara séria e uma consulta
correta.
