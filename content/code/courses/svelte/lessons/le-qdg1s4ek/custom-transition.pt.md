---
title: Escrevendo uma transição
version: 1
---

**Uma transição é uma função**, e escrever uma leva algumas linhas. Ela recebe o elemento e os
parâmetros, e devolve quanto tempo a animação dura e uma função `css`. O Svelte chama `css` com `t`, que
vai de 0 a 1 ao longo de uma entrada, e transforma as respostas em keyframes que o navegador toca. Como
a animação é CSS, ela roda fora da thread principal e continua suave enquanto o JavaScript está ocupado.

O planner pode usar uma para chamar a atenção para um total que acabou de mudar: um destaque atrás dele,
que vai sumindo. Salve como `src/lib/flash.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/flash.js", "parts": [
 {"code": "// flash.js: a highlight behind an element, fading out as it arrives.\nexport function flash(node, { duration = 600 } = {}) {\n\treturn {\n\t\tduration,", "note": "Uma função de transição: o elemento, depois os parâmetros, com uma duração padrão."},
 {"code": "\t\tcss: (t) => `background-color: rgb(255 215 0 / ${(1 - t) * 0.6})`\n\t};\n}", "note": "`t` vai de 0 a 1 ao longo da entrada, então `1 - t` começa cheio e termina em nada: um destaque que some."}
]}
```

Uma transição toca quando um elemento é criado, e o parágrafo do total é criado uma vez. O bloco que
cria um elemento de novo sempre que um valor muda é o `{#key}` da aula 8, então o `WeekTotal` envolve o
seu parágrafo num, com os minutos como chave:

```schooling-example
{"language": "html", "file": "src/lib/WeekTotal.svelte", "parts": [
 {"code": "<script>\n\timport { flash } from '#lib/flash.js';\n\n\tlet { minutes, label = 'this week' } = $props();\n\n\tlet hours = $derived(Math.floor(minutes / 60));\n\tlet rest = $derived(minutes % 60);\n</script>"},
 {"code": "{#key minutes}\n\t<p in:flash>{minutes} minutes {label} ({hours} h {rest} min)</p>\n{/key}", "note": "Cada `minutes` novo destrói o parágrafo e o cria de novo, e o novo toca `in:flash`."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter
-- fill Date=2026-10-21
-- press Enter
at /
title: 255 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph: Left and right arrows move the week.
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week (4 h 15 min)
  - paragraph: 90 of 255 minutes done.
  - list "Minutes per day":
    - listitem: "19 Oct 2026: 90 min"
    - listitem: "20 Oct 2026: 45 min"
    - listitem: "21 Oct 2026: 30 min"
    - listitem: "22 Oct 2026: 30 min"
    - listitem: "23 Oct 2026: 0 min"
    - listitem: "24 Oct 2026: 60 min"
    - listitem: "25 Oct 2026: 0 min"
  - region "Linear algebra":
    - heading "Linear algebra" [level=2]
    - list:
      - listitem:
        - checkbox "19 Oct 2026, 90 min" [checked]
        - text: 19 Oct 2026, 90 min
      - listitem:
        - checkbox "21 Oct 2026, 30 min"
        - text: 21 Oct 2026, 30 min
      - listitem:
        - checkbox "24 Oct 2026, 60 min"
        - text: 24 Oct 2026, 60 min
    - paragraph: 180 minutes for Linear algebra this week (3 h 0 min)
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
```

Os dois totais que mudaram, o da semana e o de Linear algebra, são os que piscaram; a árvore não
consegue mostrar uma cor, então veja isso no seu próprio navegador. O que a árvore mostra é que nada mais
mudou: um `{#key}` em volta de um parágrafo substitui um parágrafo.

## Easing

