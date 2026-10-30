---
title: Gerar em vez de digitar
version: 1
---

**O `ng generate` escreve os arquivos de uma peça nova da aplicação, no formato que o projeto já
usa.** Um componente são quatro arquivos com um decorator, um import e um seletor que precisam
concordar entre si; digitá-los à mão é por onde entra uma divergência. O primeiro componente novo do
planner é o resumo da semana, da árvore da aula 1.

Pergunte antes o que ele faria. O `--dry-run` imprime o plano e não escreve nada:

```
ana@dev:~/planner$ npx ng generate component week-summary --dry-run
CREATE src/app/week-summary/week-summary.css (0 bytes)
CREATE src/app/week-summary/week-summary.spec.ts (567 bytes)
CREATE src/app/week-summary/week-summary.ts (209 bytes)
CREATE src/app/week-summary/week-summary.html (27 bytes)

NOTE: The "--dry-run" option means no changes were made.
```

Depois para valer, e a classe que ele escreveu:

```
ana@dev:~/planner$ npx ng generate component week-summary
CREATE src/app/week-summary/week-summary.css (0 bytes)
CREATE src/app/week-summary/week-summary.spec.ts (567 bytes)
CREATE src/app/week-summary/week-summary.ts (209 bytes)
CREATE src/app/week-summary/week-summary.html (27 bytes)
ana@dev:~/planner$ cat src/app/week-summary/week-summary.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {}
```

Quatro coisas a notar, porque todo componente que você gerar se parece com este:

- **O nome que você digitou, `week-summary`, virou três nomes.** A pasta e os arquivos são
  `week-summary`, a classe é `WeekSummary`, e o seletor, a tag que você escreve num template para usar
  o componente, é `app-week-summary`. `app` é o prefixo que o `ng new` escolheu, para que um
  componente seu nunca colida com um elemento HTML ou com o de outra biblioteca.
- **Os arquivos têm o nome do que são, sem um tipo no nome.** Projetos mais antigos, e a maior parte
  do código que você vai abrir no trabalho, têm `week-summary.component.ts` e uma classe chamada
  `WeekSummaryComponent`. O Angular mudou o guia de estilo na versão 20, e o `ng new` pede o novo;
  `--file-name-style-guide=2016` traria o antigo de volta.
- **`imports: []`** é a lista dos outros componentes que o template pode usar. Está vazia porque o
  template não usa nenhum, e a aula 3 é sobre o que vai ali.
- **Um teste veio junto**, `week-summary.spec.ts`, que confere se o componente pode ser criado. O
  `--skip-tests` o deixa de fora; este curso os mantém, e a aula 24 é sobre escrever testes de
  verdade.

Nada usa o `WeekSummary` ainda, então a página não mudou. A aula 4 o põe na tela.

## O que mais ele gera

`component` é um **schematic**, a palavra da CLI para um gerador. Os que este curso usa, cada um na
aula que precisa dele primeiro:

| comando | escreve | aula |
|---|---|---|
| `ng generate component NOME` | um componente: classe, template, estilos, teste | 3 a 9 |
| `ng generate service NOME` | uma classe marcada com `@Injectable` | 11 |
| `ng generate interceptor NOME` | uma função que vê toda requisição HTTP | 12 |
| `ng generate guard NOME` | uma função que o router consulta antes de navegar | 18 |
| `ng generate pipe NOME` | uma função que um template usa para formatar um valor | 19 |
| `ng generate directive NOME` | um comportamento que você prende a um elemento existente | 20 |

Cada um tem uma forma curta, `ng g c`, `ng g s` e assim por diante, e cada um aceita `--dry-run`, que
é o hábito que vale manter: ver o que ele vai escrever antes que escreva.
