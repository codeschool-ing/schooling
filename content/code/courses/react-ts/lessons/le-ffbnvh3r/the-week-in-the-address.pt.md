---
title: A semana no endereço
version: 1
---

**Um curso agora tem endereço; a semana não.** Ela ainda é estado dentro do `useWeek`, então este endereço
nomeia uma semana e o planejador o ignora:

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-12' --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
```

Foi pedido 12 de outubro, e veio a semana atual. Um link para uma semana que alguém queria mostrar a você,
ou recarregar a semana que você olhava, cai na de hoje. A correção é a da aula 15: a semana vai para o
endereço como **parâmetro de busca**, `?week=2026-10-12`, que no Next.js era `searchParams` e no React
Router é `useSearchParams`. O `src/useWeek.ts`:

```ts
import { useCallback, useEffect } from 'react'
import { useSearchParams } from 'react-router'
import { addDays, formatWeek, mondayOf, today } from './week'

const DAY = /^\d{4}-\d\d-\d\d$/

// The week on screen lives in the address, as ?week=YYYY-MM-DD, so that a link,
// a bookmark or a reload shows the same week.
export function useWeek() {
  const [params, setParams] = useSearchParams()
  const asked = params.get('week')
  const monday = mondayOf(asked && DAY.test(asked) ? asked : today())
  const setMonday = useCallback((m: string) => setParams({ week: m }), [setParams])

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday(addDays(monday, -7))
      if (event.key === 'ArrowRight') setMonday(addDays(monday, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [monday, setMonday])

  return [monday, setMonday] as const
}
```

- **O estado sumiu.** O `monday` é calculado a partir do endereço a cada renderização, com a semana de
  hoje quando o endereço não nomeia nenhuma, ou nomeia algo que não é uma data.
- **O `setMonday` escreve o endereço.** `setParams({ week: m })` muda a parte de busca da URL, o que
  renderiza de novo tudo o que a lê, e acrescenta uma entrada ao histórico, então Voltar retorna à semana
  anterior.
- **Nada que chamava o `useWeek` muda.** Ele ainda devolve `[monday, setMonday]`, então o `WeekScreen` e o
  `WeekNav` ficam intactos, que é para o que servia um hook próprio, na aula 7.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 71ms on 27 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-12' --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowLeft' | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
```

O endereço nomeia o dia 12, e o planejador mostra o dia 12, com os 60 minutos de química. A seta da aula 5
continua funcionando, agora escrevendo o endereço.

**O que pertence ao endereço** é o que alguém quereria compartilhar ou rever: qual tela, qual curso, qual
semana. O que não pertence é o que é particular deste momento: se um diálogo está aberto, o que está
digitado num campo. Isso fica no estado.
