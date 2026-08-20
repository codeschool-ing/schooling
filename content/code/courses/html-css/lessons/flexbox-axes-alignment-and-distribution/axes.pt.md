---
title: Tudo depende do eixo principal
---

Flexbox organiza os filhos ao longo de **um** eixo. `flex-direction` escolhe qual:

```css
.barra {
  display: flex;
  flex-direction: row;   /* padrão: eixo principal na horizontal */
}
```

Entender isso resolve a confusão que mais atrasa quem está aprendendo: `justify-content` age no **eixo principal** e `align-items` no **cruzado**. Como o padrão é `row`, `justify-content` parece "horizontal" e `align-items` parece "vertical" — até alguém escrever `flex-direction: column`, e os dois trocarem de sentido.

A pergunta certa nunca é "como centralizo na horizontal?", e sim "qual é o meu eixo principal?".

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 760 226\" role=\"img\" aria-label=\"Com flex-direction row o eixo principal é horizontal e o cruzado é vertical; com column os dois trocam de lugar\"><g font-family=\"IBM Plex Mono, monospace\" font-size=\"11\" fill=\"currentColor\" opacity=\".65\"><text x=\"30\" y=\"18\">flex-direction: row</text><text x=\"430\" y=\"18\">flex-direction: column</text></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".4\"><rect x=\"30\" y=\"30\" width=\"300\" height=\"140\" rx=\"4\"/><rect x=\"430\" y=\"30\" width=\"300\" height=\"140\" rx=\"4\"/></g><g fill=\"currentColor\" opacity=\".2\"><rect x=\"48\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"118\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"188\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"450\" y=\"42\" width=\"180\" height=\"30\" rx=\"3\"/><rect x=\"450\" y=\"78\" width=\"180\" height=\"30\" rx=\"3\"/><rect x=\"450\" y=\"114\" width=\"180\" height=\"30\" rx=\"3\"/></g><g fill=\"none\" stroke-width=\"1.8\" style=\"stroke:var(--phosphor)\"><path d=\"M44 150h268\" marker-end=\"url(#ep)\"/><path d=\"M690 42v112\" marker-end=\"url(#ep)\"/></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".45\" stroke-dasharray=\"4 4\"><path d=\"M282 40v82\" marker-end=\"url(#ec)\"/><path d=\"M450 158h190\" marker-end=\"url(#ec)\"/></g><g font-family=\"IBM Plex Mono, monospace\" font-size=\"11\"><path d=\"M30 194h26\" fill=\"none\" stroke-width=\"1.8\" style=\"stroke:var(--phosphor)\"/><text x=\"64\" y=\"198\" style=\"fill:var(--phosphor)\">eixo principal → justify-content</text><path d=\"M30 214h26\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".45\" stroke-dasharray=\"4 4\"/><text x=\"64\" y=\"218\" fill=\"currentColor\" opacity=\".6\">eixo cruzado → align-items</text></g><defs><marker id=\"ep\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"5.5\" markerHeight=\"5.5\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" style=\"fill:var(--phosphor)\"/></marker><marker id=\"ec\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"5\" markerHeight=\"5\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" fill=\"currentColor\" opacity=\".45\"/></marker></defs></svg>",
  "caption": "Trocar `row` por `column` não move só os itens: **troca de lugar** as duas propriedades de alinhamento. É por isso que a que funcionava \"parou de funcionar\"."
}
```
