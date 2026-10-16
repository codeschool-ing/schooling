---
title: Duas Series se alinham pelo rótulo, não pela posição
version: 1
---

**Quando duas Series se encontram numa conta, o pandas casa os elementos pelo rótulo primeiro e
calcula depois.** O NumPy casava pela posição, e a aula 6 mostrou o que acontece quando as posições
querem dizer coisas diferentes. O pandas não comete esse erro. Ele comete outro, que é o assunto
desta seção.

Duas Series pequenas, as docas de três estações cada, em ordens diferentes e com estações não
exatamente iguais:

```python
docks = pd.Series({"S01": 14, "S02": 20, "S03": 12})
added = pd.Series({"S03": 4, "S01": 2, "S04": 6})
docks + added
```

```
S01    16.0
S02     NaN
S03    16.0
S04     NaN
dtype: float64
```

`S01` ganhou o seu 2 e `S03` o seu 4, embora estivessem em posições diferentes, porque os rótulos
casaram. **`S02` e `S04` viraram `NaN`**: cada rótulo está em só uma das Series, então não há a
que somá-lo, e o pandas diz "desconhecido" em vez de adivinhar. O índice do resultado é a união dos
dois, ordenada. E o dtype virou `float64`, porque `NaN` é um float, o mesmo motivo que a aula 4 deu
para o NumPy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"À esquerda: docks com rótulos S01 14, S02 20, S03 12. No meio: added com rótulos S03 4, S01 2, S04 6, em outra ordem. À direita: docks + added, casados por rótulo: S01 16, S02 NaN, S03 16, S04 NaN. Linhas ligam rótulos iguais entre as duas entradas; S02 e S04 não têm par.\" data-fig=\"align\"><text x=\"80\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">docks</text><rect x=\"20\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"80\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">14</text><rect x=\"20\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S02</text><rect x=\"80\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><rect x=\"20\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"80\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"320\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">added</text><rect x=\"260\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"320\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"260\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"320\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"260\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S04</text><rect x=\"320\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"620\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">docks + added</text><rect x=\"560\" y=\"40\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S01</text><rect x=\"620\" y=\"40\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16.0</text><rect x=\"560\" y=\"80\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S02</text><rect x=\"620\" y=\"80\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">NaN</text><rect x=\"560\" y=\"120\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S03</text><rect x=\"620\" y=\"120\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16.0</text><rect x=\"560\" y=\"160\" width=\"56\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">S04</text><rect x=\"620\" y=\"160\" width=\"60\" height=\"30\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"650\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">NaN</text><line x1=\"144\" y1=\"55\" x2=\"256\" y2=\"95\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"144\" y1=\"135\" x2=\"256\" y2=\"55\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"200\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">S02: sem par</text><text x=\"320\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">S04: sem par</text></svg>", "caption": "O pandas casa rótulos antes de somar. Um rótulo de um lado só dá NaN."}
```

Quando um rótulo faltante deve contar como zero, diga:

```python
docks.add(added, fill_value=0)
```

```
S01    16.0
S02    20.0
S03    16.0
S04     6.0
dtype: float64
```

`add` é o método por trás do `+`, e o `fill_value` dele é o valor que o lado faltante assume.
`sub`, `mul` e `div` têm o mesmo argumento.

## A armadilha é a oposta à do NumPy

O alinhamento é tão confiável que as pessoas param de pensar nele, e aí saem dele sem querer.
`.to_numpy()` e `.values` jogam o índice fora. Aritmética sobre o que eles devolvem é do NumPy, por
posição:

```python
docks.to_numpy() + added.to_numpy()
```

```
array([18, 22, 18])
```

Três números, todos errados: o 14 da `S01` mais o 4 da `S03`, e assim por diante. Nenhum `NaN`,
nada para avisar. **Dentro do pandas, os rótulos decidem; no momento em que você pega o
`.to_numpy()`, as posições decidem.** Pegue-o quando precisar, no fim, e não no meio de uma conta.
