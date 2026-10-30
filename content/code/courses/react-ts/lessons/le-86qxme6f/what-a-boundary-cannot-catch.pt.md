---
title: O que um boundary não captura
version: 1
---

**Um boundary captura o que dá errado enquanto o React está desenhando: a renderização, e os efeitos
que rodam depois dela.** Um erro que acontece fora desse trabalho não passa pelo React no caminho para
cima, então nenhum boundary o vê:

| onde o erro é lançado | um boundary captura? | por quê |
|---|---|---|
| no corpo de um componente, enquanto renderiza | sim | o React chamou a função, e captura o que ela lança |
| num `useEffect` ou `useLayoutEffect` | sim | o React roda os efeitos como parte do commit de uma renderização |
| num handler de evento, como `onClick` | não | o navegador chama o handler, muito depois de a renderização acabar |
| num callback de `setTimeout` ou no `.then` de uma promise | não | rodam depois, fora do trabalho do React |
| no próprio `render` do boundary | não por ele mesmo | o erro vai para o próximo boundary acima dele |

Um erro num handler de evento deixa a página como estava e chega ao navegador como erro não capturado,
que em desenvolvimento aparece no console. O handler é JavaScript comum, então um `try`/`catch` dentro
dele, guardando algum estado que a renderização mostra, é o jeito de pôr esse erro na tela.

A última linha da tabela é a razão de um boundary só não bastar. **Um boundary em volta de cada cartão
protege a página de um cartão; nada ainda protege a página de todo o resto.** Um erro no
`WeekSummary`, ou no próprio `App`, ainda não acharia boundary acima dele, e a página ficaria branca
como antes. Então mais um vai em volta da aplicação inteira, no `src/main.tsx`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { ErrorBoundary } from './ErrorBoundary'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

const crashed = (
  <main>
    <h1>Study planner</h1>
    <p role="alert">Something went wrong, and the planner stopped. Reload the page to start again.</p>
  </main>
)

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary fallback={crashed}>
      <QueryClientProvider client={queryClient}>
        <PlannerProvider>
          <App />
        </PlannerProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>,
)
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 56ms on 19 files with 116 rules using 4 threads.
no errors
```

A reserva dele é simples de propósito. Ela aparece quando algo imprevisto falhou, então não usa nada
que possa falhar junto: nem dados, nem contexto, nem outro componente do app. O título é o mesmo de
toda tela, para o usuário ver que continua no planejador, e o `role="alert"` faz um leitor de tela
anunciar o parágrafo assim que ele aparece.

Este boundary fica **fora** dos providers de propósito. Um erro no `PlannerProvider` ou no cliente de
queries também é capturado, e a reserva não precisa de nenhum dos dois.

As duas camadas respondem a duas perguntas. Os boundaries em volta dos cartões dizem que partes da tela
**podem falhar sozinhas** e deixar o resto funcionando. O da raiz diz o que o usuário vê **quando
qualquer outra coisa falha**, para que a resposta nunca seja uma página branca.
