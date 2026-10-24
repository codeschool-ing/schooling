---
title: Um error boundary
version: 1
---

**Um error boundary é um componente que captura erros lançados durante a renderização de qualquer coisa
dentro dele, e desenha outra coisa no lugar.** O React não tem hook para isso: um boundary é escrito
como classe, o único lugar do React moderno em que um componente de classe ainda é o único jeito. Ele
inteiro é o `src/ErrorBoundary.tsx`:

```schooling-example
{"language": "tsx", "file": "src/ErrorBoundary.tsx", "parts": [{"code": "import { Component, type ErrorInfo, type ReactNode } from 'react'\n", "note": "`Component` é a classe base que todo componente de classe estende, e `ErrorInfo` é o tipo do que o React conta ao boundary sobre um erro."}, {"code": "type ErrorBoundaryProps = {\n  fallback: ReactNode\n  children: ReactNode\n}\n", "note": "Duas props: o que desenhar quando algo falhou, e os filhos a desenhar quando nada falhou."}, {"code": "type ErrorBoundaryState = { failed: boolean }\n", "note": "Uma classe guarda o estado num objeto só, o `this.state`. Este precisa de um fato: se um filho falhou."}, {"code": "export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {\n  state: ErrorBoundaryState = { failed: false }\n", "note": "**O estado começa como não falho.** O `Component<Props, State>` diz ao TypeScript a forma dos dois, então `this.props.fallback` é conferido como qualquer prop."}, {"code": "  static getDerivedStateFromError(): ErrorBoundaryState {\n    return { failed: true }\n  }\n", "note": "**O React chama isto quando um filho lança durante a renderização**, e renderiza o boundary de novo com o estado que ele devolve. Roda no meio de uma renderização, então só deve calcular: nada de registrar aqui."}, {"code": "  componentDidCatch(error: Error, info: ErrorInfo) {\n    console.error(`ErrorBoundary: ${error.message}${info.componentStack}`)\n  }\n", "note": "**Chamado depois que a reserva está na página**, com o erro e `info.componentStack`, os componentes por onde o erro subiu. O lugar para efeitos colaterais, como um relatório."}, {"code": "  render() {\n    return this.state.failed ? this.props.fallback : this.props.children\n  }\n}", "note": "Desenha a reserva quando um filho falhou e os filhos até lá. `this.props` e `this.state` são as versões, numa classe, das props e do `useState` de um componente de função."}]}
```

Envolva cada cartão num deles, no `src/CourseList.tsx`. A `key` passa do cartão para o boundary, já
que agora o boundary é o elemento mais externo que a lista renderiza para cada curso:

```tsx
import { Card } from './Card'
import { CourseCard } from './CourseCard'
import { ErrorBoundary } from './ErrorBoundary'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseList({ courses, sessions, onOpen }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <ErrorBoundary
          key={course.id}
          fallback={
            <Card title={course.name}>
              <p>This course could not be shown.</p>
            </Card>
          }
        >
          <CourseCard
            course={course}
            sessions={sessions.filter((s) => s.course === course.id)}
            onOpen={onOpen}
          />
        </ErrorBoundary>
      ))}
    </section>
  )
}
```

A reserva é um `Card` com o nome do curso e uma frase, então um cartão que falha continua ocupando o
seu lugar na lista e diz que curso era. Faça a mesma coisa de antes, marcando a última sessão de
estatística:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 84ms on 19 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
-- click button Back to courses
[error] %o

%s

