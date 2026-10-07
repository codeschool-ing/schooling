---
title: Preencher com o centro, e o que isso faz com a dispersão
version: 1
---

**Preencher um vazio com a média ou a mediana mantém a média onde estava e encolhe todo o resto.**
Cada linha preenchida cai no mesmo valor, no meio, então a dispersão cai, as correlações
enfraquecem e qualquer contagem de extremos sai subestimada. Se isso importa depende do uso que a
coluna terá.

Os tempos de entrega de novo:

```python
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as the mean", own["minutes"].fillna(own["minutes"].mean()))
report("blanks as the median", own["minutes"].fillna(own["minutes"].median()))
```

```
ana@lab:~/clean$ python fill_centre.py
recorded only          mean  59.4  sd 21.1  late 10.5%
blanks as the mean     mean  59.4  sd 20.8  late 10.2%
blanks as the median   mean  59.3  sd 20.8  late 10.2%
```

Preenchida com a média, a média não se mexe — nem poderia, já que todo valor novo é igual a ela. O
desvio padrão cai de 21,1 para 20,8. E a fração de atrasos cai de 10,5% para 10,2%, porque 456
entregas de duas horas ou mais foram levadas para 59 minutos. **Para vazios MNAR, o centro é o
palpite errado numa direção conhecida**: a aula 3 estabeleceu que todo valor que falta é de pelo
menos 120.

## Medido contra a verdade

Os anos de nascimento são um teste mais justo, porque nada na aula 3 sugeriu que os vazios escondam
clientes mais velhos ou mais novos. O arquivo de verdade do laboratório tem todo ano real, então
cada preenchimento pode receber uma nota:

```schooling-example
{
  "language": "python",
  "file": "birth_impute.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom customers import customers\n\n"
    },
    {
      "code": "truth = pd.read_csv(\"~/clean-data/truth/people.csv\", dtype={\"birth_year\": \"Int64\"})\nboth = customers.merge(truth[[\"customer_id\", \"birth_year\"]], on=\"customer_id\",\n                       suffixes=(\"\", \"_true\"))\n",
      "note": "**O arquivo de verdade do laboratório**, ligado pelo id do cliente. Nenhum dado real tem esta coluna; é ela que permite dar nota a cada preenchimento."
    },
    {
      "code": "blank = both[\"birth_year\"].isna()\nfills = {\n    \"true values\": both[\"birth_year_true\"],\n",
      "note": "Os valores verdadeiros, como régua."
    },
    {
      "code": "    \"overall median\": both[\"birth_year\"].fillna(both[\"birth_year\"].median()),\n",
      "note": "**A mediana geral** para todo vazio."
    },
    {
      "code": "    \"median by channel\": both[\"birth_year\"].fillna(\n        both.groupby(\"signup_channel\")[\"birth_year\"].transform(\"median\")),\n",
      "note": "A mediana do próprio canal de cadastro do cliente, a imputação mais simples a partir de linhas parecidas."
    },
    {
      "code": "    \"random draw\": both[\"birth_year\"].fillna(pd.Series(\n        both[\"birth_year\"].dropna().sample(blank.sum(), replace=True, random_state=1).values,\n        index=both.index[blank])),\n}\n",
      "note": "**Um sorteio** entre os anos registrados, com semente fixa para a execução se repetir."
    },
    {
      "code": "for label, filled in fills.items():\n    error = (filled[blank] - both.loc[blank, \"birth_year_true\"]).abs().mean()\n    print(f\"{label:18} mean {filled.mean():6.1f}  sd {filled.std():4.1f}  \"\n          f\"error on the filled rows {error:4.1f}\")\n",
      "note": "Para cada preenchimento, a média e a dispersão da coluna inteira, e o erro médio nas linhas preenchidas."
    }
  ]
}
```

```
ana@lab:~/clean$ python birth_impute.py
true values        mean 1979.7  sd 16.2  error on the filled rows  0.0
overall median     mean 1979.8  sd 13.3  error on the filled rows 14.1
median by channel  mean 1979.9  sd 13.3  error on the filled rows 14.1
random draw        mean 1979.7  sd 16.3  error on the filled rows 18.9
```

Leia as colunas separadamente, porque respondem a perguntas diferentes:

- **a média** sobrevive a todo preenchimento: 1979,7 contra 1979,8, 1979,9 e 1979,7;
- **a dispersão** encolhe com a mediana, de 16,2 para 13,3 anos, e sobrevive ao sorteio;
- **o erro por linha** é de 14,1 anos com a mediana e de 18,9 com o sorteio.

Nenhum preenchimento acerta um ano de nascimento individual; a mediana erra por catorze anos em
média. **Imputação serve a resumos, nunca à pessoa da linha.** A mediana serve a uma média e
prejudica uma dispersão; um sorteio entre os valores observados — chamado de hot deck — mantém a
dispersão e é pior para cada linha. Preencher por canal não mudou nada aqui, o que já é um achado: o
canal não carrega informação nenhuma sobre a idade neste dado, então não ajuda a prevê-la.
