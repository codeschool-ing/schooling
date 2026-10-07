---
title: Um calendário explica uma lacuna
version: 1
---

A aula 4 encontrou uma semana de abril com três dias sem venda nas lojas, Sexta-feira Santa, um
domingo e Tiradentes, e disse que esta aula confirmaria o motivo. O calendário de feriados
confirma, para o ano inteiro. O enriquecimento aqui vai no sentido contrário ao da seção anterior:
em vez de acrescentar uma coluna aos dados, ele pega cada feriado e pergunta aos dados o que
aconteceu naquele dia.

```schooling-example
{
  "language": "python",
  "file": "days.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "from when import orders\n\n",
      "note": "Os pedidos com o horário em São Paulo da aula 7."
    },
    {
      "code": "holidays = pd.read_csv(\"ref/holidays_2025.csv\", parse_dates=[\"date\"])\n",
      "note": "O calendário de feriados, com as datas lidas como datas."
    },
    {
      "code": "shops = pd.read_csv(\"raw/store_sales.csv\", sep=\";\", encoding=\"latin-1\", dtype=str)\nshops[\"day\"] = pd.to_datetime(shops[\"data\"], format=\"%d/%m/%Y\")\n",
      "note": "As vendas das lojas, cada uma com o seu dia."
    },
    {
      "code": "orders[\"day\"] = orders[\"placed\"].dt.normalize()\n\n",
      "note": "O dia de cada pedido, sem a hora."
    },
    {
      "code": "holidays[\"weekday\"] = holidays[\"date\"].dt.day_name()\n",
      "note": "O dia da semana em que cada feriado caiu."
    },
    {
      "code": "holidays[\"shop_sales\"] = holidays[\"date\"].map(shops.groupby(\"day\").size()).fillna(0).astype(int)\n",
      "note": "**Vendas nas lojas no dia.** Um dia sem linha não teve venda, então aqui uma contagem faltante é mesmo 0."
    },
    {
      "code": "holidays[\"online\"] = holidays[\"date\"].map(orders.groupby(\"day\").size()).fillna(0).astype(int)\n\n",
      "note": "Pedidos online no dia, contados do mesmo jeito."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(holidays.drop(columns=\"name\").to_string(index=False))\n",
      "note": "O calendário com o que aconteceu em cada data."
    }
  ]
}
```

```
ana@lab:~/clean$ python days.py
      date     kind   weekday  shop_sales  online
2025-01-01  holiday Wednesday           0      39
2025-03-03 optional    Monday          71      69
2025-03-04 optional   Tuesday          75      51
2025-03-05 optional Wednesday          80      49
2025-04-18  holiday    Friday           0      81
2025-04-21  holiday    Monday           0      82
2025-05-01  holiday  Thursday           0      92
2025-06-19 optional  Thursday          72      82
2025-09-07  holiday    Sunday           0      39
2025-10-12  holiday    Sunday           0      44
2025-11-02  holiday    Sunday           0      42
2025-11-15  holiday  Saturday           0     106
2025-11-20  holiday  Thursday           0      64
2025-12-25  holiday  Thursday           0      87
```

O padrão é completo. **Em todo feriado nacional as lojas não venderam nada**, e em todo ponto
facultativo, Carnaval, Quarta-feira de Cinzas e Corpus Christi, abriram normalmente. O canal online
recebeu pedidos todos os dias. Mais dois fatos saem da tabela:

- **Três feriados caíram num domingo** em 2025, 7 de setembro, 12 de outubro e 2 de novembro. As
  lojas nunca abrem aos domingos, então nesses três dias o calendário não explica nada que o dia da
  semana já não tivesse explicado.
