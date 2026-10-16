---
title: Que linhas sobrevivem, e o argumento que decide
version: 1
---

**O `how` decide o que acontece com uma linha cuja chave não tem par do outro lado.** Duas tabelas
pequenas mostram as quatro respostas melhor que trinta mil viagens:

```python
left = pd.DataFrame({"station_id": ["S01", "S02", "S03"], "trips": [10, 20, 30]})
right = pd.DataFrame({"station_id": ["S02", "S03", "S04"], "docks": [20, 20, 14]})
left.merge(right, on="station_id", how="inner")
```

```
  station_id  trips  docks
0        S02     20     20
1        S03     30     20
```

`S01` não tem docas e `S04` não tem viagens, então a junção **inner** mantém só as duas chaves
presentes nos dois lados. É o padrão do `merge`, e vale lembrar: um merge sem `how` descarta toda
linha sem par sem dizer nada.

```python
left.merge(right, on="station_id", how="left")
```

```
  station_id  trips  docks
0        S01     10    NaN
1        S02     20   20.0
2        S03     30   20.0
```

Uma junção **left** mantém toda linha da tabela da esquerda e preenche o lado que falta com `NaN`. Uma
junção **right** é o espelho. Uma junção **outer** mantém tudo, e `indicator=True` acrescenta uma
coluna dizendo de onde veio cada linha:

```python
left.merge(right, on="station_id", how="outer", indicator=True)
```

```
  station_id  trips  docks      _merge
0        S01   10.0    NaN   left_only
1        S02   20.0   20.0        both
2        S03   30.0   20.0        both
3        S04    NaN   14.0  right_only
```

`_merge` é uma coluna categórica com três valores, `left_only`, `right_only` e `both`, e as contagens
dela são a auditoria mais rápida que uma junção tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As chaves que cada tipo de junção mantém. A esquerda tem S01, S02 e S03; a direita tem S02, S03 e S04. Inner mantém S02 e S03. Left mantém S01, S02 e S03. Right mantém S02, S03 e S04. Outer mantém as quatro.\" data-fig=\"how\"><text x=\"310.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S01</text><text x=\"410.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S02</text><text x=\"510.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S03</text><text x=\"610.0\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">S04</text><text x=\"130\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na esquerda</text><text x=\"130\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na direita</text><text x=\"310.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"310.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"410.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"410.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"510.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"510.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><text x=\"610.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"610.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><line x1=\"150\" y1=\"80\" x2=\"690\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"130\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;inner&quot;</text><rect x=\"270\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"92\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;left&quot;</text><rect x=\"270\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S01</text><rect x=\"370\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"130\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;right&quot;</text><rect x=\"270\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"370\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"168\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S04</text><text x=\"130\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">how=&quot;outer&quot;</text><rect x=\"270\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S01</text><rect x=\"370\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S02</text><rect x=\"470\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S03</text><rect x=\"570\" y=\"206\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S04</text></svg>", "caption": "Que chaves sobrevivem a cada how. Uma célula tracejada é uma chave que a junção descartou."}
```

## As linhas que o padrão descarta

Agora as tabelas de verdade. A estação final de cada viagem, contra a lista de estações:

```python
ids = stations[["station_id"]].drop_duplicates()
ends = trips.merge(ids, left_on="end_station", right_on="station_id", how="left", indicator=True)
ends["_merge"].value_counts()
```

```
_merge
both          33191
left_only       146
right_only        0
Name: count, dtype: int64
```

**146 viagens não acharam estação**: as bicicletas perdidas, cuja `end_station` falta, enquanto a
lista de estações não tem código faltante com que pareá-las. Com o padrão `how="inner"` essas viagens
teriam saído da tabela, e toda contagem montada sobre ela ficaria 146 abaixo, a mesma perda que a aula
13 achou no `groupby`. `right_only` é 0, então toda estação tem viagens terminando nela.

Chave faltante dos **dois** lados é outra história. Diferente do SQL, o pandas as pareia:

```python
a = pd.DataFrame({"k": ["S01", np.nan]})
b = pd.DataFrame({"k": [np.nan, "S01"], "v": [1, 2]})
a.merge(b, on="k")
```

```
     k  v
0  S01  2
1  NaN  1
```

As duas lacunas casaram como se faltante fosse uma estação. **Decida o que uma chave faltante quer
dizer antes da junção**: descarte essas linhas, ou mantenha-as de propósito com uma junção left a
partir da tabela que importa.

**Escolha o `how` de propósito, e olhe o `_merge` na primeira vez.** Uma junção left mantém inteira a
tabela que importa; o indicador diz quanto dela achou par.
