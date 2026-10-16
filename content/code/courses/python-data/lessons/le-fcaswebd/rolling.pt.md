---
title: rolling, uma janela que desliza
version: 1
---

**O `rolling(n)` calcula uma estatística numa janela das últimas `n` linhas, em cada linha.** Uma média
móvel de sete dias troca cada dia pela média da semana que termina nele, o que alisa o ritmo semanal
e deixa a tendência.

```python
week_mean = daily.rolling(7).mean()
week_mean.head(8).round(1)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04     NaN
2025-01-05     NaN
2025-01-06     NaN
2025-01-07    92.3
2025-01-08    91.4
Freq: D, dtype: float64
```

Os seis primeiros dias são `NaN`: uma janela de sete precisa de sete valores, e em 6 de janeiro só
existem seis dias. A partir de 7 de janeiro cada valor é a média daquele dia e dos seis anteriores.
**A janela termina na linha com que é rotulada**, que é o que "à direita" quer dizer, e é o que se quer
quando a pergunta é "como foram os últimos sete dias".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dez dias seguidos, de 1 a 10 de janeiro. Uma janela à direita de sete dias cobre de 1 a 7 de janeiro e a média dela é escrita em 7 de janeiro. Uma janela centrada cobre os mesmos sete dias e a média é escrita em 4 de janeiro, o meio, então três dos seus dias ficam depois do dia em que ela é escrita.\" data-fig=\"window\"><defs><marker id=\"window-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"44\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"72.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1 jan</text><rect x=\"108\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"136.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2 jan</text><rect x=\"172\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3 jan</text><rect x=\"236\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"264.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4 jan</text><rect x=\"300\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"328.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5 jan</text><rect x=\"364\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6 jan</text><rect x=\"428\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7 jan</text><rect x=\"492\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8 jan</text><rect x=\"556\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"584.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9 jan</text><rect x=\"620\" y=\"100\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10 jan</text><path d=\"M44 94 L44 84 L484 84 L484 94\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"264.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rolling(7)</text><line x1=\"456.0\" y1=\"46\" x2=\"456.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#window-ah)\"></line><text x=\"456.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrita no dia 7</text><path d=\"M44 146 L44 156 L484 156 L484 146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"379.2\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rolling(7, center=True)</text><line x1=\"264.0\" y1=\"200\" x2=\"264.0\" y2=\"144\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#window-ah)\"></line><text x=\"264.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escrita no dia 4: os dias 5, 6 e 7 são o futuro dela</text></svg>", "caption": "Os mesmos sete dias, escritos no último deles ou no do meio."}
```

O `min_periods` deixa uma janela com menos valores dar resposta:

```python
daily.rolling(7, min_periods=1).mean().head(3).round(1)
```

```
started_at
2025-01-01    106.0
2025-01-02    107.0
2025-01-03    109.7
Freq: D, dtype: float64
```

O primeiro valor é a média de um dia, o segundo de dois. Isso preenche o começo da série, e também
quer dizer que os primeiros valores são mais ruidosos que o resto parecendo iguais. Use quando uma
janela curta ainda é uma resposta honesta, e diga isso em qualquer gráfico que a mostre.

## Centrada, e o futuro

`center=True` põe a janela em volta da linha em vez de antes dela:

```python
daily.rolling(7, center=True).mean().head(5).round(1)
```

```
started_at
2025-01-01     NaN
2025-01-02     NaN
2025-01-03     NaN
2025-01-04    92.3
2025-01-05    91.4
Freq: D, dtype: float64
```

4 de janeiro agora carrega a média de 1 a 7 de janeiro, três dias dos quais estão no futuro dele.
**Uma janela centrada olha para a frente.** Isso serve para descrever um ano que já acabou, em que a
curva se alinha com os dias que descreve. É errado para qualquer coisa que vá ser usada num dia em que
o futuro ainda não se conhece, uma previsão ou um alerta, porque o número usado no teste contém
informação que o dia real não vai ter.

## O que o alisamento mostra

O dia sozinho mais calmo foi 17 de maio, com 28 viagens. A semana mais calma é outra coisa:

```python
week_mean.idxmin(), round(week_mean.min(), 1)
```

```
(Timestamp('2025-06-22 00:00:00'), np.float64(69.4))
```

A semana que terminou em 22 de junho teve em média 69,4 viagens por dia. Um sábado chuvoso faz um dia
baixo; uma semana baixa diz que alguma coisa durou. Toda agregação que o `groupby` conhece funciona
numa janela também, `sum`, `median`, `max`, `std`, e `rolling(7).sum()` é o total da semana em cada
dia.