- **15 de novembro caiu num sábado**, um dos dois dias mais fortes das lojas, e elas o perderam. Os
  pedidos online chegaram a 106, o maior número da tabela mas perto dos 97,8 de um sábado comum,
  mostrados abaixo. Se as lojas fechadas mandaram alguém para o online não dá para dizer com um dia
  só, e vale dizer isso antes que alguém leia isso no número.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-calendar\" aria-label=\"Vendas diárias das cinco lojas de março a maio de 2025, uma barra por dia. As barras caem a zero todo domingo e nos três feriados nacionais do período, a Sexta-feira Santa em 18 de abril, Tiradentes em 21 de abril e o Dia do Trabalho em 1º de maio. Nos pontos facultativos, os dois dias de Carnaval e a Quarta-feira de Cinzas no começo de março, as lojas venderam normalmente.\"><path d=\"M70.0 40.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 210.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 146.2 L690.0 146.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 146.2 L70.0 146.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"146.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M70.0 82.4 L690.0 82.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 82.4 L70.0 82.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"82.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">vendas nas lojas</text><rect x=\"70.8\" y=\"73.5\" width=\"5.1\" height=\"136.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"84.3\" y=\"119.4\" width=\"5.1\" height=\"90.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"86.8\" cy=\"222.0\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"91.0\" y=\"114.3\" width=\"5.1\" height=\"95.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"93.6\" cy=\"222.0\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"97.8\" y=\"108.0\" width=\"5.1\" height=\"102.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"100.3\" cy=\"222.0\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"104.5\" y=\"115.6\" width=\"5.1\" height=\"94.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"111.2\" y=\"69.7\" width=\"5.1\" height=\"140.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"118.0\" y=\"88.8\" width=\"5.1\" height=\"121.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"131.5\" y=\"108.0\" width=\"5.1\" height=\"102.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"138.2\" y=\"114.3\" width=\"5.1\" height=\"95.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"144.9\" y=\"114.3\" width=\"5.1\" height=\"95.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"151.7\" y=\"96.5\" width=\"5.1\" height=\"113.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"158.4\" y=\"69.7\" width=\"5.1\" height=\"140.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"165.1\" y=\"60.8\" width=\"5.1\" height=\"149.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"178.6\" y=\"106.7\" width=\"5.1\" height=\"103.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"185.4\" y=\"114.3\" width=\"5.1\" height=\"95.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"192.1\" y=\"104.1\" width=\"5.1\" height=\"105.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"198.8\" y=\"105.4\" width=\"5.1\" height=\"104.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"205.6\" y=\"71.0\" width=\"5.1\" height=\"139.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"212.3\" y=\"71.0\" width=\"5.1\" height=\"139.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"225.8\" y=\"108.0\" width=\"5.1\" height=\"102.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"232.5\" y=\"97.8\" width=\"5.1\" height=\"112.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"239.3\" y=\"113.1\" width=\"5.1\" height=\"96.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"246.0\" y=\"110.5\" width=\"5.1\" height=\"99.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"252.8\" y=\"68.4\" width=\"5.1\" height=\"141.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"259.5\" y=\"65.9\" width=\"5.1\" height=\"144.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"273.0\" y=\"101.6\" width=\"5.1\" height=\"108.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"279.7\" y=\"104.1\" width=\"5.1\" height=\"105.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"286.5\" y=\"92.7\" width=\"5.1\" height=\"117.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"293.2\" y=\"109.2\" width=\"5.1\" height=\"100.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"299.9\" y=\"60.8\" width=\"5.1\" height=\"149.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"306.7\" y=\"63.3\" width=\"5.1\" height=\"146.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"320.1\" y=\"110.5\" width=\"5.1\" height=\"99.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"326.9\" y=\"91.4\" width=\"5.1\" height=\"118.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"333.6\" y=\"105.4\" width=\"5.1\" height=\"104.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"340.4\" y=\"106.7\" width=\"5.1\" height=\"103.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"347.1\" y=\"60.8\" width=\"5.1\" height=\"149.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"353.8\" y=\"72.2\" width=\"5.1\" height=\"137.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"367.3\" y=\"111.8\" width=\"5.1\" height=\"98.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"374.1\" y=\"102.9\" width=\"5.1\" height=\"107.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"380.8\" y=\"106.7\" width=\"5.1\" height=\"103.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"387.5\" y=\"99.0\" width=\"5.1\" height=\"111.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"396.8\" cy=\"222.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"401.0\" y=\"64.6\" width=\"5.1\" height=\"145.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"417.1\" cy=\"222.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"421.2\" y=\"101.6\" width=\"5.1\" height=\"108.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"428.0\" y=\"97.8\" width=\"5.1\" height=\"112.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"434.7\" y=\"101.6\" width=\"5.1\" height=\"108.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"441.5\" y=\"63.3\" width=\"5.1\" height=\"146.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"448.2\" y=\"59.5\" width=\"5.1\" height=\"150.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"461.7\" y=\"102.9\" width=\"5.1\" height=\"107.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"468.4\" y=\"96.5\" width=\"5.1\" height=\"113.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"475.1\" y=\"115.6\" width=\"5.1\" height=\"94.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><circle cx=\"484.5\" cy=\"222.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><rect x=\"488.6\" y=\"64.6\" width=\"5.1\" height=\"145.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"495.4\" y=\"65.9\" width=\"5.1\" height=\"144.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"508.8\" y=\"101.6\" width=\"5.1\" height=\"108.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"515.6\" y=\"113.1\" width=\"5.1\" height=\"96.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"522.3\" y=\"96.5\" width=\"5.1\" height=\"113.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"529.1\" y=\"106.7\" width=\"5.1\" height=\"103.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"535.8\" y=\"58.2\" width=\"5.1\" height=\"151.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"542.5\" y=\"67.1\" width=\"5.1\" height=\"142.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"556.0\" y=\"105.4\" width=\"5.1\" height=\"104.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"562.8\" y=\"95.2\" width=\"5.1\" height=\"114.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"569.5\" y=\"92.7\" width=\"5.1\" height=\"117.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"576.2\" y=\"99.0\" width=\"5.1\" height=\"111.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"583.0\" y=\"72.2\" width=\"5.1\" height=\"137.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"589.7\" y=\"59.5\" width=\"5.1\" height=\"150.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"603.2\" y=\"110.5\" width=\"5.1\" height=\"99.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"609.9\" y=\"104.1\" width=\"5.1\" height=\"105.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"616.7\" y=\"99.0\" width=\"5.1\" height=\"111.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"623.4\" y=\"113.1\" width=\"5.1\" height=\"96.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"630.1\" y=\"77.3\" width=\"5.1\" height=\"132.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"636.9\" y=\"79.9\" width=\"5.1\" height=\"130.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"650.4\" y=\"105.4\" width=\"5.1\" height=\"104.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"657.1\" y=\"101.6\" width=\"5.1\" height=\"108.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"663.8\" y=\"93.9\" width=\"5.1\" height=\"116.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"670.6\" y=\"97.8\" width=\"5.1\" height=\"112.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"677.3\" y=\"73.5\" width=\"5.1\" height=\"136.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"684.1\" y=\"72.2\" width=\"5.1\" height=\"137.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><path d=\"M70.0 210.0 L690.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 210.0 L70.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"74.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">março</text><path d=\"M278.9 210.0 L278.9 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"282.9\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abril</text><path d=\"M481.1 210.0 L481.1 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"485.1\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">maio</text><circle cx=\"80.0\" cy=\"280.0\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"90.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">feriado nacional</text><circle cx=\"250.0\" cy=\"280.0\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"260.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ponto facultativo</text></svg>", "caption": "Toda falha nas barras é um domingo ou um feriado nacional; todo ponto facultativo é um dia normal de vendas. Sem o calendário, as três falhas de abril e maio seriam dado faltante."}
```

```
ana@lab:~/clean$ python -c "from days import shops, orders, holidays; s = shops.groupby('day').size(); print(round(s.mean(), 1), s.index.dayofweek.max()); o = orders.groupby('day').size(); h = o.index.isin(holidays.loc[holidays['kind'] == 'holiday', 'date']); print(round(o[~h].mean(), 1), round(o[h].mean(), 1), round(o[~h & (o.index.dayofweek == 5)].mean(), 1))"
77.1 5
78.5 67.6 97.8
```

As médias confirmam o desenho: as lojas fazem 77,1 vendas por dia quando abrem, e o último dia da
semana em que abrem é o 5, sábado. No online, um dia comum traz 78,5 pedidos, um feriado nacional 67,6 e
um sábado comum 97,8. Feriado é um dia mais calmo no online, não um dia fechado.

**O calendário transforma vazios em zeros explicados.** Sem ele, um dia sem venda nas lojas é um
valor faltante de causa desconhecida, o caso mais difícil da aula 3. Com ele, o zero é um fato com
motivo, e uma série diária pode ser preenchida com zeros exatamente nesses dias, pela regra que a
aula 4 deu para fluxos.
