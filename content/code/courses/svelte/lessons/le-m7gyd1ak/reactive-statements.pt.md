---
title: O que o `$:` errava
version: 1
---

**Uma instrução `$:` do Svelte 4 roda de novo quando um nome escrito dentro dela muda, e o compilador
decide quais são esses nomes lendo a instrução, uma vez, na hora do build.** Essa é a regra inteira, e
é a origem do bug que fez a equipe do Svelte substituí-la. Um valor lido em qualquer outro lugar,
dentro de uma função que a instrução chama, por exemplo, fica invisível para ela.

Para ver isso, leve o rótulo do `WeekNav` para dentro de uma função, o tipo de arrumação que qualquer
pessoa faria:

```schooling-example
{"language": "html", "file": "src/lib/WeekNav.svelte", "parts": [
 {"code": "<svelte:options runes={false} />\n\n<script>\n\timport { createEventDispatcher } from 'svelte';\n\timport { addDays, format } from '#lib/week.js';\n\n\texport let week;\n\texport let label = 'Week of';\n\n\tconst dispatch = createEventDispatcher();"},
 {"code": "\tfunction describe() {\n\t\treturn `${label} ${format(week)}`;\n\t}\n\n\t$: shown = describe();\n\n\tfunction move(days) {\n\t\tweek = addDays(week, days);\n\t\tdispatch('change', { week });\n\t}\n</script>\n\n<p>\n\t<button on:click={() => move(-7)}>Previous week</button>\n\t{shown}\n\t<button on:click={() => move(7)}>Next week</button>\n</p>", "note": "Agora o texto é montado por uma função. A instrução `$:` contém um nome, `describe`, que nunca muda."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Next week' --click 'Next week'
-- click Next week
-- click Next week
at /
title: 0 min this week · Study planner
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 2 Nov 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 0 min
    - listitem:
      - button "Spanish"
      - text: 0 min
    - listitem:
      - button "Guitar"
      - text: 0 min
  - paragraph: 0 minutes this week (0 h 0 min)
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min"
  - paragraph: 0 minutes for Linear algebra this week (0 h 0 min)
  - button "Add 30 minutes on 2 Nov 2026"
```

Dois cliques para a frente. **A semana mudou**: o total da página caiu para 0 porque não há sessões
planejadas para o dia 2 de novembro, que é o que a página recebeu pelo `on:change`. **O rótulo não
mudou**: ainda diz 19 de outubro. O compilador olhou `$: shown = describe();`, achou o nome
`describe`, viu que nada nunca atribui a `describe`, e concluiu que a instrução nunca precisa rodar de
novo. Ele estava errado, e nada avisou ninguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois jeitos de descobrir de que uma instrução depende. Em cima, o Svelte 4: o compilador lê o texto de $: shown = describe(), acha um nome, describe, que nunca muda, e conclui que a instrução nunca precisa rodar de novo; as leituras de label e week dentro da função ficam invisíveis para ele. Embaixo, o Svelte 5: $derived(describe()) roda, e enquanto roda a função lê label e week, então os dois signals o registram como leitor.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Svelte 4: decidido uma vez, no build, a partir do texto</text><rect x=\"20\" y=\"36\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$: shown = describe();</text><line x1=\"250\" y1=\"56\" x2=\"318\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,56.0 310.6,59.1 310.6,52.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"320\" y=\"36\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nomes que contém:</text><text x=\"405\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><line x1=\"490\" y1=\"56\" x2=\"538\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,56.0 530.6,59.1 530.6,52.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"540\" y=\"36\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nunca roda de novo</text><rect x=\"320\" y=\"88\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">label, week: não vistos</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Svelte 5: registrado enquanto roda</text><rect x=\"20\" y=\"164\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$derived(describe())</text><line x1=\"250\" y1=\"184\" x2=\"318\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,184.0 310.6,187.1 310.6,180.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"320\" y=\"164\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leituras ao rodar:</text><text x=\"405\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">label, week</text><line x1=\"490\" y1=\"184\" x2=\"538\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"538.0,184.0 530.6,187.1 530.6,180.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"540\" y=\"164\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">roda de novo se um mudar</text><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mesma função, mesmo texto: só o segundo enxerga dentro dela</text></svg>", "caption": "O $: sabia como a linha parecia; uma rune sabe o que ela fez."}
```

## A mesma função, sob uma rune

A versão em runes daquela linha é `let shown = $derived(describe());`, e ela funciona, pelo motivo que
a aula 2 desenhou: um valor derivado registra o que leu **enquanto roda**, e `describe` leu `label` e
`week` quando rodou. As leituras dentro da função contam tanto quanto leituras escritas na expressão.
**Runes rastreiam o que o código faz; o `$:` rastreava como o código parecia.**

Essa única diferença é quase todo o motivo de o Svelte 5 existir. O `$:` era conciso, e estava certo
para as instruções que as pessoas escreviam em tutoriais. Estava errado para as instruções que as
pessoas escreviam um ano depois de começar um projeto, depois das refatorações óbvias, e estava errado
em silêncio. Volte o `WeekNav.svelte` para a versão da seção anterior antes da próxima.
