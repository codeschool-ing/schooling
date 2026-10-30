---
title: A lista de imports, e o erro que ela evita
version: 1
---

**Um template só pode usar outro componente se o componente dono do template o importar.** A regra é
só essa, e o erro quando ela é quebrada é um que você vai ler muitas vezes, então esta seção a quebra
de propósito.

A primeira tela do planner é a semana, da árvore da aula 1. Gere-a:

```
ana@dev:~/planner$ npx ng generate component week
CREATE src/app/week/week.css (0 bytes)
CREATE src/app/week/week.spec.ts (517 bytes)
CREATE src/app/week/week.ts (178 bytes)
CREATE src/app/week/week.html (19 bytes)
```

O template dela é um título e o resumo da seção anterior:

```html
<!-- src/app/week/week.html -->
<h2>This week</h2>
<app-week-summary />
```

`<app-week-summary />` se fecha sozinho: uma tag de componente sem nada dentro pode ser escrita assim,
coisa que o HTML puro não permite para os próprios elementos. O componente raiz mostra a semana logo
abaixo do título da página, então o `App` importa o `Week` e escreve a tag dele:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<app-week />
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

O signal `title` que o `ng new` pôs no `App` sumiu: nada o lia. O `Week` em si está como a CLI o
escreveu, com `imports: []`. Faça o build:

```
ana@dev:~/planner$ npx ng build
❯ Building...
✔ Building...
Application bundle generation failed. [4.944 seconds] - 2026-10-29T23:37:10.405Z

✘ [ERROR] NG8001: 'app-week-summary' is not a known element:
1. If 'app-week-summary' is an Angular component, then verify that it is included in the '@Component.imports' of this component.
2. If 'app-week-summary' is a Web Component then add 'CUSTOM_ELEMENTS_SCHEMA' to the '@Component.schemas' of this component to suppress this message. [plugin angular-compiler]

    src/app/week/week.html:3:0:
      3 │ <app-week-summary />
        ╵ ~~~~~~~~~~~~~~~~~~~~

  Error occurs in the template of component Week.

    src/app/week/week.ts:6:15:
      6 │   templateUrl: './week.html',
        ╵                ~~~~~~~~~~~~~
```

`NG8001` é o código do erro, e a mensagem diz tudo o que importa: `app-week-summary` não é um elemento
conhecido, no `week.html`, que pertence ao `Week`. A segunda metade da mensagem fala de elementos
personalizados que nem são componentes Angular, e não se aplica. **O Angular confere cada tag de um
template contra o `imports` do componente**, na hora do build, e recusa a que não consegue resolver,
em vez de desenhar um elemento desconhecido vazio e deixar você adivinhando.

O conserto vai na classe dona do template, não no `WeekSummary`:

```typescript
// src/app/week/week.ts
import { Component } from '@angular/core';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | tail -3

Output location: /home/ana/planner/dist/planner
```

## O que vai na lista

| ponha no `imports` | porque o template o usa como |
|---|---|
| um componente | um elemento: `<app-week-summary />` |
| uma diretiva | um atributo: `routerLink`, na aula 17 |
| um pipe | um `|` numa expressão: `date`, na aula 19 |
| um NgModule | tudo isso de uma vez, para bibliotecas que ainda trazem módulos: as próximas seções |

O que não vai ali é qualquer coisa que a classe usa no próprio código, como um serviço: uma linha
`import` do TypeScript no topo do arquivo basta para isso. Os `imports` do decorator são só para o
template, que o TypeScript não lê.

São duas listas, então, com a mesma palavra. As linhas `import` do topo deixam um nome disponível para
o arquivo, e o `imports` do `@Component` o deixa disponível para o template. Um componente na segunda
lista precisa estar na primeira também, e é por isso que o seu editor oferece acrescentar os dois.
