---
title: O que roda de novo quando algo muda
version: 1
---

**Os quatro cartões desenham a mesma página e a atualizam de dois jeitos diferentes.** As linhas de
`console.log` disseram qual:

| | o código do componente rodou | depois, para uma marcação |
| --- | --- | --- |
| Angular | uma vez, o construtor | o signal, os dois `computed` dele, e os bindings que os leem |
| React | uma vez por desenho | a função inteira, de novo; o React compara o que ela devolveu com a vez anterior |
| Vue | uma vez, o setup | o `ref`, os dois `computed` dele, e as partes do template que os leem |
| Svelte | uma vez, o script | o `$state`, os dois `$derived` dele, e o código que o compilador escreveu para o parágrafo |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois diagramas lado a lado. À esquerda, leituras rastreadas, como fazem Angular, Vue e Svelte: uma marcação muda o estado, uma seta vai aos dois valores derivados que o leem, e deles ao único parágrafo que os lê; o título e o resto ficam intocados. À direita, o React: uma marcação muda o estado, a função inteira do componente roda de novo, o resultado é comparado com o anterior, e a diferença é escrita na página.\"><text x=\"175\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Angular, Vue, Svelte: leituras rastreadas</text><text x=\"545\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">React: rodar de novo, comparar</text><line x1=\"360\" y1=\"14\" x2=\"360\" y2=\"236\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><rect x=\"115\" y=\"44\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estado</text><rect x=\"40\" y=\"110\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planned</text><rect x=\"190\" y=\"110\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done</text><line x1=\"160\" y1=\"80\" x2=\"110\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"110.0,106.0 115.1,99.8 118.0,105.4\" fill=\"var(--wire)\"></polygon><line x1=\"190\" y1=\"80\" x2=\"240\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"240.0,106.0 232.0,105.4 234.9,99.8\" fill=\"var(--wire)\"></polygon><rect x=\"100\" y=\"176\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o parágrafo</text><line x1=\"100\" y1=\"146\" x2=\"150\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,172.0 142.0,171.4 144.9,165.8\" fill=\"var(--wire)\"></polygon><line x1=\"250\" y1=\"146\" x2=\"200\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"200.0,172.0 205.1,165.8 208.0,171.4\" fill=\"var(--wire)\"></polygon><text x=\"175\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o título não é tocado</text><rect x=\"430\" y=\"44\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estado</text><rect x=\"430\" y=\"98\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a função inteira roda</text><rect x=\"430\" y=\"152\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">comparada com o resultado anterior</text><rect x=\"430\" y=\"206\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a diferença é escrita</text><line x1=\"545\" y1=\"74\" x2=\"545\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,96.0 541.9,88.6 548.1,88.6\" fill=\"var(--wire)\"></polygon><line x1=\"545\" y1=\"128\" x2=\"545\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,150.0 541.9,142.6 548.1,142.6\" fill=\"var(--wire)\"></polygon><line x1=\"545\" y1=\"182\" x2=\"545\" y2=\"204\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,204.0 541.9,196.6 548.1,196.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "A mesma marcação, dois jeitos de achar o que mudou: seguir quem leu o valor, ou rodar o componente de novo e comparar."}
```

**Três dos quatro rastreiam leituras.** Um signal no Angular, um ref no Vue e uma rune no Svelte
sabem quem os leu, então uma mudança chega exatamente a esses leitores e a mais nada. Isso é a aula 6
e a aula 7 deste curso, e é a mesma ideia com três nomes: o Vue a tem desde o começo, o Svelte tem
runes desde a versão 5, e o Angular passou a ela com os signals, que é o motivo de o planner poder
largar o zone.js.

**O React roda de novo e compara.** Uma mudança de estado roda de novo a função do componente,
inteira, e o React compara o resultado novo com o antigo para achar o que mudar na página. Nada é
rastreado; tudo é recalculado, e a comparação mantém a página barata de atualizar. Os totais no
cartão em React são aritmética simples na função, refeita a cada desenho. Num componente maior, o
React oferece o `useMemo` para guardar um valor até aquilo de que ele depende mudar; o curso
`react-ts` o ensina na aula 7, e a aula 3 dele é toda esta pergunta, o que de fato é redesenhado.

Nenhum dos dois jeitos está errado, e a diferença aparece no que você precisa pensar. No Angular, no
Vue e no Svelte, a pergunta é **o que lê o quê**: um valor lido fora de um contexto reativo, ou um
`computed` que lê algo que não deveria, se comporta de um jeito surpreendente. No React a pergunta é
**o que roda de novo**: um objeto criado dentro da função é um objeto novo a cada desenho, e um
componente que passa um para um filho faz o filho desenhar de novo também.

## As mesmas ideias, quatro grafias

| ideia | Angular | React | Vue | Svelte |
| --- | --- | --- | --- | --- |
| estado | `signal()` | `useState()` | `ref()` | `$state()` |
| derivado | `computed()` | um `const`, ou `useMemo()` | `computed()` | `$derived()` |
| efeito colateral | `effect()` | `useEffect()` | `watch()`, `watchEffect()` | `$effect()` |
| laço no template | `@for` com `track` | `map()` com `key` | `v-for` com `:key` | `{#each}` com uma chave |
| condição | `@if` | `&&` ou `? :` | `v-if` | `{#if}` |
| uma entrada vinda do pai | `input()` | uma propriedade de `props` | `defineProps()` | `$props()` |
| um valor de volta ao pai | `output()` | uma função passada como prop | `defineEmits()` | uma função passada como prop |
| binding nos dois sentidos com um campo | `[(ngModel)]`, `[formField]` | `value` e `onChange` | `v-model` | `bind:value` |

Quem fez este curso já lê a maior parte do código dos outros três. O que muda é a grafia, e no React,
o modelo do que roda.
