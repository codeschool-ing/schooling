---
title: Um framework que é um compilador
version: 1
---

**O Svelte é um compilador que transforma componentes em JavaScript comum antes de o navegador
vê-los.** React, Vue e Angular mandam uma biblioteca para o navegador, e essa biblioteca lê os seus
componentes enquanto a página roda. O Svelte faz esse trabalho antes, no seu computador, na hora do
build. O que chega ao navegador é código que atualiza a página diretamente, mais um runtime pequeno
de funções auxiliares que esse código chama.

A imagem comum é que um framework é algo que você baixa e chama. O Svelte quebra essa imagem de
propósito. A sintaxe que você escreve, `$state`, `{#each}`, `onclick={…}`, não é JavaScript que um
navegador saiba rodar; é a entrada de um programa que a lê e escreve outra coisa. A seção "O que o
compilador escreve", a penúltima desta aula, mostra o programa que ele escreve para um componente
de seis linhas.

## Os dois nomes que você vai encontrar

**Svelte** é a linguagem de componentes e o seu compilador. Um arquivo `.svelte` guarda um
componente: um `<script>`, um pouco de marcação e um `<style>`. Este curso usa o **Svelte 5.57.2**,
e as aulas 2 a 11 são sobre ele.

**SvelteKit** é o framework construído sobre o Svelte para aplicações inteiras: páginas em
endereços, dados carregados no servidor, formulários que enviam, e um build que produz algo que dá
para publicar. Este curso usa o **SvelteKit 3.1.0**, lançado em outubro de 2026, e as aulas 12 a 19
são sobre ele. Um projeto criado hoje é um projeto SvelteKit mesmo quando você só quer componentes,
então você vai ter o SvelteKit desde esta aula e usar as rotas dele a partir da aula 12.

Os dois rodam sobre o **Vite**, a ferramenta de build que serve o seu projeto enquanto você trabalha
nele e o empacota quando você termina. Você raramente vai chamar o Vite pelo nome; `npm run dev` e
`npm run build` chamam por você.

## Onde este curso fica

Este é um de quatro cursos no mesmo passo da trilha `frontend`. **React com TypeScript, Angular,
Vue e Svelte** ensinam um framework cada, e você faz um deles. Os cursos depois da bifurcação não
supõem nenhum dos quatro, então nada que você deixa de fazer aqui vai ser cobrado depois.

**Os quatro cursos constroem a mesma aplicação**, para que um aluno que troca de curso reconheça
tudo menos o código. É um **planner de estudos**:

- a primeira tela lista os seus cursos, e quantos minutos de estudo cada um tem nesta semana;
- um curso abre nas suas sessões, cada uma com data, duração e uma caixa para marcar como feita;
- um formulário acrescenta uma sessão a um curso;
- o total da semana está sempre na tela, e botões levam à semana anterior ou à seguinte.

Os dados são três cursos e seis sessões em outubro de 2026, num arquivo JSON de umas vinte linhas
que a aula 3 entrega inteiro. Não há serviço externo nem conta em lugar nenhum. A aula 20 olha o
mesmo planner nos outros três frameworks, e é por isso que ela consegue comparar coisas iguais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O planner de estudos que os quatro cursos de framework constroem. À esquerda, a primeira tela: o título Study planner, a semana de 19 de outubro de 2026 com botões para a semana anterior e a seguinte, três cursos com os seus minutos na semana (Linear algebra 150, Spanish 30, Guitar 45) e o total da semana, 225 minutos. Escolher um curso abre a tela da direita: as sessões de Linear algebra, cada uma com data, duração e uma caixa de feito, e um formulário que acrescenta uma sessão com data e número de minutos. Embaixo das duas, um arquivo JSON guarda três cursos e seis sessões.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Study planner</text><text x=\"170\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">‹   Week of 19 Oct 2026   ›</text><rect x=\"36\" y=\"92\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Linear algebra</text><text x=\"292\" y=\"105\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150 min</text><rect x=\"36\" y=\"126\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish</text><text x=\"292\" y=\"139\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30 min</text><rect x=\"36\" y=\"160\" width=\"268\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Guitar</text><text x=\"292\" y=\"173\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45 min</text><line x1=\"36\" y1=\"202\" x2=\"304\" y2=\"202\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"48\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">esta semana</text><text x=\"292\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">225 min</text><line x1=\"304\" y1=\"105\" x2=\"398\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,105.0 390.6,108.1 390.6,101.9\" fill=\"var(--phosphor)\"></polygon><text x=\"351\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">escolher um curso</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Linear algebra</text><rect x=\"416\" y=\"62\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-13</text><text x=\"560\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60 min</text><rect x=\"650\" y=\"68\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"92\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-19</text><text x=\"560\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90 min</text><rect x=\"650\" y=\"98\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"122\" width=\"268\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2026-10-24</text><text x=\"560\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60 min</text><rect x=\"650\" y=\"128\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acrescentar uma sessão</text><rect x=\"416\" y=\"180\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"426\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data</text><rect x=\"534\" y=\"180\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"544\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutos</text><rect x=\"612\" y=\"180\" width=\"72\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Add</text><text x=\"684\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">150 min esta semana</text><rect x=\"170\" y=\"280\" width=\"380\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um arquivo JSON: 3 cursos, 6 sessões, outubro de 2026</text><line x1=\"170\" y1=\"280\" x2=\"120\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><line x1=\"550\" y1=\"280\" x2=\"600\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "As duas telas do planner, e o único arquivo por trás das duas.", "same": ["Add", "Guitar", "Linear algebra", "Spanish", "Study planner"]}
```

## Como o curso funciona

**A aula 1 prepara o seu computador e cria o projeto**, e cada aula depois dela muda esse mesmo
projeto, em `~/planner`. Cada aula mostra inteiro cada arquivo que muda, para você digitar ou
copiar; nada vem de outro lugar além da aula à sua frente. Duas aulas olham em volta mais do que
constroem: a aula 2, o que muda por não haver DOM virtual, e a aula 4, o código Svelte 4, porque
muito dele continua em uso.

Você precisa do conteúdo do curso `javascript`, e do hábito do curso `git` de fazer commits pelo
caminho. TypeScript não é pressuposto: o planner é JavaScript puro até a aula 18 convertê-lo.
