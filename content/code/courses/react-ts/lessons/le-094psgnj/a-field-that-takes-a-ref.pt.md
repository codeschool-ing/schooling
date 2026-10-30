---
title: Um campo que repassa o ref
version: 1
---

**No React 19, `ref` é uma prop como qualquer outra.** Um componente de função que recebe um pode
entregá-lo a um elemento, e o nó do elemento vai parar onde o ref aponta. Versões anteriores tratavam
`ref` como especial: ele nunca chegava ao componente, e repassá-lo exigia um envoltório chamado
`forwardRef`. Código escrito antes do React 19 está cheio dele; código novo não precisa.

O formulário dentro do diálogo tem as mesmas três linhas duas vezes: um rótulo, um input com os
atributos de acessibilidade e um parágrafo de erro. Um componente pode dizê-las uma vez, o
`src/Field.tsx`:

```tsx
import { useId, type ComponentProps } from 'react'

type FieldProps = ComponentProps<'input'> & {
  label: string
  error?: string
}

export function Field({ label, error, ...input }: FieldProps) {
  const id = useId()
  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        {...input}
      />
      {error && <p id={`${id}-error`}>{error}</p>}
    </>
  )
}
```

`ComponentProps<'input'>` é o tipo de toda prop que um `<input>` aceita, `ref` entre elas, e o `Field`
acrescenta duas próprias, `label` e `error`. Todo o resto, `...input`, segue para o input sem mudança.
O formulário, `src/AddSessionForm.tsx`, agora se lê como uma lista dos seus campos:

```tsx
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Field } from './Field'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

type AddSessionFormProps = {
  course: string
  onAdded: (session: SessionInput) => void
}

export function AddSessionForm({ course, onAdded }: AddSessionFormProps) {
  const { addSession } = usePlannerContext()
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
    addSession(
      { course, ...values },
      {
        onSuccess: () => {
          reset()
          onAdded(values)
        },
      },
    )
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <Field label="Date" type="date" error={errors.date?.message} {...register('date')} />
      <Field
        label="Minutes"
        type="number"
        error={errors.minutes?.message}
        {...register('minutes', { valueAsNumber: true })}
      />
      <button type="submit">Add session</button>
    </form>
  )
}
```

`{...register('date')}` espalha quatro coisas no `Field`: `name`, `onChange`, `onBlur` e **`ref`**. O
React Hook Form guarda o elemento que recebe por esse ref, lê dele o valor do input e o usa para focar o
primeiro campo com erro quando um envio falha. O ref atravessa o `Field` até o `<input>` porque, no
React 19, nada o impede: é uma das props em `...input`.

Duas outras mudanças. O título saiu, porque o diálogo tem um, e quem chama o formulário fica sabendo
quando uma sessão foi salva: `addSession` é o `mutate` do React Query, que aceita um segundo argumento
de callbacks **para esta chamada só**, e o `onSuccess` roda quando o servidor respondeu. Só então o
formulário reinicia e avisa quem o chamou, que fecha o diálogo. Um formulário que fechasse ao enviar
fecharia numa sessão que o servidor depois recusasse.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'click button Add session' | sed -n '/dialog/,$p'
  - dialog "Plan a session":
    - heading "Plan a session" [level=2]
    - text: Date
    - textbox "Date" [invalid]
    - paragraph: Choose the day of the session.
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
    - button "Close"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'dialog|checkbox'
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - checkbox "Wed 21 Oct · 40 min"
      - checkbox "Sat 24 Oct · 45 min"
```

A primeira página envia o formulário vazio: o diálogo fica, `Date` está `[invalid]`, e a mensagem do
schema aparece embaixo. A segunda preenche os dois campos e envia: **o diálogo sumiu, e os 45 minutos
de sábado estão na lista.** As caixas de marcação são da tela do curso, desenhadas de novo a partir do
cache depois da invalidação que a aula 11 montou.
