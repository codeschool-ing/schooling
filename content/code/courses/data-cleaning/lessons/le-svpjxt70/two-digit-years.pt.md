---
title: Anos escritos com dois dígitos
version: 1
---

O aplicativo gravou um ano de nascimento de dois dígitos para 105 clientes, já sem as linhas
repetidas. `87` não é um marcador como `1900`; alguém nascido em 1987 escreveu certo, num formato
que ninguém deveria ter permitido. A aula 4 deixou esses anos como desconhecidos e prometeu uma
conversão de verdade. **Um ano de dois dígitos precisa de um século, e escolher um é uma regra que
você escreve, não um fato que você lê.**

A regra aqui se apoia numa coisa que se sabe de todo cliente: são adultos comprando comida.
Ninguém neste arquivo nasceu em 2087, e ninguém nascido em 2087 está fazendo compras. Então um ano
de dois dígitos acima de `25` pertence aos anos 1900, e `25` ou menos pertence aos anos 2000:

```schooling-example
{
  "language": "python",
  "file": "years.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom raw_customers import customers\n\n",
      "note": "Os clientes como texto, sem as linhas repetidas."
    },
    {
      "code": "year = customers[\"birth_year\"].mask(customers[\"birth_year\"] == \"1900\")\n",
      "note": "**O marcador** `1900` vira vazio primeiro, para nunca chegar à regra do século."
    },
    {
      "code": "two = year.str.len() == 2\n",
      "note": "Quais valores têm dois dígitos."
    },
    {
      "code": "# Customers are adults: a two-digit year above 25 is 19xx, at most 25 is 20xx.\nfull = year.mask(two & (year > \"25\"), \"19\" + year).mask(two & (year <= \"25\"), \"20\" + year)\n",
      "note": "**A regra do século.** A comparação é entre strings, o que é seguro aqui porque os dois lados têm exatamente dois dígitos."
    },
    {
      "code": "customers[\"birth\"] = pd.to_numeric(full).astype(\"Int64\")\n",
      "note": "Texto para número, depois para o inteiro anulável, para que os vazios continuem vazios."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from years import customers as c; t = c[c['birth_year'].str.len() == 2]; print(t[['birth_year', 'birth']].drop_duplicates().sort_values('birth').head(4).to_string(index=False)); print(c['birth'].min(), c['birth'].max(), c['birth'].isna().sum())"
birth_year  birth
        52   1952
        54   1954
        55   1955
        56   1956
1952 2006 670
```

O cliente de dois dígitos mais velho nasceu em 1952, o mais novo em 2006, e os 670 vazios são os
332 que ninguém preencheu mais os 338 marcadores das lojas, agora abertamente desconhecidos.
**Cada valor ou virou um ano plausível ou virou vazio de propósito**, e o comentário no código diz
qual suposição decidiu o século, para que a próxima pessoa possa discordar dela.

A regra tem uma borda, e vale dizer em voz alta. Um cliente nascido em 1925 que digitou `25` agora
aparece como nascido em 2025. O `%y` do próprio Python põe a linha em outro lugar: `68` vira 2068
e `69` vira 1969, então por ele o cliente nascido em 1952 teria nascido em 2052. Uma planilha usa
ainda outro corte. **Nenhum corte serve para todo arquivo**; o que serve é o que
combina com quem as pessoas do arquivo podem ser.

Este laboratório tem um gabarito que o trabalho real nunca tem, então dá para conferir a regra:

```
ana@lab:~/clean$ python -c "import pandas as pd; from years import customers as c; t = pd.read_csv('~/clean-data/truth/people.csv', dtype={'birth_year': 'Int64'}); m = c[c['birth_year'].str.len() == 2].merge(t[['customer_id', 'birth_year']], on='customer_id', suffixes=('', '_true')); print(len(m), (m['birth'] == m['birth_year_true']).sum())"
103 103
```

O arquivo de verdade conhece 103 dos clientes de dois dígitos, e a regra dá a todos os 103 o ano
certo. Sem gabarito, a verificação é a da última seção desta aula: uma coluna de anos de
nascimento com uma restrição que recusa quem é velho demais para estar comprando ou novo demais
para ter conta.