`css` recebe `t` **depois** de a função de easing ter sido aplicada, então a mesma transição pode
parecer mecânica ou natural dependendo de um parâmetro. `svelte/easing` exporta as curvas padrão, e a
maioria das transições prontas, `slide` e `fly` entre elas, usa `cubicOut` como padrão, que começa
rápido e desacelera até o lugar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três curvas de easing, desenhadas como progresso contra tempo, de 0 a 1. linear é uma diagonal reta. cubicOut sobe rápido no começo e se achata ao chegar a 1, chegando suave. cubicIn começa plano e sobe rápido no fim, saindo de repente.\"><rect x=\"40\" y=\"30\" width=\"180\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40.0 210.0 L44.5 205.5 L49.0 201.0 L53.5 196.5 L58.0 192.0 L62.5 187.5 L67.0 183.0 L71.5 178.5 L76.0 174.0 L80.5 169.5 L85.0 165.0 L89.5 160.5 L94.0 156.0 L98.5 151.5 L103.0 147.0 L107.5 142.5 L112.0 138.0 L116.5 133.5 L121.0 129.0 L125.5 124.5 L130.0 120.0 L134.5 115.5 L139.0 111.0 L143.5 106.5 L148.0 102.0 L152.5 97.5 L157.0 93.0 L161.5 88.5 L166.0 84.0 L170.5 79.5 L175.0 75.0 L179.5 70.5 L184.0 66.0 L188.5 61.5 L193.0 57.0 L197.5 52.5 L202.0 48.0 L206.5 43.5 L211.0 39.0 L215.5 34.5 L220.0 30.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"></path><text x=\"130.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">linear</text><text x=\"32\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"32\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"265\" y=\"30\" width=\"180\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M265.0 210.0 L269.5 196.8 L274.0 184.3 L278.5 172.5 L283.0 161.2 L287.5 150.6 L292.0 140.5 L296.5 131.1 L301.0 122.2 L305.5 113.8 L310.0 105.9 L314.5 98.6 L319.0 91.7 L323.5 85.4 L328.0 79.4 L332.5 73.9 L337.0 68.9 L341.5 64.2 L346.0 59.9 L350.5 56.0 L355.0 52.5 L359.5 49.3 L364.0 46.4 L368.5 43.8 L373.0 41.5 L377.5 39.5 L382.0 37.7 L386.5 36.2 L391.0 34.9 L395.5 33.7 L400.0 32.8 L404.5 32.1 L409.0 31.4 L413.5 31.0 L418.0 30.6 L422.5 30.4 L427.0 30.2 L431.5 30.1 L436.0 30.0 L440.5 30.0 L445.0 30.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"355.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">cubicOut</text><text x=\"257\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"257\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"490\" y=\"30\" width=\"180\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M490.0 210.0 L494.5 210.0 L499.0 210.0 L503.5 209.9 L508.0 209.8 L512.5 209.6 L517.0 209.4 L521.5 209.0 L526.0 208.6 L530.5 207.9 L535.0 207.2 L539.5 206.3 L544.0 205.1 L548.5 203.8 L553.0 202.3 L557.5 200.5 L562.0 198.5 L566.5 196.2 L571.0 193.6 L575.5 190.7 L580.0 187.5 L584.5 184.0 L589.0 180.1 L593.5 175.8 L598.0 171.1 L602.5 166.1 L607.0 160.6 L611.5 154.6 L616.0 148.3 L620.5 141.4 L625.0 134.1 L629.5 126.2 L634.0 117.8 L638.5 108.9 L643.0 99.5 L647.5 89.4 L652.0 78.8 L656.5 67.5 L661.0 55.7 L665.5 43.2 L670.0 30.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"580.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">cubicIn</text><text x=\"482\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"482\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na horizontal: tempo; na vertical: quanto a animação avançou</text></svg>", "caption": "A mesma duração, três jeitos de gastá-la."}
```

Uma curva que termina suave parece algo chegando, o que é certo para um elemento que entra. Uma que
começa suave e termina de repente, como `cubicIn`, combina com um elemento que sai. `linear` é a linha
reta honesta, e quase sempre parece errada para movimento, porque nada no mundo físico se move assim.
