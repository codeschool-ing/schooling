---
title: Reduções, e o eixo ao longo do qual correm
version: 1
---

**Uma redução transforma muitos valores em um: `sum`, `mean`, `min`, `max`, `std`.** Numa
tabela, a pergunta é sempre *um valor por quê*, e o argumento `axis` a responde.

Pegue os primeiros 364 dias de temperatura, exatamente 52 semanas, e disponha uma semana por linha:

```python
weeks = temp[:364].reshape(52, 7)
weeks.shape, weeks.mean()
```
```
((52, 7), np.float64(29.93324175824176))
```

Sem `axis`, a redução percorre todos os elementos: um número, a média de 364 dias. Com um eixo, ela
corre **ao longo** desse eixo e o remove do formato:

```python
weekly = weeks.mean(axis=1)
by_position = weeks.mean(axis=0)
weekly.shape, weekly[:3].round(2), by_position.round(2)
```
```
((52,),
 array([30.37, 30.61, 30.53]),
 array([30.02, 29.85, 29.96, 29.91, 30.1 , 29.82, 29.87]))
```

`axis=1` corre ao longo de cada linha, pelos sete dias, e deixa uma média por semana: 52 delas.
`axis=0` desce cada coluna, pelas 52 semanas, e deixa uma média por posição na semana: 7 delas. A
regra que nunca falha: **o eixo que você nomeia é o que some.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma tabela de 52 semanas por 7 dias. mean com axis=1 percorre cada linha e deixa 52 médias semanais, uma por linha. mean com axis=0 desce cada coluna e deixa 7 médias, uma por posição do dia. O eixo nomeado é o que some.\" data-fig=\"axis\"><defs><marker id=\"axis-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">weeks, formato (52, 7)</text><rect x=\"40\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"40\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"64\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"88\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"112\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"74\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"108\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"176\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244\" y=\"136\" width=\"34\" height=\"24\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"159.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">⋮</text><line x1=\"44\" y1=\"52\" x2=\"274\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><line x1=\"57\" y1=\"44\" x2=\"57\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><rect x=\"330\" y=\"30\" width=\"340\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">weeks.mean(axis=1)</text><text x=\"500.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ao longo de cada linha: 52 valores, formato (52,)</text><rect x=\"330\" y=\"140\" width=\"340\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">weeks.mean(axis=0)</text><text x=\"500.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descendo cada coluna: 7 valores, formato (7,)</text><line x1=\"286\" y1=\"52\" x2=\"326\" y2=\"65\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line><line x1=\"57\" y1=\"162\" x2=\"326\" y2=\"175\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#axis-ah)\"></line></svg>", "caption": "O eixo que você nomeia é o que some: (52, 7) vira (52,) ou (7,)."}
```

2025 começou numa quarta-feira, então a posição 0 é toda quarta e a posição 4 todo domingo. As
sete médias ficam a poucos décimos umas das outras, o que se espera do tempo, já que ele não sabe
que dia é; as viagens, na aula 13, não serão tão iguais.

## Valores faltantes numa redução

A coluna de chuva tem seis `nan`, e uma redução encontra todos:

```python
rain.sum(), np.nansum(rain), np.nanmean(rain), np.nanmax(rain)
```
```
(np.float64(nan),
 np.float64(1712.8),
 np.float64(4.771030640668523),
 np.float64(45.9))
```

`rain.sum()` é `nan`: um dia desconhecido torna o total do ano desconhecido, o que é a resposta
honesta e uma inútil. As versões com prefixo `nan` **ignoram** os valores faltantes e reduzem o que
sobra. Isso é uma decisão, não uma correção. O total do ano pelo `nansum` é o total de 359 dias
conhecidos, e se os seis faltantes foram chuvosos, ele está baixo demais. Diga isso onde quer que o
informe.

| simples | ignora `nan` |
|---|---|
| `sum`, `mean`, `max`, `min`, `std` | `np.nansum`, `np.nanmean`, `np.nanmax`, `np.nanmin`, `np.nanstd` |

O pandas, a partir da aula 9, pula valores faltantes nas reduções por padrão, que é a segunda
escolha feita por você; a aula 12 diz como torná-la a primeira.
