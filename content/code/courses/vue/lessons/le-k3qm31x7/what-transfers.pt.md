---
title: O que você leva junto
version: 1
---

**A maior parte deste curso não foi sobre a sintaxe do Vue, e essa parte vai com você para qualquer um
dos outros três.** A trilha de frontend põe os quatro lado a lado como uma escolha por um motivo, escrito
na própria nota dela: o que você leva de um, componentes, estado, roteamento, o build, é a mesma ideia
quatro vezes.

O que passa quase sem mudança:

- **Componentes com props entrando e eventos saindo.** O `CourseCard` e o `SessionRow` da aula 6 são um
  componente React com props e um callback, um componente Angular com `input()` e `output()`, um
  componente Svelte com `$props()`. A decisão de onde o estado mora, e de que um filho pede ao pai em vez
  de mudar o que recebeu, é a mesma nos quatro.
- **Regras em funções simples.** O `planner.ts` rodaria sem mudança em qualquer um deles, e os sete
  testes dele também. É o código mais portável do planner, e é portável porque não sabe nada do Vue.
- **Estado derivado, não estado copiado.** Os totais foram `computed` aqui, `$derived` no Svelte,
  `computed` no Angular e um `const` recalculado no React, e em nenhum deles foram guardados e mantidos
  em sincronia à mão. A regra da aula 3, derive o que pode ser derivado, é a regra de todos.
- **O build.** Três dos quatro cards foram servidos pelo Vite, e o servidor de desenvolvimento do Angular
  é o Vite debaixo do build próprio dele: a aula 17 vale para todos, `import.meta.env`, arquivos `.env`
  e plugins incluídos.
- **Os testes.** O Vitest roda os testes dos quatro, e o projeto novo do Angular já o lista no seu
  `package.json`. O que a aula 21 disse sobre testar primeiro as funções puras, fingir a rede e o
  relógio, e não testar o framework, vale palavra por palavra.
- **A renderização no servidor.** O SSR, a hidratação e as divergências do Nuxt têm seus gêmeos no Next
  para o React, no SSR próprio do Angular e no SvelteKit, e os dois "hojes" da aula 19 acontecem em todos
  eles pelo mesmo motivo.

O que não passa é a parte de que cada framework se orgulha: a sintaxe do template, o modelo exato do que
roda de novo, os nomes dos hooks do ciclo de vida, a biblioteca de store e o formato de um projeto. Isso
é uma semana de leitura para quem terminou direito um dos quatro cursos, que é o que a nota da trilha
promete.

## Para onde ir daqui

O catálogo tem um curso para cada um dos outros três, `react-ts`, `angular` e `svelte`, cada um
construído em torno do mesmo planner de estudos, para que o segundo framework seja a mesma aplicação em
palavras novas. Depois deste curso a trilha segue para `front-quality`, `front-performance` e
`front-delivery`, que são os mesmos qualquer que seja o framework que o aluno escolheu: acessibilidade e
testes no navegador, o custo de uma página e como um meta-framework a renderiza, e como um build chega
ao seu host. Todos eles têm exemplos que um aluno de Vue agora consegue ler em qualquer um dos quatro.
