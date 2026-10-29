---
title: Um elemento, quatro frameworks
version: 1
---

**Um elemento registrado no navegador pode ser escrito por qualquer coisa que escreva HTML.** Esse era o
motivo de construir um. Esta seção o lança na biblioteca e depois mostra a mesma linha usada em React,
Angular, Vue e Svelte.

## Lançado com a biblioteca

O elemento é exportado ao lado dos componentes em forma de função, então quem consome importa a classe e a
função que a registra do mesmo pacote:

```
ana@dev:~/planner-ui$ echo 'export { PlannerSession, definePlannerSession } from "./session-element";' >> src/index.ts
ana@dev:~/planner-ui$ npx tsc && echo types ok
types ok
```

O changelog ganha a sua entrada antes de a versão mudar:

```
<!-- CHANGELOG.md -->
# Changelog

## 0.3.0

- Added `<planner-session>`, a Web Component for a session row, registered by `definePlannerSession()`.

## 0.2.0

- Added `progressBar`, which shows minutes done out of minutes planned.

## 0.1.0

- First release: the tokens, the type and spacing scales, two themes, `actionButton`, `sessionRow` and
  `weekSummary`.
```

Depois, o lançamento da aula 7, uma versão minor, porque nada que funcionava antes mudou:

```
ana@dev:~/planner-ui$ git add -A && git commit -qm "Export <planner-session>"
ana@dev:~/planner-ui$ npm version minor
v0.3.0
ana@dev:~/planner-ui$ git log --oneline --decorate -3
e197621 (HEAD -> main, tag: v0.3.0) 0.3.0
4bd022f Export <planner-session>
c68c1b3 Add <planner-session>, its demo page and its tests
ana@dev:~/planner-ui$ npm run build > /dev/null && npm publish 2>&1 | tail -1
+ @planner/ui@0.3.0
```

Uma página o usa com duas linhas e uma tag:

```typescript
import { definePlannerSession } from "@planner/ui";
definePlannerSession();
```

O registro é uma chamada, e não algo que o import faz sozinho, então a página decide quando a tag começa a
funcionar, e um app que só usa os componentes em forma de função não registra um elemento que ninguém
escreve.

## A mesma linha, de quatro jeitos

**Nenhum dos quatro foi executado para este curso**: cada um seria um projeto à parte, com a sua própria
versão para fixar. O que está aqui é a forma que a documentação de cada um dava, em outubro de 2026, para
usar um custom element. Os quatro têm três coisas a dizer: que a tag não é deles, como os atributos são
passados e como o evento é ouvido.

### React

O React 19 passa props a um custom element como atributos ou propriedades, e uma prop que começa com `on`
vira um listener do evento com o nome do resto. O TypeScript precisa ser avisado de que a tag existe:

```tsx
// declare the tag once, for TypeScript
declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "planner-session": React.HTMLAttributes<HTMLElement> & { date: string; minutes: number };
    }
  }
}

<planner-session id="session-6" date="2026-10-15" minutes={45} onsession-done={() => setDone(true)}>
  JavaScript
</planner-session>
```

O React 18 e anteriores definem tudo como atributo e não escutam eventos customizados: um listener entra por
um `ref` e `addEventListener`.

### Angular

O Angular recusa um elemento que não conhece, a menos que o componente diga que custom elements são
permitidos:

```typescript
@Component({
  selector: "app-session",
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <planner-session id="session-6" [attr.date]="date" [attr.minutes]="minutes" (session-done)="done = true">
      JavaScript
    </planner-session>
  `,
})
export class SessionComponent {
  date = "2026-10-15";
  minutes = 45;
  done = false;
}
```

`[attr.date]` define o atributo; um `[date]` simples definiria uma propriedade, que este elemento não tem.
`(session-done)` escuta o evento pelo nome.

### Vue

O Vue tenta resolver toda tag como um componente dele, a menos que o compilador seja avisado do contrário,
nas opções do plugin do Vite:

```typescript
// vite.config.ts
vue({ template: { compilerOptions: { isCustomElement: (tag) => tag.startsWith("planner-") } } })
```

```html
<planner-session id="session-6" :date="date" :minutes="minutes" @session-done="done = true">
  JavaScript
</planner-session>
```

O Vue define um valor ligado como propriedade quando o elemento tem uma com esse nome, e como atributo
quando não tem, então `:minutes` vira o atributo aqui.

### Svelte

O Svelte não precisa de configuração: uma tag com hífen é um custom element para ele. No Svelte 5, um
atributo que começa com `on` é um listener, então o evento é ouvido do jeito que o `onclick` é:

```html
<planner-session id="session-6" {date} {minutes} onsession-done={() => (done = true)}>
  JavaScript
</planner-session>
```

Como o Vue, o Svelte define uma propriedade quando o elemento tem uma, e um atributo quando não tem.

## Em que os quatro concordam

Cada um escreve a tag, passa os atributos e ouve `session-done`, e nenhum deles precisa que a biblioteca
saiba qual framework está do outro lado. As diferenças ficam todas do lado do framework, numa
configuração ou numa declaração cada, e são o preço de um componente escrito uma vez só.
