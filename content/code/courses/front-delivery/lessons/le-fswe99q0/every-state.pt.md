---
title: Todo estado, por escrito
version: 1
---

**O valor de uma oficina está nos estados que ninguém veria de outro jeito, e escrevê-los é o trabalho.**
Três stories para a linha vieram de fazer três perguntas: como ela fica antes, depois, e quando os dados
são maiores do que a designer imaginou? O resumo da semana ganha as mesmas perguntas, e mais uma: o que ele
diz quando não há nada a dizer?

```typescript
// src/week-summary.stories.ts
import type { Meta, StoryObj } from "@storybook/html-vite";
import { weekSummary } from "./components";

type Args = { planned: number; done: number };

const meta: Meta<Args> = {
  title: "Planner/Week summary",
  render: (week) => weekSummary(week),
  args: { planned: 130, done: 60 },
};
export default meta;

type Story = StoryObj<Args>;

export const InProgress: Story = {};
export const AllDone: Story = { args: { done: 130 } };
export const Empty: Story = { args: { planned: 0, done: 0 } };
```

`Empty` é a story que mudou o componente. Antes de ela existir, uma semana sem nada planejado dizia *This
week: 0 min planned, 0 min done*, o que é correto e parece defeito. Escrever a story deixou o caso visível,
e o `weekSummary` ganhou uma frase própria para ele. A aula 11 de portfolio-project chama esses de caminhos
que ninguém demonstra; uma story é como um design system os demonstra.

## As perguntas a fazer a todo componente

Uma lista curta cobre a maior parte do que dá errado entre um design e a tela:

| estado | no planner |
|---|---|
| vazio | uma semana sem nada planejado; um curso sem sessões |
| um, e muitos | uma sessão; quarenta, que rolam |
| longo demais | um título de curso de oitenta caracteres; uma sessão de 600 minutos |
| terminado, ou desabilitado | uma sessão já feita |
| carregando, e falhou | o momento antes de o `courses.json` chegar, e o dia em que ele não chega |
| cada tema | claro e escuro, a próxima seção |

**Nem todo componente precisa de toda linha.** Os que precisam são os que alguém encontra num momento
ruim: a lista vazia depois do cadastro, o erro depois de uma queda de rede. São exatamente os estados que
uma pessoa clicando pelo caminho feliz nunca alcança.

## Controles servem para achar estados, stories para guardá-los

O painel Controls deixa qualquer pessoa mudar os argumentos de uma story enquanto olha para ela, e é assim
que um estado novo é achado: digite 600 em `minutes` e veja se *10 h* cabe. **Um estado que vale guardar
vira uma story**, porque o valor de um controle some quando a aba fecha, e uma story fica no repositório,
revisada e, a partir da seção sobre testes, conferida em todo push.
