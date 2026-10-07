---
title: O padrão dos vazios
version: 1
---

**Vazios raramente estão espalhados. Eles se alinham com alguma coisa, e aquilo com que se alinham é
a primeira pista do seu mecanismo.** A técnica é a que a aula 2 usou para formatos: separar a
ausência de cada coluna pelas colunas que poderiam explicá-la, e procurar as células que são tudo
ou nada.

Para os pedidos, as candidatas são o canal, como o pedido foi atendido e por quem:

```schooling-example
{
  "language": "python",
  "file": "pattern.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "`drop_duplicates()` tira os 25 pedidos repetidos, para nenhum pedido contar duas vezes numa fração."
    },
    {
      "code": "orders[\"segment\"] = orders[\"fulfilment\"] + \" / \" + orders[\"courier\"].fillna(\"-\")\n",
      "note": "Um segmento é como o pedido foi atendido e por quem. Uma retirada não tem entregador, então `-` o representa no rótulo; a coluna em si fica como está."
    },
    {
      "code": "share = (orders[[\"courier\", \"delivery_minutes\", \"discount\"]].isna()\n         .groupby([orders[\"channel\"], orders[\"segment\"]]).mean() * 100)\n",
      "note": "`isna()` transforma cada coluna em verdadeiro e falso, e a média de verdadeiros e falsos dentro de um grupo é a fração vazia."
    },
    {
      "code": "print(share.round(1))\n",
      "note": "Frações em percentual, uma linha por canal e segmento."
    }
  ]
}
```

```
ana@lab:~/clean$ python pattern.py
                            courier  delivery_minutes  discount
channel segment                                                
app     delivery / Rapidex      0.0             100.0       0.0
        delivery / propria      0.0               6.9       0.0
        pickup / -            100.0             100.0       0.0
site    delivery / Rapidex      0.0             100.0      88.8
        delivery / propria      0.0               6.8      87.9
        pickup / -            100.0             100.0      87.8
```

Leia como um mapa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-pattern-map\" aria-label=\"Uma grade da fração de células vazias em três colunas do arquivo de pedidos, para seis grupos de pedidos. O entregador está vazio em toda retirada e em nenhum outro lugar. Os minutos de entrega estão vazios em toda retirada e em toda entrega da Rapidex, e em cerca de sete por cento das da frota própria. O desconto está vazio em quase nove de dez pedidos do site e em nenhum do aplicativo.\"><text x=\"320.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">courier</text><text x=\"460.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">delivery_minutes</text><text x=\"600.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">discount</text><text x=\"238.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app · Rapidex</text><rect x=\"252.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><rect x=\"392.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"532.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><text x=\"238.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app · propria</text><rect x=\"252.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><rect x=\"392.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6,9%</text><rect x=\"532.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><text x=\"238.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">app · retirada</text><rect x=\"252.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"392.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"532.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><text x=\"238.0\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site · Rapidex</text><rect x=\"252.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><rect x=\"392.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"532.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">88,8%</text><text x=\"238.0\" y=\"212.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site · propria</text><rect x=\"252.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0,0%</text><rect x=\"392.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6,8%</text><rect x=\"532.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87,9%</text><text x=\"238.0\" y=\"248.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">site · retirada</text><rect x=\"252.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"392.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100,0%</text><rect x=\"532.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87,8%</text></svg>", "caption": "Leia descendo uma coluna e atravessando uma linha: cada vazio se alinha com algo que você vê, menos os 7% de tempos da frota própria."}
```

- **`courier`** está vazio em 100% das retiradas e em 0% de todo o resto. Totalmente explicado por
  `fulfilment`: não se aplica.
- **`discount`** está vazio em cerca de 88% dos pedidos do site, igual em todos os segmentos, e em
  nenhum pedido do aplicativo. Explicado por `channel`, e a taxa é a fração de pedidos do site sem
  cupom, o que a aula 2 já tinha estabelecido.
- **`delivery_minutes`** está vazio em 100% das retiradas e em 100% das entregas da Rapidex — as duas
  coisas explicadas — e em cerca de 7% das da frota própria, nos dois canais.

**Células em 0% e em 100% são explicações; as do meio são perguntas.** Tudo aqui está explicado,
menos uma célula em cada canal, e as duas concordam entre si, o que já é informação: o que esvazia
os tempos da frota própria não liga para qual sistema recebeu o pedido.

## Seguindo a que sobrou

Separar a frota própria pelo status do pedido dá o passo seguinte:

```
ana@lab:~/clean$ psql -c "SELECT status, count(*) AS orders, count(delivery_minutes) AS timed FROM (SELECT DISTINCT * FROM raw.orders) o WHERE courier = 'propria' GROUP BY status ORDER BY orders DESC"
  status   | orders | timed 
-----------+--------+-------
 delivered |  14835 | 14394
 cancelled |    643 |     0
 refunded  |    479 |   464
(3 rows)
```

Os 643 pedidos cancelados não têm tempo e não precisam; ninguém os entregou, então eles vão para a
pilha do não se aplica. Sobram 441 pedidos entregues e 15 reembolsados: **456 vazios ao lado de
14.858 entregas cronometradas, cerca de 3%**, sem nada em `channel`, `fulfilment`, `courier` ou
`status` que os explique.

Três por cento parece pouco o bastante para ignorar, e esse é o instinto que esta aula existe para
interromper. Uma taxa pequena de ausência faz pouco estrago se for MCAR. Se for MNAR, uma taxa
pequena pode esconder exatamente os casos de que um relatório trata. A próxima seção descobre qual
é o caso aqui.
