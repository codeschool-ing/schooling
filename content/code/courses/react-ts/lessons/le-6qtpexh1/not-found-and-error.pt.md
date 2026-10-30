---
title: Não encontrado, e falhou
version: 1
---

**Duas coisas podem dar errado numa página de curso, e elas merecem telas diferentes.** O curso pode não
existir, que é o endereço do estudante e culpa de ninguém; ou o servidor pode não responder, que não é
endereço de ninguém e é culpa nossa. Peça um curso que o planejador não tem:

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/latin --today 2026-10-21 | grep -v '^$'
[HMR] connected
- alert
- heading "404" [level=1]
- heading "This page could not be found." [level=2]
ana@dev:~/planner-next$ look http://localhost:3000/courses/latin --today 2026-10-21 | grep -v '^$'
[HMR] connected
- alert
- main:
  - heading "No such course" [level=1]
  - paragraph: The planner has no course at this address.
  - link "Back to the week":
    - /url: /
ana@dev:~/planner-next$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/courses/latin
200
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/latin | grep -o '<meta name="robots"[^>]*>'
<meta name="robots" content="noindex"/>
```

O primeiro `look` recebeu a página 404 do próprio Next.js: o `notFound()` rodou, e sem `not-found.tsx`
na pasta, o Next.js usou o padrão dele. A do planejador, em `app/courses/[courseId]/not-found.tsx`:

```tsx
import Link from 'next/link'

export default function CourseNotFound() {
  return (
    <main>
      <h1>No such course</h1>
      <p>The planner has no course at this address.</p>
      <Link href="/">Back to the week</Link>
    </main>
  )
}
```

apareceu no segundo. Depois, duas verificações sem navegador. **O status é 200**, não 404, e a página
traz uma meta tag `robots` que diz `noindex`. Esse é o preço do `loading.tsx`: para mandar a reserva na
hora, o servidor teve de mandar primeiro a linha de status, antes de a página descobrir que o curso não
existe, e um status já mandado não pode mudar. O Next.js faz o melhor possível e diz aos buscadores que
não indexem a página. Uma verificação que precisa responder 404 roda antes de qualquer streaming, no
lugar onde estava o loader da aula 17: o proxy do Next.js, que roda antes da página.

**Um servidor que não responde é uma falha, não uma ausência.** O error boundary da pasta,
`app/courses/[courseId]/error.tsx`:

```tsx
'use client'

export default function CourseError({ retry }: { error: unknown; retry: () => void }) {
  return (
    <main>
      <h1>The course could not be loaded</h1>
      <p role="alert">The planner's server did not answer.</p>
      <button type="button" onClick={() => retry()}>
        Try again
      </button>
    </main>
  )
}
```

- **Ele precisa ser Client Component**, porque um error boundary guarda estado, como a classe da aula 12,
  e oferece um botão.
- **`retry`**, do Next.js, renderiza a página de novo no servidor. Uma página que falhou porque o servidor
  caiu por um momento ganha uma segunda chance, que é o que a aula 12 disse que uma nova tentativa
  precisa.

Com a API parada:

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$' | grep -v '^    at '
[HMR] connected
[error] %o
%s TypeError: fetch failed
- alert
- main:
  - heading "The course could not be loaded" [level=1]
  - alert: The planner's server did not answer.
  - button "Try again"
```

O `fetch` da página falhou, *TypeError: fetch failed*, no formato de console do React; o boundary trocou
a página pelo título dele, um alerta e um botão. O resto da aplicação, se houvesse um layout em volta do
curso, teria ficado.
