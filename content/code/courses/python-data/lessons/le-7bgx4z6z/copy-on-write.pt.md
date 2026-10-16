---
title: Copy-on-Write, a resposta do pandas 3
version: 1
---

**No pandas 3, toda seleção se comporta como uma cópia do que selecionou, e mudá-la nunca muda a
tabela de onde veio.** A biblioteca chama isso de Copy-on-Write: a cópia só é feita de verdade quando
um dos lados é escrito, então selecionar continua barato, mas o resultado é o mesmo que se ela tivesse
sido feita.

Pegue as viagens de passe diário como uma tabela própria e acrescente uma coluna a ela:

```python
day = trips[trips["plan"] == "day"]
day["note"] = "day pass"
"note" in day.columns, "note" in trips.columns
```

```
(True, False)
```

`day` tem a coluna nova e `trips` não. É o que quase todo mundo espera, e o pandas 3 faz isso sem
aviso. Mudar um valor numa Series selecionada é igual:

```python
plan = trips["plan"]
plan.iloc[0] = "changed"
plan.iloc[0], trips.loc[0, "plan"]
```

```
('changed', 'day')
```

`plan` mudou; a tabela, não. A Series não é mais uma janela para a coluna da tabela.

## Atribuição encadeada nunca funciona

O único padrão que quebra são duas seleções seguidas com uma atribuição no fim, a versão pandas da
escrita que some da aula 7:

```python
trips["bike"][trips["bike"] == "electric"] = "e-bike"
(trips["bike"] == "e-bike").sum()
```

```
/tmp/ipykernel_2374/3907501872.py:1: ChainedAssignmentError: A value is being set on a copy of a DataFrame or Series through chained assignment.
Such chained assignment never works to update the original DataFrame or Series, because the intermediate object on which we are setting values always behaves as a copy (due to Copy-on-Write).

Try using '.loc[row_indexer, col_indexer] = value' instead, to perform the assignment in a single step.

See the documentation for a more detailed explanation: https://pandas.pydata.org/pandas-docs/stable/user_guide/copy_on_write.html#chained-assignment
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
np.int64(0)
```

`trips["bike"]` é selecionado primeiro, como objeto próprio; a máscara e a atribuição agem então
sobre esse objeto, que é jogado fora. **Nada em `trips` mudou, e o pandas 3 diz isso**, com um aviso
`ChainedAssignmentError` que aponta a linha e a correção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Em cima: trips[&quot;bike&quot;][mask] = &quot;e-bike&quot;. Os primeiros colchetes criam um objeto separado a partir da coluna bike; a atribuição cai nesse objeto, que é jogado fora, e trips não muda. Embaixo: trips.loc[mask, &quot;bike&quot;] = &quot;e-bike&quot;. Um passo, e a atribuição cai em trips.\" data-fig=\"chained\"><defs><marker id=\"chained-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">trips[&quot;bike&quot;][mask] = &quot;e-bike&quot;</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"95.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não muda</text><rect x=\"285\" y=\"40\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips[&quot;bike&quot;]</text><text x=\"370.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um objeto separado</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">= &quot;e-bike&quot;</text><text x=\"630.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cai aqui, e se perde</text><line x1=\"174\" y1=\"70\" x2=\"281\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line><line x1=\"459\" y1=\"70\" x2=\"556\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">trips.loc[mask, &quot;bike&quot;] = &quot;e-bike&quot;</text><rect x=\"20\" y=\"158\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"95.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">muda no lugar</text><rect x=\"285\" y=\"158\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">um passo</text><text x=\"370.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas e coluna juntas</text><line x1=\"281\" y1=\"188\" x2=\"174\" y2=\"188\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#chained-ah)\"></line></svg>", "caption": "Duas seleções e depois uma atribuição escrevem no objeto do meio. Um loc escreve na tabela."}
```

A correção é a forma de um passo:

```python
trips.loc[trips["bike"] == "electric", "bike"] = "e-bike"
(trips["bike"] == "e-bike").sum()
```

```
np.int64(11655)
```

## O que isso substituiu

Antes do pandas 3, se uma seleção era view ou cópia dependia de como ela era feita, mais ou menos como
no NumPy, e as regras eram intrincadas demais para lembrar. Escrever numa seleção às vezes mudava o
original e às vezes não, e o pandas nem sempre sabia dizer qual, então avisava sempre que pudesse ser
qualquer um dos dois: o `SettingWithCopyWarning`. A próxima seção mostra esse aviso e esse
comportamento, porque o código que você vai ler foi escrito para eles.
