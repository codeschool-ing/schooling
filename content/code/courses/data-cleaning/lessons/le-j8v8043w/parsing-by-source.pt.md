---
title: Ler por origem, com o formato por escrito
version: 1
---

**A correção para datas ambíguas é ler cada origem com o seu próprio formato, dito explicitamente.**
Não `dayfirst=True` para a coluna inteira nem o palpite do leitor, mas uma tabela de que sistema
escreve que convenção, aplicada linha a linha:

```schooling-example
{
  "language": "python",
  "file": "dates.py",
  "parts": [
    {
      "code": "import pandas as pd\n\ncustomers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "FORMATS = {\"site\": \"%Y-%m-%d\", \"app\": \"%m/%d/%Y\", \"store\": \"%d/%m/%Y\"}\n\n\n",
      "note": "**A convenção de cada origem, por escrito**, provada na seção anterior contando testemunhas."
    },
    {
      "code": "def parse(row):\n    text = row[\"signed_up\"]\n"
    },
    {
      "code": "    if row[\"signup_channel\"] in FORMATS:\n        return pd.to_datetime(text, format=FORMATS[row[\"signup_channel\"]], errors=\"coerce\")\n",
      "note": "Uma origem conhecida é lida com o seu próprio formato."
    },
    {
      "code": "    # the 2023 migration copied all three systems' records\n",
      "note": "A migração misturou as três convenções, então cada valor dela se decide sozinho."
    },
    {
      "code": "    if \"-\" in text:\n        return pd.to_datetime(text, format=\"%Y-%m-%d\")\n",
      "note": "Um hífen quer dizer ISO, que tem uma leitura só."
    },
    {
      "code": "    first, second = int(text[:2]), int(text[3:5])\n    if first > 12:\n        return pd.to_datetime(text, format=\"%d/%m/%Y\")\n    if second > 12:\n        return pd.to_datetime(text, format=\"%m/%d/%Y\")\n",
      "note": "Um número acima de 12 é uma testemunha: em primeiro lugar é um dia; em segundo, o segundo número é o dia."
    },
    {
      "code": "    return pd.NaT  # both readings are dates: nothing in the value decides\n\n\n",
      "note": "**Quando os dois números são 12 ou menos, nada decide**, e o valor fica vazio em vez de chutado."
    },
    {
      "code": "customers[\"signed\"] = customers.apply(parse, axis=1)\n",
      "note": "Uma data lida por cliente."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from dates import customers as c; print(c['signed'].isna().sum()); print(c.groupby('signup_channel')['signed'].agg(['min', 'max', 'count']))"
10
                      min        max  count
signup_channel                             
app            2023-03-01 2025-12-10    723
import-2023    2023-02-10 2023-09-26     35
site           2023-01-19 2025-12-10   1003
store          2023-02-20 2025-12-10    605
```

Dez valores ficam como `NaT`, a data faltante do pandas, e o mínimo e o máximo de cada origem são
plausíveis: nada antes de 2023, quando começam os registros da Quitanda Verde, e nada depois de 10 de
dezembro, quando o arquivo de clientes foi exportado. **O mínimo e o máximo depois da leitura são a
checagem mais barata que existe**: um formato errado produz datas no futuro, ou um amontoado em
janeiro vindo de um texto com dia primeiro lido como mês primeiro.

Os dez são o resíduo honesto da migração:

```
ana@lab:~/clean$ python -c "from dates import customers as c; m = c[c['signed'].isna()]; print(m[['customer_id', 'signed_up', 'signup_channel']].head(4).to_string(index=False))"
customer_id  signed_up signup_channel
     C00012 03/06/2023    import-2023
     C00013 03/07/2023    import-2023
     C00054 01/06/2023    import-2023
     C00074 06/07/2023    import-2023
```

`03/06/2023` é 3 de junho ou 6 de março, e as duas são datas que a migração poderia ter. **Nada no
valor decide, então o leitor também não decide.** O código diz isso num comentário, e a contagem diz
quantos: dez de 2.376, deixados vazios em vez de chutados. Alguém que saiba de onde veio cada
registro migrado consegue preenchê-los; ninguém deveria tirar cara ou coroa para eles.

## O mesmo em SQL

`to_date` recebe o formato como segundo argumento, e um `CASE` o escolhe pela origem:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, min(d), max(d) FROM (SELECT signup_channel, CASE signup_channel WHEN 'site' THEN to_date(signed_up, 'YYYY-MM-DD') WHEN 'app' THEN to_date(signed_up, 'MM/DD/YYYY') WHEN 'store' THEN to_date(signed_up, 'DD/MM/YYYY') END AS d FROM raw.customers) t GROUP BY 1"
 signup_channel |    min     |    max     
----------------+------------+------------
 site           | 2023-01-19 | 2025-12-10
 app            | 2023-03-01 | 2025-12-10
 import-2023    |            | 
 store          | 2023-02-20 | 2025-12-10
(4 rows)
```

As três origens comuns concordam exatamente com o pandas. A migração sai vazia porque o `CASE` não
lhe dá formato, o que é o padrão certo: uma origem com convenções misturadas não recebe formato até
alguém escrever a regra para ela. **Nunca defina um estilo de data global e o deixe ler tudo**; o
banco que a aula 1 criou está em `DMY`, e um `::date` teria lido toda data do aplicativo com o dia
primeiro sem dizer uma palavra.