%s
 TypeError: Cannot read properties of undefined (reading 'date')
    at CourseCard (http://localhost:5173/src/CourseCard.tsx:30:80)
    at Object.react_stack_bottom_frame (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:14140:12)
    at renderWithHooks (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:4398:19)
    at updateFunctionComponent (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:5773:16)
    at beginWork (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:6389:20)
    at runWithFiberInDEV (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:942:66)
    at performUnitOfWork (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9146:92)
    at workLoopSync (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9042:37)
    at renderRootSync (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:9026:6)
    at performWorkOnRoot (http://localhost:5173/node_modules/.vite/deps/react-dom_client.js?v=f3762bc1:8713:27) The above error occurred in the <CourseCard> component. React will try to recreate this component tree from scratch using the error boundary you provided, ErrorBoundary.
[error] ErrorBoundary: Cannot read properties of undefined (reading 'date')
    at CourseCard (http://localhost:5173/src/CourseCard.tsx:5:30)
    at ErrorBoundary (http://localhost:5173/src/ErrorBoundary.tsx:2:8)
    at section (<anonymous>)
    at CourseList (http://localhost:5173/src/CourseList.tsx:6:30)
    at main (<anonymous>)
    at App (http://localhost:5173/src/App.tsx:14:30)
    at PlannerProvider (http://localhost:5173/src/PlannerProvider.tsx:6:35)
    at QueryClientProvider (http://localhost:5173/node_modules/.vite/deps/@tanstack_react-query.js?v=f3762bc1:43:30)
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: This course could not be shown.
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

**A página ficou.** O título, os botões de semana, o resumo com os seus 120 minutos, os cartões de
espanhol e química estão todos lá; só o cartão de estatística virou *This course could not be shown.*
O erro subiu a árvore a partir do `CourseCard` e parou no boundary mais próximo acima dele, e os
boundaries em volta dos outros dois cartões nem o viram.

```schooling-figure
{"svg": "<svg data-fig=\"caught\" viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A árvore do planejador com error boundaries. A raiz tem o App, que tem WeekNav, WeekSummary e CourseList. O CourseList tem três componentes ErrorBoundary, um por curso, cada um em volta de um CourseCard. O CourseCard de estatística lança um erro; o erro sobe até o boundary logo acima dele, que desenha o cartão de reserva. Os outros dois boundaries e tudo acima deles ficam intactos.\"><rect x=\"290\" y=\"10\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"40\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"360\" y1=\"40\" x2=\"115\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"210\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><line x1=\"360\" y1=\"40\" x2=\"285\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"470\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"360\" y1=\"40\" x2=\"545\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"545\" y1=\"100\" x2=\"360\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"300\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ErrorBoundary</text><line x1=\"360\" y1=\"160\" x2=\"360\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"300\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseCard</text><text x=\"360.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">statistics</text><line x1=\"545\" y1=\"100\" x2=\"500\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"440\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ErrorBoundary</text><line x1=\"500\" y1=\"160\" x2=\"500\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"440\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"500.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">spanish</text><line x1=\"545\" y1=\"100\" x2=\"640\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"130\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ErrorBoundary</text><line x1=\"640\" y1=\"160\" x2=\"640\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"190\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"640.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">chemistry</text><path d=\"M 296 214 C 270 200 270 160 296 148\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><polygon points=\"296.0,148.0 291.2,154.6 287.9,149.1\" fill=\"var(--amber)\"></polygon><text x=\"260\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">lança</text><text x=\"360\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o cartão de reserva</text><text x=\"570\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">desenhados como antes</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">intactos:</text><text x=\"40\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a semana, o resumo</text></svg>", "caption": "Um erro sobe até o boundary mais próximo, e não passa dele."}
```

O console agora tem dois erros, ambos em vermelho, e eles são as duas metades do boundary em ação:

- **O relatório do próprio React**, o comprido com `%o` e `%s`, que em desenvolvimento nomeia o
  boundary que assumiu: *React will try to recreate this component tree from scratch using the error
  boundary you provided, ErrorBoundary.* A pilha dele é uma pilha JavaScript, quase toda de funções do
  próprio React, com números de linha do arquivo como o Vite o serviu depois de compilar o JSX, e por
  isso o `CourseCard.tsx:30` não bate com o código-fonte.
- **A linha do `componentDidCatch`**, que começa com `ErrorBoundary:`. A pilha dela é outra: a pilha
  de *componentes*, a cadeia de componentes desde o que falhou até a raiz. É essa a pilha que quem
  depura o problema quer, e é ela que você mandaria a um serviço de relatório de erros.

O React dá ao boundary dois métodos para dois momentos, e eles não são intercambiáveis:

| método | quando o React o chama | o que ele pode fazer |
|---|---|---|
| `static getDerivedStateFromError(error)` | durante a renderização, assim que um filho lançou | devolver o estado novo, e nada mais: é uma função pura |
| `componentDidCatch(error, info)` | depois que a reserva foi posta na página | efeitos colaterais: registrar, mandar um relatório |
