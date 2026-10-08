---
title: Em pandas
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "task.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\n",
      "note": "Tudo como texto, e **linhas repetidas exatas removidas**, comparando todas as colunas."
    },
    {
      "code": "orders = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "Só pedidos entregues."
    },
    {
      "code": "orders[\"total\"] = pd.to_numeric(orders[\"total\"]).clip(lower=0)\n",
      "note": "**Um total negativo vira zero.**"
    },
    {
      "code": "site = orders[\"channel\"] == \"site\"\nutc = pd.to_datetime(orders.loc[site, \"ordered_at\"], format=\"%Y-%m-%dT%H:%M:%SZ\", utc=True)\norders.loc[site, \"placed\"] = utc.dt.tz_convert(\"America/Sao_Paulo\").dt.tz_localize(None)\norders.loc[~site, \"placed\"] = pd.to_datetime(orders.loc[~site, \"ordered_at\"],\n                                              format=\"%Y-%m-%d %H:%M:%S\")\n",
      "note": "**Os dois relógios**: os horários UTC do site convertidos para São Paulo, os do aplicativo lidos como estão."
    },
    {
      "code": "december = pd.to_datetime(orders[\"placed\"]) >= \"2025-12-01\"\n\n",
      "note": "Dezembro, no horário local."
    },
    {
      "code": "result = orders.groupby(\"channel\").agg(orders=(\"total\", \"size\"), revenue=(\"total\", \"sum\"))\nresult[\"december\"] = orders[december].groupby(\"channel\")[\"total\"].sum()\nprint(result.round(2).to_string())\n",
      "note": "Pedidos e receita por canal, e a receita de dezembro ao lado."
    }
  ]
}
```

```
ana@lab:~/clean$ python task.py
         orders     revenue   december
channel                               
app       11851  1065555.60  132925.45
site      14659  1436387.75  281616.15
```

Os mesmos números, ao centavo. A estrutura é a que este curso usou do começo ao fim: ler tudo como
texto, decidir cada tipo de propósito, e só depois calcular.

O que o pandas traz e o SQL não traz é o espaço entre os passos. **Todo resultado intermediário é
uma tabela que você pode olhar**, imprimir, contar e desenhar, e é por isso que a exploração da
aula 15 e a comparação aproximada da aula 5 foram escritas nele. O que ele pede em troca é
disciplina com os padrões: o `read_csv` adivinha tipos a menos que se diga o contrário, o
`errors="coerce"` esconde o que perde, e o `groupby` descarta chaves vazias a menos que se passe
`dropna=False`. Cada um desses foi uma aula própria.

O dinheiro aqui é float, diferente do `numeric` do SQL. Para somas de alguns milhares de valores
isso arredonda para o mesmo centavo, como a saída mostra; a aula 7 converteu os valores das lojas
com `Decimal` justamente porque uma cadeia longa o bastante de contas em float acaba não
arredondando.
