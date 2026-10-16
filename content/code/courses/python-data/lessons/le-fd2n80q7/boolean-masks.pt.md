---
title: Máscaras booleanas, que selecionam por condição
version: 1
---

**Uma máscara booleana é um array de `True` e `False` do mesmo formato dos dados, e indexar com ela
fica com os elementos em que ela é `True`.** É como o NumPy diz "onde": os dias de chuva forte, os
domingos quentes, as leituras que não faltam. A aula 5 construiu máscaras e as contou; aqui elas
selecionam.

```python
heavy = rain > 20
heavy.shape, heavy.sum(), rain[heavy]
```

```
((365,),
 np.int64(20),
 array([25.2, 25. , 45.9, 28.3, 28.9, 29. , 20.8, 37.4, 25.4, 30.8, 29.4,
        41. , 21. , 41.4, 21.7, 23.9, 29.3, 21. , 40.9, 28.6]))
```

`rain[heavy]` é um array novo, unidimensional, com os 20 valores em que a máscara é `True`, na ordem
original.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Linha de cima: as oito primeiras leituras de chuva, 0.0, 6.8, 7.9, 15.7, 0.0, 0.0, 1.3, 0.0. Linha do meio: a máscara rain &gt; 5, True sob 6.8, 7.9 e 15.7 e False no resto. Embaixo: indexar com a máscara dá um array novo e mais curto, 6.8, 7.9, 15.7, que é uma cópia.\" data-fig=\"masking\"><defs><marker id=\"masking-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8]</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8] &gt; 5</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rain[:8][mask]</text><rect x=\"150\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"150\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"214\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.8</text><rect x=\"214\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"278\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.9</text><rect x=\"278\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"342\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"371.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15.7</text><rect x=\"342\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"371.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">True</text><rect x=\"406\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"406\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"470\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"470\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"534\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"563.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.3</text><rect x=\"534\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"563.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"598\" y=\"24\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0</text><rect x=\"598\" y=\"74\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">False</text><rect x=\"150\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"179.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.8</text><line x1=\"243.0\" y1=\"110\" x2=\"179.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><rect x=\"214\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"243.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7.9</text><line x1=\"307.0\" y1=\"110\" x2=\"243.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><rect x=\"278\" y=\"174\" width=\"58\" height=\"32\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"307.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15.7</text><line x1=\"371.0\" y1=\"110\" x2=\"307.0\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#masking-ah)\"></line><text x=\"352\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um array novo, de três: uma cópia</text></svg>", "caption": "Uma máscara guarda os elementos sob True, em ordem, num array novo."}
```

A mesma máscara, aplicada a outro array do mesmo comprimento, seleciona os elementos
correspondentes daquele, **que é como dois arrays se mantêm em passo**:

```python
dates[heavy][:5], temp[heavy].mean().round(2), temp[~heavy].mean().round(2)
```

```
(array(['2025-01-09', '2025-03-20', '2025-03-22', '2025-04-15',
        '2025-04-17'], dtype='<U10'),
 np.float64(29.49),
 np.float64(29.97))
```

As datas dos cinco primeiros dias de chuva forte, e a temperatura média nos dias de chuva forte
contra o resto. `~` inverte uma máscara, então `temp[~heavy]` é todo dia que não foi de chuva
forte, o que aqui inclui os seis dias sem leitura, porque `nan > 20` é `False`.

## Uma máscara não guarda formato

Numa tabela, uma máscara do mesmo formato seleciona elementos, e o resultado é plano, porque os
elementos escolhidos não formam mais linhas:

```python
hot = weeks > 31.5
weeks[hot].shape, weeks[hot][:4]
```

```
((18,), array([31.7, 32.1, 31.6, 31.9]))
```

Para manter linhas inteiras, mascare um eixo com uma máscara do comprimento desse eixo. As semanas em
que pelo menos um dia passou de 31,5:

```python
any_hot = hot.any(axis=1)
any_hot.shape, weeks[any_hot].shape
```

```
((52,), (16, 7))
```

`any(axis=1)` pergunta a cada linha se algum elemento é `True`; `all(axis=1)` perguntaria se todos
são. A máscara `(52,)` resultante seleciona linhas, e as linhas mantêm os sete dias.

## Os valores faltantes, tirados por seleção

A máscara que você vai escrever em quase todo notebook:

```python
known = ~np.isnan(rain)
known.sum(), rain[known].mean().round(3), np.nanmean(rain).round(3)
```

```
(np.int64(359), np.float64(4.771), np.float64(4.771))
```

A média dos valores conhecidos, de dois jeitos. `rain[known]` é explícito sobre o que foi deixado de
fora e deixa você contá-lo; `np.nanmean` faz o mesmo em silêncio. Quando você informar o número, a
versão explícita é a que lembra você de dizer "de 359 dias".
