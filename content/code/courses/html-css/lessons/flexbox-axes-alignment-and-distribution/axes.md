---
title: Everything depends on the main axis
---

Flexbox arranges the children along **one** axis. `flex-direction` picks which:

```css
.bar {
  display: flex;
  flex-direction: row;   /* default: main axis horizontal */
}
```

Understanding that settles the confusion that slows learners down most: `justify-content` acts on the **main axis** and `align-items` on the **cross** one. Since the default is `row`, `justify-content` looks "horizontal" and `align-items` looks "vertical" — until somebody writes `flex-direction: column`, and the two swap meaning.

The right question is never "how do I centre horizontally?", it is "what is my main axis?".

```schooling-figure
{
  "svg": "<svg viewBox=\"0 0 760 226\" role=\"img\" aria-label=\"With flex-direction row the main axis is horizontal and the cross axis vertical; with column the two swap places\"><g font-family=\"IBM Plex Mono, monospace\" font-size=\"11\" fill=\"currentColor\" opacity=\".65\"><text x=\"30\" y=\"18\">flex-direction: row</text><text x=\"430\" y=\"18\">flex-direction: column</text></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".4\"><rect x=\"30\" y=\"30\" width=\"300\" height=\"140\" rx=\"4\"/><rect x=\"430\" y=\"30\" width=\"300\" height=\"140\" rx=\"4\"/></g><g fill=\"currentColor\" opacity=\".2\"><rect x=\"48\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"118\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"188\" y=\"44\" width=\"62\" height=\"76\" rx=\"3\"/><rect x=\"450\" y=\"42\" width=\"180\" height=\"30\" rx=\"3\"/><rect x=\"450\" y=\"78\" width=\"180\" height=\"30\" rx=\"3\"/><rect x=\"450\" y=\"114\" width=\"180\" height=\"30\" rx=\"3\"/></g><g fill=\"none\" stroke-width=\"1.8\" style=\"stroke:var(--phosphor)\"><path d=\"M44 150h268\" marker-end=\"url(#ep)\"/><path d=\"M690 42v112\" marker-end=\"url(#ep)\"/></g><g fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".45\" stroke-dasharray=\"4 4\"><path d=\"M282 40v82\" marker-end=\"url(#ec)\"/><path d=\"M450 158h190\" marker-end=\"url(#ec)\"/></g><g font-family=\"IBM Plex Mono, monospace\" font-size=\"11\"><path d=\"M30 194h26\" fill=\"none\" stroke-width=\"1.8\" style=\"stroke:var(--phosphor)\"/><text x=\"64\" y=\"198\" style=\"fill:var(--phosphor)\">main axis → justify-content</text><path d=\"M30 214h26\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.2\" opacity=\".45\" stroke-dasharray=\"4 4\"/><text x=\"64\" y=\"218\" fill=\"currentColor\" opacity=\".6\">cross axis → align-items</text></g><defs><marker id=\"ep\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"5.5\" markerHeight=\"5.5\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" style=\"fill:var(--phosphor)\"/></marker><marker id=\"ec\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"5\" markerHeight=\"5\" orient=\"auto\"><path d=\"M0 0l8 4-8 4z\" fill=\"currentColor\" opacity=\".45\"/></marker></defs></svg>",
  "caption": "Swapping `row` for `column` does not just move the items: it **swaps** the two alignment properties around. That is why the one that used to work \"stopped working\"."
}
```
