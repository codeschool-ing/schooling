---
title: Escolhendo, e para que nenhuma delas serve
version: 1
---

**As quatro versões do planejador se comportam de modo idêntico, e diferem no que pedem que você
escreva e no que facilitam.** Aqui está o código de que cada uma precisou, contado, e as versões que
cada uma instalou:

```
ana@dev:~$ wc -l planner/src/plannerContext.ts planner/src/PlannerProvider.tsx planner-*/src/store.ts planner-*/src/atoms.ts planner-*/src/plannerContext.ts planner-*/src/PlannerProvider.tsx
  14 planner/src/plannerContext.ts
   8 planner/src/PlannerProvider.tsx
  45 planner-redux/src/store.ts
  31 planner-zustand/src/store.ts
  10 planner-jotai/src/atoms.ts
  11 planner-jotai/src/plannerContext.ts
   9 planner-redux/src/plannerContext.ts
  13 planner-zustand/src/plannerContext.ts
  29 planner-jotai/src/PlannerProvider.tsx
  10 planner-redux/src/PlannerProvider.tsx
  10 planner-zustand/src/PlannerProvider.tsx
 190 total
ana@dev:~$ cd planner-zustand && npm ls zustand; cd ../planner-redux && npm ls @reduxjs/toolkit react-redux; cd ../planner-jotai && npm ls jotai
planner@0.0.0 /home/ana/planner-zustand
└── zustand@5.0.16

planner@0.0.0 /home/ana/planner-redux
├─┬ @reduxjs/toolkit@2.13.0
│ └── react-redux@9.3.0 deduped
└── react-redux@9.3.0

planner@0.0.0 /home/ana/planner-jotai
└── jotai@3.0.1
```

| | context | Zustand | Redux Toolkit | Jotai |
|---|---|---|---|---|
| linhas para este planejador | 22 | 54 | 64 | 50 |
| precisa de provider | sim | não | sim | não, por padrão |
| um componente renderiza de novo quando | o valor do context muda | a fatia que ele seleciona muda | a fatia que ele seleciona muda | um átomo que ele lê muda |
| o estado mora | num componente, o `usePlanner` | num store fora do React | num store único fora do React | em átomos, no store do Jotai |
| mais conhecido por | nenhuma dependência | API pequena, pouca cerimônia | convenções, devtools, middleware | pedaços finos e independentes |

As contagens de linhas vêm do `wc -l` acima, com os arquivos de provider e de hook somados ao store de
cada um; o context não precisa de store, porque o estado dele continua sendo o `usePlanner`. Elas
medem cerimônia, não qualidade: as linhas a mais do Redux compram convenções que um time de vinte
pessoas consegue seguir, e as devtools dele no navegador mostram cada ação com o estado antes e
depois.

Como escolher, num app que você começa:

- **Comece com props e context.** O planejador depois desta aula usa context, sem dependência, e nada
  do que ele faz o força.
- **Acrescente o Zustand quando as renderizações do context começarem a custar**, ou quando o estado
  precisar ser lido fora de componentes, como num helper de busca. É o menor passo acima.
- **Use o Redux Toolkit onde ele já está**, e num time grande que quer as convenções dele. Muitas
  bases de código React com estado global o usam.
- **Use o Jotai quando o estado compartilhado for muitos valores pequenos e independentes**, como o
  aberto ou fechado de dezenas de painéis.

## Para que nenhuma delas serve

**Dados que pertencem a um servidor.** Os cursos e as sessões do planejador são cópias do que o
servidor guarda, e manter uma cópia correta quer dizer saber quando ela ficou velha, buscar de novo,
tentar de novo, e mostrar ao usuário o que está carregando: quatro trabalhos que nenhuma das
bibliotecas acima faz por você. A aula 11 leva esses dados para o React Query, que faz exatamente
esses quatro, e o que sobra para o estado global é pouco: qual semana está escolhida, qual curso está
aberto, e na aula 17 até esses vão para o endereço. As três cópias foram apagadas no fim da
transcrição; o planejador fica com o context.
