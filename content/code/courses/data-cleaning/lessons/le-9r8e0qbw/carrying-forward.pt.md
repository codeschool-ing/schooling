---
title: Levar o último valor adiante
version: 1
---

**Numa série no tempo, um vazio costuma ser preenchido com o último valor antes dele.** Para algumas
colunas isso está exatamente certo e para outras inventa dado, e a diferença é se a coluna descreve
um **estado** ou um **fluxo**.

Um estado persiste até mudar: um preço, um nível de estoque, um câmbio, o endereço de um cliente. Se
o preço era R$ 6,90 na segunda e nada foi registrado na terça, R$ 6,90 é a melhor estimativa para a
terça. Um fluxo é uma contagem num período: vendas, entregas, visitantes. As vendas de segunda não
dizem nada sobre as de terça.

A loja Batel, na semana da Páscoa de 2025, por dia:

```schooling-example
{
  "language": "python",
  "file": "daily.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "sales = pd.read_csv(\"raw/store_sales.csv\", sep=\";\", encoding=\"latin-1\", dtype=str)\nsales[\"day\"] = pd.to_datetime(sales[\"data\"], format=\"%d/%m/%Y\")\n",
      "note": "O arquivo do caixa lido como a aula 2 descobriu, com as datas de dia primeiro lidas por um formato explícito."
    },
    {
      "code": "sales[\"reais\"] = pd.to_numeric(sales[\"total\"].str[3:].str.replace(\",\", \".\"))\n",
      "note": "`R$ 94,50` vira 94.50: tirar o `R$ `, trocar a vírgula por ponto. Basta para 2025, que não tem venda de mil reais; a aula 7 escreve a conversão que também sobrevive a uma."
    },
    {
      "code": "batel = sales[sales[\"loja\"] == \"Batel\"].groupby(\"day\")[\"reais\"].sum()\n",
      "note": "Um total por dia para a loja Batel. Um dia sem venda não tem linha nenhuma."
    },
    {
      "code": "days = pd.date_range(\"2025-04-14\", \"2025-04-22\")\nweek = batel.reindex(days)\n",
      "note": "`reindex` sobre todo dia do calendário da semana da Páscoa devolve os dias ausentes, como `NaN`."
    },
    {
      "code": "print(pd.DataFrame({\"as_found\": week, \"ffill\": week.ffill(), \"zero\": week.fillna(0)}))\n",
      "note": "A mesma semana de três jeitos: como veio, levada adiante e preenchida com zero."
    }
  ]
}
```

```
ana@lab:~/clean$ python daily.py
            as_found  ffill   zero
2025-04-14     598.8  598.8  598.8
2025-04-15     790.1  790.1  790.1
2025-04-16     514.5  514.5  514.5
2025-04-17     348.0  348.0  348.0
2025-04-18       NaN  348.0    0.0
2025-04-19     800.9  800.9  800.9
2025-04-20       NaN  800.9    0.0
2025-04-21       NaN  800.9    0.0
2025-04-22     492.5  492.5  492.5
```

Três dias não têm venda nenhuma. Sexta, dia 18, foi Sexta-feira Santa, domingo, dia 20, um domingo,
e segunda, dia 21, Tiradentes — as lojas fecham aos domingos e nos feriados nacionais, como a aula
14 confirma pelo calendário. **Os dias faltam no arquivo porque nada aconteceu**, não porque um
registro se perdeu.

`ffill` preenche a Sexta-feira Santa com os R$ 348,00 de quinta e o domingo e o Tiradentes com os
R$ 800,90 de sábado: R$ 1.949,80 de vendas numa semana em que elas nunca aconteceram, numa loja que
estava fechada. Preenchida com zero, a semana soma o que o caixa recebeu. **Para um fluxo, um dia
sem registro é um dia sem fluxo**, desde que o negócio confirme que estava fechado — um caixa que
travou também deixaria um dia vazio, e esse falta de verdade.

A regra é curta o bastante para guardar: leve estados adiante, ponha zero em fluxos quando nada
aconteceu, e deixe vazio um fluxo quando algo aconteceu e ninguém registrou.
