---
title: Refs tipadas, a store e o router
version: 1
---

**O tipo de uma ref quase sempre é deduzido do valor inicial, e precisa ser escrito quando o valor
inicial diz pouco demais**: um array vazio, `null`, ou um elemento que ainda não existe. Esses três
são quase todos os erros que sobraram, e cada um tem uma correção pequena e padrão.

## Um array vazio: diga o que ele vai guardar

`ref([])` começa como um array de nada, que o TypeScript chama de `never[]`, e não se lê nada de um
`never`. A store diz o que os seus arrays vão guardar, com um argumento de tipo:

```typescript
const courses = ref<Course[]>([])
const sessions = ref<Session[]>([])
```

com `type Course` e `type Session` acrescentados ao import da store de `../planner.js`, e os
parâmetros das actions tipados como os de qualquer função: o `(id: string)` do `hasCourse`,
`toggle(id: string)`, `add(session: Omit<Session, 'id' | 'done'>)`, e `let loading: Promise<void> |
null = null`. Essa única mudança na store corrige os erros de todas as views, porque as views leem a
store, e **os tipos delas decorrem dela sem nada escrito nelas**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Onde os tipos do planner são escritos e onde só são inferidos. O planner.ts declara Course e Session. A store escreve ref de array de Course e ref de array de Session, uma vez. As views e os componentes leem a store e recebem esses tipos sem nada escrito neles; o SessionRow nomeia Session nas props porque o recebe do pai.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">planner.ts</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">interface Session</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escrito</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">stores/planner.ts</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ref&lt;Session[]&gt;([])</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">escrito uma vez</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">HomeView.vue</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sessions.value</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">inferido</text><line x1=\"222\" y1=\"75\" x2=\"258\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,75.0 250.6,78.1 250.6,71.9\" fill=\"var(--wire)\"></polygon><line x1=\"462\" y1=\"75\" x2=\"498\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,75.0 490.6,78.1 490.6,71.9\" fill=\"var(--wire)\"></polygon><rect x=\"500\" y=\"150\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SessionRow: session: Session</text><line x1=\"600\" y1=\"112\" x2=\"600\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"600.0,148.0 596.9,140.6 603.1,140.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Os tipos são escritos onde os dados nascem, e todo leitor depois disso os recebe de graça."}
```

## Algo que talvez ainda não esteja lá: `?.`

O `useTemplateRef('dialog')` é `null` até o componente ser montado, como a aula 9 mostrou, então o
verificador insiste na possibilidade:

```typescript
const dialog = useTemplateRef<HTMLDialogElement>('dialog')
defineExpose({
  open: () => dialog.value?.showModal(),
  close: () => dialog.value?.close(),
})
```

`<HTMLDialogElement>` diz qual elemento ela vai ser, então se sabe que o `showModal` existe; o `?.`
só o chama se a ref estiver preenchida. As mesmas duas mudanças vão para o `SessionForm`,
`useTemplateRef<HTMLSelectElement>('course')` e `courseField.value?.focus()`, e para o `HomeView`,
cuja ref guarda um componente: `useTemplateRef<InstanceType<typeof PlannerDialog>>('adding')`, que é
como se tipa uma template ref para um componente, com `adding.value?.close()` no script e
`adding?.open()` no template.

## Um timer, uma rota, uma mensagem

Os últimos são uma linha cada. A terceira linha não está entre os 59: ela aparece quando a segunda é
corrigida, porque até lá o `to` não tem tipo do qual reclamar.

| erro | onde | correção |
|---|---|---|
| `timer` implicitamente `any` | `useToday.ts` | o tipo do que o `setInterval` devolve, abaixo da tabela |
| `to` implicitamente `any` | `router.ts` | `const routes: RouteRecordRaw[] = [...]`, com `type RouteRecordRaw` importado de `vue-router`, para que o guard de cada rota receba o seu tipo |
| um parâmetro que pode ser uma lista, passado onde se espera uma string | o guard do `router.ts` | `planner.hasCourse(String(to.params.id))`: um parâmetro pode se repetir, então o router o tipa como qualquer um dos dois |
| `message` implicitamente `any` | o `onAdded` do `HomeView.vue` | `function onAdded(message: string)` |
| `shown.course` não existe em `{}` | `SessionForm.vue` | um tipo com nome para as mensagens, abaixo |

O timer é declarado `let timer: ReturnType<typeof setInterval> | undefined`: o que quer que o
`setInterval` devolva, ou nada antes de o componente ser montado. E o `SessionForm` dá nome à forma
das suas mensagens uma vez, e a usa nos dois valores computados:

```typescript
type Errors = Record<'course' | 'date' | 'minutes', string>

const errors = computed<Errors>(() => ({
```

e `const shown = computed<Partial<Errors>>(() => (tried.value ? errors.value : {}))`, em que o
`Partial` diz que qualquer uma das três pode faltar, que é exatamente o que um `{}` vazio é. Com
isso, o verificador roda limpo:

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```
