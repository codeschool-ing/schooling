---
title: Um loader como guarda
version: 1
---

**Um endereço pode nomear algo que não existe**, e alguém vai digitar um. O loader é o lugar de pegar
isso, porque roda antes da tela: uma tela que nunca é desenhada não pode quebrar num curso que não está
lá. Peça um curso que o planejador não tem, e um endereço que nenhuma rota atende:

```
ana@dev:~/planner$ look http://localhost:5173/courses/latin --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - alert: "404: There is no course called “latin”."
  - link "Back to this week":
    - /url: /
ana@dev:~/planner$ look http://localhost:5173/no/such/page --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - alert: "404: Error: No route matches URL \"/no/such/page\""
  - link "Back to this week":
    - /url: /
```

Os dois chegaram ao `src/RouteError.tsx`, o `ErrorBoundary` da rota em `/`:

```tsx
import { isRouteErrorResponse, Link, useRouteError } from 'react-router'

export function RouteError() {
  const error = useRouteError()
  const message = isRouteErrorResponse(error)
    ? `${error.status}: ${error.data}`
    : error instanceof Error
      ? error.message
      : 'Something went wrong.'
  return (
    <main>
      <h1>Study planner</h1>
      <p role="alert">{message}</p>
      <Link to="/">Back to this week</Link>
    </main>
  )
}
```

- **`throw data(…, { status: 404 })`** no loader parou a rota antes de ela ser desenhada, e o roteador
  usou o `ErrorBoundary` mais próximo no lugar, com o valor lançado vindo do `useRouteError()`. O
  `isRouteErrorResponse` reconhece um `data()` lançado e dá o `status` e o `data` dele, aqui a frase.
- **Um endereço que nenhuma rota atende** é o 404 do próprio roteador, pelo mesmo boundary, com a frase
  dele: *No route matches URL*.
- **Qualquer outra coisa lançada ao renderizar uma rota**, um `Error` comum, também chega aqui, e o
  boundary mostra a mensagem. O `ErrorBoundary` de uma rota é o error boundary da aula 12, dado a cada
  rota.

**Essa é a forma de todo guarda de rota.** O exemplo de costume é uma página que só usuários logados podem
ver: o loader dela confere a sessão e, quando não há, faz `throw redirect('/login')`, que manda o
navegador para outro lugar antes de qualquer coisa privada ser desenhada. O planejador não tem contas,
então o guarda dele é o 404, mas o mecanismo é o mesmo: **um loader roda primeiro, e pode recusar**.

Uma coisa que o servidor de desenvolvimento faz por você, e um servidor de verdade não faz sem pedido: o
Vite responde `/courses/latin` e `/no/such/page` com o `index.html`, para o roteador no navegador decidir.
Um servidor que só tem os arquivos do `npm run build` responderia esses endereços com o próprio 404, antes
de qualquer JavaScript rodar. Publicar um app de página única significa dizer ao servidor que responda com
o `index.html` todo endereço que não for um arquivo.
