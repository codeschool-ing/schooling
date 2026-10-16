---
title: O jeito antigo, e o estado global que ele compartilha
version: 1
---

**A maior parte do código na internet semeia o NumPy com `np.random.seed(42)` e sorteia com
`np.random.rand()`.** Essa é a interface que o NumPy tinha antes de 2019, e ela ainda funciona. O
problema dela é que há um único gerador escondido para o programa todo, e qualquer coisa que sorteie
dele o faz avançar, inclusive código que você não escreveu.

```python
np.random.seed(42)
np.random.randint(1, 7, size=5)
```

```
array([4, 5, 3, 5, 5])
```

Mesma semente, os mesmos cinco números, como com um Generator. Agora as mesmas duas linhas com um
auxiliar no meio, o tipo de função que um colega poderia ter escrito, que por acaso embaralha algo:

```python
def tidy(values):
    values = list(values)
    np.random.shuffle(values)
    return sorted(values)

np.random.seed(42)
tidy([3, 1, 2])
np.random.randint(1, 7, size=5)
```

```
array([5, 3, 5, 5, 2])
```

**Números diferentes, da mesma semente**, porque `tidy` sorteou do gerador global antes da sua
linha. O resultado dela foi ordenado, então o embaralhamento não mudou nada que se visse, a não ser
todo número aleatório depois dele. Acrescente uma chamada, tire uma, atualize uma biblioteca que
sorteia por dentro, e todo resultado "semeado" dali para baixo muda. Nada avisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Em cima: uma sequência global da semente 42. Sem o auxiliar, a sua linha pega os cinco primeiros valores. Com o auxiliar, o embaralhamento dele pega os primeiros e a sua linha recebe os cinco seguintes, outros. Embaixo: o seu próprio gerador da semente 42 é uma sequência separada que o auxiliar nunca toca, então a sua linha sempre pega os cinco primeiros.\" data-fig=\"shared\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">np.random.seed(42): uma sequência para o programa todo</text><rect x=\"20\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"39\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"62\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"81\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><rect x=\"104\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"123\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><rect x=\"146\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"165\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><rect x=\"188\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"207\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v5</text><rect x=\"230\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v6</text><rect x=\"272\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"291\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v7</text><rect x=\"314\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v8</text><rect x=\"356\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"375\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v9</text><rect x=\"398\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"417\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v10</text><rect x=\"440\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"459\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v11</text><rect x=\"482\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"501\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v12</text><rect x=\"524\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"543\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v13</text><rect x=\"566\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v14</text><rect x=\"608\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v15</text><rect x=\"650\" y=\"40\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"669\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v16</text><rect x=\"20\" y=\"76\" width=\"122\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"81.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tidy()</text><rect x=\"146\" y=\"76\" width=\"206\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"249.0\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os seus cinco</text><text x=\"362\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">deslocados por quem sorteou antes</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">rng = np.random.default_rng(42): só seu</text><rect x=\"20\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"39\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w1</text><rect x=\"62\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"81\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w2</text><rect x=\"104\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"123\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w3</text><rect x=\"146\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"165\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w4</text><rect x=\"188\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"207\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w5</text><rect x=\"230\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w6</text><rect x=\"272\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"291\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w7</text><rect x=\"314\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w8</text><rect x=\"356\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"375\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w9</text><rect x=\"398\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"417\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w10</text><rect x=\"440\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"459\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w11</text><rect x=\"482\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"501\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w12</text><rect x=\"524\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"543\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w13</text><rect x=\"566\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w14</text><rect x=\"608\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"627\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w15</text><rect x=\"650\" y=\"152\" width=\"38\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"669\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">w16</text><rect x=\"20\" y=\"188\" width=\"206\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"123.0\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os seus cinco</text><text x=\"236\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iguais com ou sem tidy()</text></svg>", "caption": "Quem sorteia primeiro de um gerador compartilhado muda os números de todo mundo."}
```

Um Generator está imune, porque ninguém mais o segura:

```python
rng = np.random.default_rng(42)
tidy([3, 1, 2])
rng.integers(1, 7, size=5), np.random.default_rng(42).integers(1, 7, size=5)
```

```
(array([1, 5, 4, 3, 3]), array([1, 5, 4, 3, 3]))
```

`tidy` continuou sorteando do gerador global; `rng` é um objeto separado, e a sequência dele fica
intacta: os cinco números dele são os que um gerador novo da mesma semente sorteia, com ou sem
`tidy`. **Passe o seu gerador para as funções que precisam de aleatoriedade**, como argumento, em
vez de deixá-las pegar um global.

| antigo, global | novo, um Generator |
|---|---|
| `np.random.seed(42)` | `rng = np.random.default_rng(42)` |
| `np.random.rand(3)` | `rng.random(3)` |
| `np.random.randint(1, 7, 5)` | `rng.integers(1, 7, 5)` |
| `np.random.normal(0, 1, 5)` | `rng.normal(0, 1, 5)` |
| `np.random.choice(a, 3)` | `rng.choice(a, 3)` |

Os dois dão **números diferentes para a mesma semente**: usam algoritmos diferentes por baixo. Um
código levado de uma coluna para a outra mantém o comportamento e muda os resultados, uma vez, o que
vale dizer no commit que faz a mudança.
