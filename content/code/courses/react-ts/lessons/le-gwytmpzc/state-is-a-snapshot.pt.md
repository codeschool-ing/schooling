---
title: O estado é um retrato
version: 1
---

**O `useState` dá a um componente um valor que o React guarda entre renderizações, e uma função que
pede um valor diferente da próxima vez.** É essa segunda metade que as pessoas entendem errado.
Chamar o setter não muda a variável que você tem nas mãos; ele agenda uma nova renderização, e o
valor novo chega nessa renderização. A aula 3 usou o `setMonday` como gatilho. Esta seção olha o que
ele faz de fato.

```tsx
const [monday, setMonday] = useState(() => mondayOf(today()))
```

Três coisas estão empacotadas nessa linha:

- **O valor inicial**, usado só na primeira renderização. Aqui ele é uma função,
  `() => mondayOf(today())`, que o React chama uma vez; passar `mondayOf(today())` direto também
  funcionaria, e calcularia a data em toda renderização só para jogá-la fora.
- **`monday`**, o valor desta renderização. É uma constante comum, e nada consegue mudá-la enquanto o
  código desta renderização roda.
- **`setMonday`**, que diz ao React: da próxima vez que renderizar este componente, `monday` é isto.

## Um clique, duas chamadas

Um componente descartável deixa a diferença visível. Ele chama o setter duas vezes num clique, como
faz um código que tenta andar duas semanas andando uma semana duas vezes, e registra `monday` depois.
Salve como `src/TwoWeeks.tsx`; ele é só para esta aula:

```tsx
import type { Dispatch, SetStateAction } from 'react'
import { addDays } from './week'

type TwoWeeksProps = {
  monday: string
  setMonday: Dispatch<SetStateAction<string>>
}

// For lesson 4 only: one click, two calls to the setter.
export function TwoWeeks({ monday, setMonday }: TwoWeeksProps) {
  function jump() {
    setMonday(addDays(monday, 7))
    setMonday(addDays(monday, 7))
    console.log('after both calls, monday is', monday)
  }
  return (
    <button type="button" onClick={jump}>
      Two weeks on
    </button>
  )
}
```

Ponha-o embaixo do `WeekNav` no `App` e aperte uma vez:

```
ana@dev:~/planner$ sed -i 's|^      <WeekNav .*|&\n      <TwoWeeks monday={monday} setMonday={setMonday} />|; 1a import { TwoWeeks } from "./TwoWeeks"' src/App.tsx
ana@dev:~/planner$ grep -n TwoWeeks src/App.tsx
2:import { TwoWeeks } from "./TwoWeeks"
16:      <TwoWeeks monday={monday} setMonday={setMonday} />
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Two weeks on' | head -n 11
-- click button Two weeks on
after both calls, monday is 2026-10-19
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - button "Two weeks on"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
```

Duas coisas deram errado, e as duas são a mesma coisa. **O registro diz `2026-10-19`**, depois de
duas chamadas que pediram o dia 26: `monday` é a constante desta renderização, e pedir um valor novo
não volta para mudá-la. **E a semana andou uma**, para o 26, não duas. As duas chamadas calcularam
`addDays(monday, 7)` a partir do mesmo retrato, então as duas pediram o 26, e pedir duas vezes o
mesmo valor é pedir uma.

```schooling-figure
{"svg": "<svg data-fig=\"snapshot\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas, um clique cada. Linha de cima, com valores: a renderização tem monday 19 Oct, o handler chama set 26 Oct duas vezes, ambas calculadas do retrato, e a renderização seguinte tem 26 Oct. Linha de baixo, com funções de atualização: a fila roda de 19 para 26, depois de 26 para 2 Nov, e a renderização seguinte tem 2 Nov. Nas duas linhas o monday do próprio handler continua 19 Oct.\"><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">setMonday(valor)</text><rect x=\"20\" y=\"40\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render</text><text x=\"85.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><line x1=\"152\" y1=\"68\" x2=\"188\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,68.0 180.5,71.2 180.5,64.8\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"40\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"202\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">handler do clique, um evento</text><rect x=\"202\" y=\"66\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">set 26 Oct</text><rect x=\"360\" y=\"66\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">set 26 Oct</text><line x1=\"522\" y1=\"68\" x2=\"558\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,68.0 550.5,71.2 550.5,64.8\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"40\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">next render</text><text x=\"630.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">monday = 26 Oct</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">setMonday(função)</text><rect x=\"20\" y=\"150\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render</text><text x=\"85.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><line x1=\"152\" y1=\"178\" x2=\"188\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,178.0 180.5,181.2 180.5,174.8\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"150\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"202\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">handler do clique, um evento</text><rect x=\"202\" y=\"176\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">19 → 26 Oct</text><rect x=\"360\" y=\"176\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">26 Oct → 2 Nov</text><line x1=\"522\" y1=\"178\" x2=\"558\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,178.0 550.5,181.2 550.5,174.8\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"150\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">next render</text><text x=\"630.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">monday = 2 Nov</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o monday do próprio handler é 19 Oct nas duas linhas</text></svg>", "caption": "Um valor pede duas vezes a mesma coisa; uma função recebe o que a anterior devolveu."}
```

O React também não renderizou duas vezes. **Todo setter chamado durante um evento é juntado e
aplicado de uma vez**, e o componente renderiza uma vez depois. Isso se chama batching, e é por isso
que um handler que define três pedaços de estado produz uma renderização, e não três telas
intermediárias.
