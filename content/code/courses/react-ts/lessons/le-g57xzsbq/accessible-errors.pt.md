---
title: O formulário, com erros que um leitor de tela encontra
version: 1
---

**Uma mensagem de erro só serve se quem errou consegue encontrá-la.** Para quem enxerga, isso é um
texto ao lado do campo. Para quem usa leitor de tela, é o próprio campo dizer que está inválido, a
mensagem estar presa a ele, e o foco ir até lá. Este é o formulário com o React Hook Form, o schema, e
as três coisas:

```tsx
import { zodResolver } from '@hookform/resolvers/zod'
import { useId } from 'react'
import { useForm } from 'react-hook-form'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const id = useId()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SessionInput>({
    resolver: zodResolver(sessionSchema),
    defaultValues: { date: '', minutes: 30 },
  })

  function submit(values: SessionInput) {
    addSession({ course, ...values })
    reset()
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <h2>Add a session</h2>
      <label htmlFor={`${id}-date`}>Date</label>
      <input
        id={`${id}-date`}
        type="date"
        aria-invalid={errors.date ? true : undefined}
        aria-describedby={errors.date ? `${id}-date-error` : undefined}
        {...register('date')}
      />
      {errors.date && <p id={`${id}-date-error`}>{errors.date.message}</p>}
      <label htmlFor={`${id}-minutes`}>Minutes</label>
      <input
        id={`${id}-minutes`}
        type="number"
        aria-invalid={errors.minutes ? true : undefined}
        aria-describedby={errors.minutes ? `${id}-minutes-error` : undefined}
        {...register('minutes', { valueAsNumber: true })}
      />
      {errors.minutes && <p id={`${id}-minutes-error`}>{errors.minutes.message}</p>}
      <button type="submit">Add session</button>
    </form>
  )
}
```

- **`useForm` com `zodResolver(sessionSchema)`** roda o schema no envio e preenche `errors` com as
  mensagens dele. O `defaultValues` dá os valores iniciais, e o `reset()` volta a eles.
- **`{...register('date')}`** espalha no input as props de que a biblioteca precisa, `name`, `ref`,
  `onChange` e `onBlur`; o `valueAsNumber` entrega ao schema um número para os minutos, como ele
  espera.
- **`handleSubmit(submit)`** chama o `submit` só com valores que o schema aceitou, já tipados como
  `SessionInput`.
- **`noValidate`** desliga os balões do navegador, porque o formulário agora mostra as próprias
  mensagens; os atributos `min` e `max` foram junto, já que o schema guarda essas regras.
- **`useId`** cria ids únicos por formulário, para que dois formulários numa página não colidam; o
  React os escreve como `_r_0_`, como a transcrição mostra.

Envie sem data e com 500 minutos:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 17 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' | sed -n '/heading "Add/,$p'
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date" [invalid]
  - paragraph: Choose the day of the session.
  - text: Minutes
  - spinbutton "Minutes" [invalid]: "500"
  - paragraph: A session is at most 240 minutes.
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html ':focus'
-- click button Statistics
-- fill Minutes=500
-- click button Add session
<input id="_r_0_-date" type="date" name="date" aria-invalid="true" aria-describedby="_r_0_-date-error">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input[aria-invalid]'
-- click button Statistics
-- fill Minutes=500
-- click button Add session
<input id="_r_0_-date" type="date" name="date" aria-invalid="true" aria-describedby="_r_0_-date-error">
```

Os dois campos estão marcados como `[invalid]` no retrato, que é o `aria-invalid="true"`, e cada
mensagem é um parágrafo embaixo do campo. **O foco foi para o primeiro campo inválido**, a data,
porque o React Hook Form o foca por padrão; o `aria-describedby` do campo aponta para a mensagem dele,
então um leitor de tela anuncia o campo, que ele está inválido, e "Choose the day of the session." O
usuário cai no problema e ouve o que é.

Corrija os dois e as mensagens somem conforme os campos mudam, porque depois de um envio que falhou a
biblioteca confere de novo a cada mudança; envie, e a sessão é acrescentada e o formulário se esvazia:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' | sed -n '/heading "Add/,$p'
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date": 2026-10-24
  - text: Minutes
  - spinbutton "Minutes": "45"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep minutes
    - paragraph: 80 of 240 minutes done
```

240 minutos planejados agora, 195 mais 45. Este é o formulário que o planejador mantém.

| o que o torna encontrável | como |
|---|---|
| o campo tem um nome | um `<label>` ligado a ele com `htmlFor` |
| o campo diz que está errado | `aria-invalid` |
| a mensagem pertence ao campo | `aria-describedby` apontando para o `id` da mensagem |
| o usuário é levado até ele | foco no primeiro campo inválido |
| a mensagem diz o que fazer | "Choose the day of the session", não "Inválido" |
