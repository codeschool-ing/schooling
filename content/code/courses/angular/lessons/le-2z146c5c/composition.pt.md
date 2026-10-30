---
title: Compondo diretivas num componente
version: 1
---

**O `hostDirectives` põe diretivas no próprio elemento de um componente, de dentro do componente.** Um
componente que sempre quer um comportamento pode carregá-lo, em vez de todo template que usa o
componente ter de lembrar um atributo. Os inputs da diretiva não ficam expostos a não ser que sejam
listados, então o componente decide o que quem o usa pode definir.

```typescript
@Component({
  selector: 'app-card',
  hostDirectives: [{ directive: Highlight, inputs: ['appHighlight'] }],
  template: '<ng-content />',
})
export class Card {}
```

```html
<app-card appHighlight="khaki">Highlighted, with no directive written here.</app-card>
```

Todo `<app-card>` agora destaca ao passar o mouse e ao receber o foco, e o `appHighlight` define a cor
dele. As bibliotecas do próprio Angular usam isso para montar componentes a partir de pequenos
comportamentos, e o CDK da aula 21 tem muitos deles para compor.

| uma diretiva é | quando |
|---|---|
| uma diretiva de atributo | um comportamento ou aparência acrescentado a um elemento existente: foco, destaque, um atributo |
| uma diretiva estrutural | um template desenhado sob condição ou repetido, onde `@if` e `@for` não servem |
| no `hostDirectives` | um comportamento que toda instância de um componente deve ter |
| um componente | há algo novo para desenhar |

O bench sai, e as duas diretivas que o planner usa ficam:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/add-session/add-session.ts
?? src/app/aria-invalid.ts
?? src/app/autofocus.spec.ts
?? src/app/autofocus.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Directives: focus on arrival, and aria-invalid on every field"
```
