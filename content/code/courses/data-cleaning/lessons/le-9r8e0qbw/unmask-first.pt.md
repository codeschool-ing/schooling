---
title: Desmascarar primeiro: toda ausência vira vazio
version: 1
---

**Toda estratégia desta aula trabalha sobre vazios, então o primeiro passo é fazer de toda
ausência um vazio e de todo vazio que não é ausência um valor.** A aula 3 achou os dois tipos: os
1900, que são faltantes vestidos de ano, e os descontos vazios do site, que são zeros vestidos de
vazio. Deixe qualquer um no lugar e toda escolha depois dele é feita sobre os números errados.

O SQL tem uma função para cada direção:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE birth_year = '1900') AS was_1900, count(*) FILTER (WHERE NULLIF(birth_year, '1900') IS NULL) AS now_blank FROM raw.customers"
 was_1900 | now_blank 
----------+-----------
      348 |       686
(1 row)
```

`NULLIF(birth_year, '1900')` devolve NULL quando o valor é `1900` e o próprio valor nos outros
casos. Os 348 marcadores se juntam aos 338 vazios de verdade, e a coluna agora tem 686 anos
faltantes — **a contagem honesta, o dobro do que o arquivo mostrava**. Nada se perdeu; algo parou de
fingir.

`COALESCE(discount, '0')` vai na outra direção. Ele devolve o primeiro argumento que não é NULL,
então um vazio vira `0`:

```
ana@lab:~/clean$ psql -c "SELECT channel, count(*) FILTER (WHERE discount IS NULL) AS blank, count(*) FILTER (WHERE COALESCE(discount, '0') = '0') AS no_coupon FROM raw.orders GROUP BY channel"
 channel | blank | no_coupon 
---------+-------+-----------
 site    | 13883 |     13883
 app     |     0 |     11233
(2 rows)
```

No site, os 13.883 vazios viram 13.883 pedidos sem cupom, o mesmo que os 11.233 zeros do aplicativo
dizem. Isso é seguro por um motivo só: a aula 2 estabeleceu que o vazio quer dizer zero. **`COALESCE`
com uma constante é uma afirmação sobre significado**, e escrito sem essa evidência é um palpite
fantasiado de correção.

No pandas, os dois movimentos ficam assim, no arquivo que toda seção seguinte desta aula importa:

```schooling-example
{
  "language": "python",
  "file": "customers.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "O arquivo de clientes como texto, e sem as linhas duplicadas exatas que a aula 2 achou: um cliente repetido contaria duas vezes em toda média."
    },
    {
      "code": "unusable = customers[\"birth_year\"].eq(\"1900\") | customers[\"birth_year\"].str.len().eq(2)\n",
      "note": "**As linhas cujo ano não se usa**: o marcador e os anos de dois dígitos."
    },
    {
      "code": "customers[\"birth_year\"] = pd.to_numeric(customers[\"birth_year\"].mask(unusable))\n",
      "note": "`mask` esvazia essas linhas e deixa o resto; só então a coluna vira número, para nenhum marcador virar o número 1900."
    }
  ]
}
```

Os anos de dois dígitos do aplicativo também ficam de lado aqui. Não são marcadores — `87` quase
certamente quis dizer 1987 — mas decidir isso é uma conversão com riscos próprios, e a aula 10 a faz
direito. Até lá, contam como desconhecidos e não como palpite.
