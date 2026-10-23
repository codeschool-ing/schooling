---
title: Dando nome a um valor no template com @let
version: 1
---

**`@let nome = expressão;` dá a um valor um nome dentro do template, para que ele seja calculado uma
vez e lido onde for preciso.** O resumo da semana calcula `planned - done` e compara `done` com
`planned` separadamente, o que são dois jeitos de fazer a mesma pergunta. Dê nome à resposta:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned - done;
<p>{{ planned }} minutes planned, {{ done }} done.</p>
@if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

A mesma página de antes, que é o objetivo de uma refatoração. Quatro regras tornam o `@let`
previsível:

- **ele é só de leitura.** O template não pode atribuir a ele, nem num event binding;
- **ele é recalculado** toda vez que o Angular confere o template, a partir dos valores que lê, então
  nunca fica desatualizado;
- **ele é visível depois da sua linha**, no mesmo bloco e nos blocos de dentro, e não antes dela nem
  fora;
- **o tipo dele é inferido**, então `left` é um `number` e a comparação é conferida.

## Onde ele não é a ferramenta certa

O `@let` é para a conveniência do próprio template: uma expressão longa lida duas vezes, ou um valor
desembrulhado uma vez e usado em vários lugares. Um valor de que a classe também precisa, ou que dá
trabalho de verdade calcular, pertence à classe, onde pode ser testado; o `computed` da aula 6 é
exatamente isso, e o resumo da semana leva `left` para lá quando os números dele deixarem de ser
constantes.
