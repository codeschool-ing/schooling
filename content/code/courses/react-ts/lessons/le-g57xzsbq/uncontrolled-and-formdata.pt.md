---
title: Deixando o navegador guardar os valores
version: 1
---

**Um input não controlado guarda o próprio valor, no DOM, e o React o lê uma vez, quando o formulário
é enviado.** Sem estado por campo, sem `onChange`, sem renderização a cada tecla. O navegador sempre
soube juntar os valores de um formulário, e o `FormData` é como um handler pede por eles:

```tsx
import type { FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    addSession({ course, date: String(form.get('date')), minutes: Number(form.get('minutes')) })
    event.currentTarget.reset()
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input name="date" type="date" required />
      </label>
      <label>
        Minutes
        <input name="minutes" type="number" defaultValue={30} min={5} max={240} required />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
```

```schooling-figure
{"svg": "<svg data-fig=\"controlled\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Dois caminhos para o valor de um campo. Controlado: o valor mora no estado do React, entra no input pela prop value, e cada tecla chama onChange, que define o estado, que renderiza o input de novo. Não controlado: o valor mora no próprio input do DOM, e o React o lê uma vez, no envio, pelo FormData.\"><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">controlado</text><rect x=\"40\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useState</text><rect x=\"200\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;input&gt;</text><line x1=\"162\" y1=\"52\" x2=\"198\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,52.0 190.5,55.2 190.5,48.8\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">value</text><line x1=\"198\" y1=\"72\" x2=\"162\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"162.0,72.0 169.5,68.8 169.5,75.2\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">onChange</text><text x=\"180\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada tecla renderiza</text><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a tela pode reagir na hora</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">não controlado</text><rect x=\"400\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;input name&gt;</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">onSubmit</text><line x1=\"522\" y1=\"60\" x2=\"558\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,60.0 550.5,63.2 550.5,56.8\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">new FormData(form)</text><text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">digitar não renderiza nada</text><text x=\"540\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o React lê o valor uma vez</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "Controlado: o React guarda o valor. Não controlado: o DOM guarda até o envio."}
```

- **`name` em cada input** é por onde o `FormData` junta: `form.get('date')` é o texto do campo de data.
- **`defaultValue={30}`**, não `value`: ele define o valor inicial e depois deixa o campo em paz. Um
  `value` sem `onChange` congelaria o campo, e o React avisa exatamente sobre isso.
- **`event.currentTarget.reset()`** esvazia o formulário depois de acrescentar, do jeito do próprio
  navegador, sem estado para limpar.
- **`required`, `min` e `max`** são a validação do navegador, que a próxima seção examina.

Qual escrever? **Controlado quando a tela precisa reagir enquanto o usuário digita**: uma contagem de
caracteres, um campo que habilita outro, uma busca que filtra enquanto você escreve. **Não controlado
quando os valores só importam no envio**, o que é a maioria dos formulários, inclusive este. Os dois
são React; nenhum é o jeito antigo. As bibliotecas de formulário do resto desta aula são quase todas
não controladas por baixo, e a aula 16 mostra o React 19 entregando o `FormData` de um formulário
direto a uma função, sem handler nenhum.
