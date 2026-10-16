---
title: Rótulos que cabem
version: 1
---

**O matplotlib dispõe uma figura pensando em rótulos curtos, e um longo é cortado na borda da imagem.**
Nada avisa: o gráfico parece pronto no notebook, e o arquivo que você manda está sem o começo de cada
nome.

Viagens por estação de partida, com os nomes das estações. Cada código recebe o seu nome **atual**, a
última linha de cada código no `stations.csv`, porque o gráfico é sobre a estação e a aula 14 já
mostrou como nomear cada viagem pelo nome do seu dia:

```python
current = stations.drop_duplicates("station_id", keep="last").set_index("station_id")["name"]
per_station = trips["start_station"].map(current).value_counts().sort_values()
per_station.tail(3)
```

```
start_station
Espinheiro        2636
Rua da Aurora     2728
Praça do Derby    4154
Name: count, dtype: int64
```

Barras horizontais combinam com nomes longos, porque os nomes se leem numa linha em vez de inclinados
embaixo de uma barra:

```python
fig, ax = plt.subplots(figsize=(6, 6))
ax.barh(per_station.index, per_station.to_numpy())
ax.set_title("Trips by start station, 2025")
fig.savefig("stations.png")
```

Abra o `stations.png` pelo navegador de arquivos do JupyterLab, e os nomes à esquerda dizem
`do Derby`, `da Aurora`, `ruzilhada`: a figura tem seis polegadas de largura, os eixos ocupam uma
fração fixa dela, e os nomes que não cabem na margem à esquerda dos eixos são desenhados fora da
imagem. A própria figura sabe dizer isso. O `get_tightbbox` mede tudo o que foi desenhado, em
polegadas a partir do canto inferior esquerdo da figura:

```python
box = fig.get_tightbbox()
round(box.x0, 2), round(box.x1, 2)
```

```
(np.float64(-0.87), np.float64(5.4))
```

O desenho começa à esquerda do zero, fora das seis polegadas que o arquivo guarda. Embaixo da célula os
nomes pareciam inteiros, porque o notebook mostra cada gráfico salvo com `bbox_inches="tight"`, o
padrão dele para gráficos numa célula, e é exatamente esse padrão que esconde o problema até o arquivo
ser aberto em outro lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas versões do gráfico de estações. À esquerda: o arquivo salvo, cuja borda corta os nomes longos, que ficam do Derby, da Aurora e spinheiro. À direita: o mesmo gráfico com layout constrained, os eixos movidos para a direita dentro da figura e todos os nomes inteiros.\" data-fig=\"clipped\"><rect x=\"20\" y=\"40\" width=\"320\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">stations.png, como salvo</text><line x1=\"82\" y1=\"60\" x2=\"82\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"82\" y=\"70\" width=\"238.0\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">do Derby</text><rect x=\"82\" y=\"106\" width=\"156.29850746268656\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">da Aurora</text><rect x=\"82\" y=\"142\" width=\"151.02744342802117\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">spinheiro</text><rect x=\"82\" y=\"178\" width=\"148.79297063071738\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"78\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Madalena</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">layout=&quot;constrained&quot;</text><line x1=\"520\" y1=\"60\" x2=\"520\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><rect x=\"520\" y=\"70\" width=\"160.0\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Praça do Derby</text><rect x=\"520\" y=\"106\" width=\"105.07462686567165\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Rua da Aurora</text><rect x=\"520\" y=\"142\" width=\"101.53105440539238\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Espinheiro</text><rect x=\"520\" y=\"178\" width=\"100.02888781896968\" height=\"24\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"516\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Madalena</text><text x=\"30\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os nomes começam fora da imagem</text></svg>", "caption": "As quatro estações mais movimentadas do gráfico, como o arquivo foi salvo e como deveria ser."}
```

## Duas correções

`bbox_inches="tight"` ao salvar mede o que foi desenhado e aumenta a imagem salva para caber:

```python
fig.savefig("stations.png", bbox_inches="tight")
```

A outra correção é no começo: `layout="constrained"` pede ao matplotlib que encaixe os eixos dentro da
figura **em volta** dos rótulos, então a figura fica certa na tela e em todo arquivo:

```python
fig, ax = plt.subplots(figsize=(6, 6), layout="constrained")
ax.barh(per_station.index, per_station.to_numpy())
ax.set_title("Trips by start station, 2025")
fig.savefig("stations.png")
```

A segunda é o hábito melhor. Um gráfico bem disposto não depende de como é salvo, e o `constrained`
também impede que os títulos de vários eixos numa figura se atropelem, do que a próxima seção precisa.
**Abra o arquivo que você salvou**, não só o notebook, antes de mandá-lo.

O gráfico faz um ponto de relance: `Praça do Derby`, a `S05`, está muito à frente de todas as outras
estações, e as três seguintes estão próximas. Ordenar pelo valor, o `sort_values()` acima, é o que
torna isso visível; em ordem alfabética as mesmas barras seriam uma lista para procurar.
