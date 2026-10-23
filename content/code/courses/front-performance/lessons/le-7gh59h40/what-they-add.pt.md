---
title: O que um meta-framework acrescenta
version: 1
---

**Um meta-framework é a metade servidor da aula 1, escrita uma vez para todo mundo, em volta de um
framework de interface.** O do React é o Next.js, o do Vue é o Nuxt e o do Svelte é o SvelteKit. O
Angular não tem um produto à parte com nome próprio: a sua renderização no servidor é o
`@angular/ssr`, mantido pelo time do Angular e ligado com uma opção quando o projeto é criado, e
faz o mesmo trabalho. Esta aula chama os quatro de meta-frameworks, na falta de palavra melhor.

Você fez um dos quatro frameworks antes deste curso. **Você não precisa dos outros três para
acompanhar esta aula**, e nada aqui supõe qual foi: cada seção mostra as mesmas duas páginas do
planner num deles, brevemente, e a comparação fica nas seções em volta. Leia com atenção a que
você conhece e as outras pela forma.

## O que a aula 1 fez à mão

Tudo o que um meta-framework faz, o planner já fazia em poucas linhas. A tabela é o mapa de um
para o outro:

| na aula 1 | o que fazia | o que um meta-framework dá em troca |
|---|---|---|
| `page(plan, path)` | decidia pelo endereço qual página desenhar | um **roteador**, preenchido a partir de arquivos numa pasta ou de uma lista de rotas |
| `server.ts` | desenhava a página a cada requisição e servia os arquivos | um **servidor de produção**, construído para você, ou um conjunto de arquivos estáticos |
| `mount` e o seu tratador de links | assumia no navegador, desenhava a próxima página sem pedir ao servidor | **hidratação** e **navegação no cliente**, ligadas por padrão |
| `fetch("/courses.json")` e o `readFile` do servidor | carregavam os dados, uma vez em cada lugar | um **loader**: uma função que roda no servidor para uma rota, cujo resultado chega ao navegador com a página |
| `npm run build` | juntava o script | um build que também decide, por rota, se renderiza agora, no build ou no navegador |

Vêm mais duas coisas com eles, de que o planner nunca precisou: um servidor de desenvolvimento que
recarrega as duas metades enquanto você edita, e convenções para tudo em volta de uma página, como
o seu `<title>`, uma página para um endereço que não existe, uma página de erro, e um layout
compartilhado por várias rotas.

## Quanto custam

Eles não são de graça, e vale dizer o preço antes das quatro seções que vêm:

- **JavaScript.** Cada um manda ao navegador o seu framework de interface e o seu roteador, em cada
  página que hidrata. A seção "A mesma página, de quatro jeitos" pesa isso numa página.
- **Um servidor para manter**, a não ser que toda página seja construída antes. Um processo Node
  que precisa ficar no ar, ser atualizado e ser vigiado.
- **As suas próprias regras.** Onde o código roda, qual arquivo é do servidor e qual é do navegador,
  o que pode ir para cache e por quanto tempo: cada um responde de um jeito, e as respostas mudam
  entre versões maiores. O Next.js 16, a versão desta aula, imprime um aviso nos seus próprios
  arquivos dizendo que as suas APIs diferem das de versões antigas, e diferem.

**O que eles compram é tudo o que está na coluna da esquerda feito corretamente para um app de
qualquer tamanho**, inclusive as partes de que a aula 1 escapou: um endereço que não existe, uma
rota com parâmetro, dados de que uma página precisa antes de poder renderizar, e uma página que
renderiza no servidor para alguns endereços e é construída antes para outros.
