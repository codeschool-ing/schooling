---
title: Lendo um diff
version: 1
---

Um diff é como o Git responde *o que mudou*. A aula 1 disse que um commit guarda uma fotografia e não
uma lista de mudanças; **um diff é calculado quando você pede, comparando duas fotografias**, e a
única coisa a decidir é quais duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"Quatro caixas em fila: um commit mais antigo, o último commit, a área de preparo e o diretório de trabalho. Embaixo, três chaves mostram o que cada diff compara: git diff compara a área de preparo com o diretório de trabalho, git diff --staged compara o último commit com a área de preparo, e git diff com dois commits compara dois commits quaisquer.\"><defs><marker id=\"df-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"97.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um commit mais antigo</text><text x=\"97.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HEAD~3</text><rect x=\"195\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o último commit</text><text x=\"272.5\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HEAD</text><rect x=\"370\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">área de preparo</text><rect x=\"545\" y=\"30\" width=\"155\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">diretório de trabalho</text><path d=\"M447 92 L447 112 L622 112 L622 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff</text><path d=\"M272 92 L272 150 L447 150 L447 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"359.5\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff --staged</text><path d=\"M97 92 L97 188 L272 188 L272 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"184.5\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">git diff HEAD~3 HEAD</text></svg>", "caption": "Todo diff compara exatamente duas fotografias. Quais duas é decidido pelo que você digita depois de git diff."}
```

## Uma mudança, linha por linha

Aqui o preço do pão de queijo foi editado e ainda não foi preparado, então o `git diff` puro o
mostra:

```
ana@vm:~/site$ git diff
diff --git a/menu.html b/menu.html
index ee9e6e3..28fc426 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
 <p>French bread, 0.90</p>
-<p>Cheese roll, 2.50</p>
+<p>Cheese roll, 2.80</p>
```

As quatro primeiras linhas são um cabeçalho. `diff --git a/menu.html b/menu.html` nomeia o arquivo
dos dois lados: `a` é o lado antigo e `b` o novo. A linha `index` dá os ids de blob das duas
versões, os mesmos ids que a aula 1 encontrou numa árvore. `---` e `+++` repetem qual lado é qual.

Depois vem a parte que importa, o **hunk**. `@@ -1,3 +1,3 @@` quer dizer *a partir da linha 1, três
linhas, no arquivo antigo; a partir da linha 1, três linhas, no novo*. Embaixo, toda linha começa com
um de três caracteres:

- um espaço é **contexto**, sem mudança, mostrado para você saber onde está;
- `-` é uma linha que só existe no lado antigo;
- `+` é uma linha que só existe no lado novo.

**Diffs não têm ideia de "mudou".** Uma linha mudada aparece como a antiga removida e a nova
acrescentada, `-…2.50` e `+…2.80`. Um arquivo comprido mudado em três lugares dá três hunks, cada um
com algumas linhas de contexto em volta.

## Entre dois commits

Nomeie dois commits e o Git compara essas fotografias. Acrescentar `-- menu.html` limita a um
arquivo:

```
ana@vm:~/site$ git diff HEAD~3 HEAD -- menu.html
diff --git a/menu.html b/menu.html
index ca66507..ee9e6e3 100644
--- a/menu.html
+++ b/menu.html
@@ -1,3 +1,3 @@
 <h1>Menu</h1>
 <p>French bread, 0.90</p>
-<p>Rye bread, 1.35</p>
+<p>Cheese roll, 2.50</p>
```

Repare no que ele diz e no que não diz. Três commits separam o `HEAD~3` do `HEAD`: o pão de centeio
removido, o pão de queijo acrescentado, um link na página inicial. **O diff mostra a diferença entre
as duas pontas, não os passos entre elas.** O centeio saiu e o queijo entrou, e o diff mostra
exatamente isso, sem sinal de que foram commits separados, de pessoas diferentes, em dias
diferentes. Quando você quer os passos, você quer o log.

O `--stat` dá a mesma comparação como resumo, o que muitas vezes basta para saber se vale olhar mais
de perto:

```
ana@vm:~/site$ git diff --stat HEAD~3 HEAD
 index.html | 1 +
 menu.html  | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
```
