---
title: Fusos horários: o mesmo instante, dois relógios
version: 1
---

**Um horário sem fuso é uma leitura num relógio sem nome.** O aplicativo escreve
`2025-01-01 07:00:30` e quer dizer São Paulo. O site escreve `2025-01-01T11:24:01Z`, e o `Z` — de
"Zulu", o nome militar do UTC — diz que o relógio é UTC. São Paulo está três horas atrás do UTC o ano
inteiro desde que o Brasil acabou com o horário de verão, em 2019, então 11:24 UTC são 08:24 na loja.

Convertendo cada origem para um relógio só:

```schooling-example
{
  "language": "python",
  "file": "when.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\nsite = orders[\"channel\"] == \"site\"\n",
      "note": "Os pedidos sem as repetições, e uma máscara para os do site."
    },
    {
      "code": "utc = pd.to_datetime(orders.loc[site, \"ordered_at\"], format=\"%Y-%m-%dT%H:%M:%SZ\", utc=True)\n",
      "note": "Os horários do site, lidos como UTC: o formato inclui o `Z` literal, e `utc=True` diz o que ele significa."
    },
    {
      "code": "local = pd.to_datetime(orders.loc[~site, \"ordered_at\"], format=\"%Y-%m-%d %H:%M:%S\")\n",
      "note": "Os do aplicativo, sem fuso: hora local como escrita."
    },
    {
      "code": "orders.loc[site, \"placed\"] = utc.dt.tz_convert(\"America/Sao_Paulo\").dt.tz_localize(None)\n",
      "note": "**Um relógio para os dois.** UTC convertido para São Paulo, e o rótulo de fuso tirado para a coluna guardar horas locais simples."
    },
    {
      "code": "orders.loc[~site, \"placed\"] = local\n"
    },
    {
      "code": "orders[\"placed\"] = pd.to_datetime(orders[\"placed\"])\n",
      "note": "Uma coluna de horas locais para todo pedido."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from when import orders as o; s = o[o['channel'] == 'site']; print(s[['ordered_at', 'placed']].head(3).to_string(index=False)); print((s['ordered_at'].str[:10] != s['placed'].dt.strftime('%Y-%m-%d')).sum())"
          ordered_at              placed
2025-01-01T11:24:01Z 2025-01-01 08:24:01
2025-01-01T12:53:12Z 2025-01-01 09:53:12
2025-01-01T13:59:17Z 2025-01-01 10:59:17
1335
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l07-two-clocks\" aria-label=\"Duas linhas do tempo, uma acima da outra, para o mesmo trecho de tempo. A de cima é UTC e a de baixo São Paulo, três horas atrás. Um pedido carimbado 02:00 de 2 de janeiro em UTC fica às 23:00 de 1º de janeiro em São Paulo: o mesmo instante, no dia anterior.\"><text x=\"60.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">UTC, como o site escreve</text><path d=\"M60.0 70.0 L680.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 66.0 L60.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M163.3 66.0 L163.3 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.3\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M266.7 66.0 L266.7 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"266.7\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M370.0 66.0 L370.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M473.3 66.0 L473.3 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.3\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03:00</text><path d=\"M576.7 66.0 L576.7 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"576.7\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M680.0 66.0 L680.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">09:00</text><path d=\"M370.0 94.0 L370.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 2\"></path><text x=\"364.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1º de janeiro</text><text x=\"376.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 de janeiro</text><text x=\"60.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo, como o cliente viu</text><path d=\"M60.0 170.0 L680.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 166.0 L60.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M163.3 166.0 L163.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M266.7 166.0 L266.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"266.7\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M370.0 166.0 L370.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M473.3 166.0 L473.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M576.7 166.0 L576.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"576.7\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03:00</text><path d=\"M680.0 166.0 L680.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M473.3 194.0 L473.3 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 2\"></path><text x=\"467.3\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1º de janeiro</text><text x=\"479.3\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 de janeiro</text><path d=\"M438.9 70.0 L438.9 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"438.9\" cy=\"70.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"438.9\" cy=\"170.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"448.9\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">02:00</text><text x=\"448.9\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">23:00</text><text x=\"492.9\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesmo instante, dia anterior</text><text x=\"492.9\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um pedido</text></svg>", "caption": "Todo pedido do site carimbado entre 00:00 e 02:59 UTC pertence à noite anterior no relógio do cliente: 1.335 deles em 2025."}
```

Os três primeiros pedidos do site voltam três horas, para os horários que um cliente em São Paulo viu
na tela. **1.335 pedidos do site também mudam de dia**: tudo o que foi carimbado de 00:00 a 02:59 UTC
foi feito na noite anterior, entre 21:00 e 23:59 no horário local.

Isso não é erro de arredondamento. Um relatório de pedidos por dia construído sobre o texto bruto
poria todo pedido do fim da noite na data errada, inflando as segundas com as noites de domingo e
empurrando os pedidos da véspera de Ano-Novo para 2026. Um relatório por hora mostraria os clientes do
site comprando às duas da manhã. A aula 3 evitou as duas coisas usando só os pedidos do aplicativo
para a hora do dia, e disse que voltaria a isto.

## Em SQL

O PostgreSQL lê o `Z` sozinho quando o texto vira `timestamptz`, e `AT TIME ZONE` dá a hora do relógio
local:

```
ana@lab:~/clean$ psql -c "SELECT ordered_at, (ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo') AS placed FROM raw.orders WHERE channel = 'site' LIMIT 3"
      ordered_at      |       placed        
----------------------+---------------------
 2025-01-01T11:24:01Z | 2025-01-01 08:24:01
 2025-01-01T12:53:12Z | 2025-01-01 09:53:12
 2025-01-01T13:59:17Z | 2025-01-01 10:59:17
(3 rows)
```

Duas regras valem para qualquer dado com horários:

- **guarde instantes em UTC, ou com o seu deslocamento, e converta na borda**, para exibir e para
  tudo que se agrupa por dia ou hora locais;
- **nomeie fusos pela região, `America/Sao_Paulo`, nunca pelo deslocamento, `-03:00`**. A região
  conhece a própria história, inclusive o horário de verão que São Paulo tinha antes de 2019; um
  deslocamento só está certo para as datas em que por acaso foi medido.
