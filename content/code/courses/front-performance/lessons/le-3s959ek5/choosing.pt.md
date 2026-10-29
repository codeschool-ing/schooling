---
title: Escolhendo, uma página de cada vez
version: 1
---

**A escolha é feita por página, perguntando para quem a página é e com que frequência o seu
conteúdo muda.** Fazer a pergunta para o site inteiro produz os dois erros clássicos: um site de
marketing renderizado no navegador, que não mostra nada aos visitantes que ele existe para ganhar,
e uma ferramenta com login renderizada no servidor a cada clique, que paga um servidor por um
trabalho que o navegador do visitante teria feito de graça.

## Quatro perguntas

1. **Alguém vai chegar a esta página por uma busca ou por um link compartilhado?** Então o
   conteúdo dela pertence à primeira resposta: renderize no servidor ou no build.
2. **Ela é igual para todo mundo?** Então pode ser construída uma vez e servida como arquivo, que é
   o assunto da aula 3. Uma página que muda por pessoa tem de ser renderizada por requisição, no
   servidor ou no navegador.
3. **Com que frequência ela muda?** Um conteúdo que muda uma vez por semana pode ser reconstruído
   uma vez por semana. Um conteúdo que muda a cada minuto precisa de renderização por requisição,
   ou de um build que se atualiza sozinho, o que a aula 3 chama de regeneração incremental.
4. **Ela é usada o dia todo, atrás de um login?** Então a primeira carga é paga uma vez e cada
   clique depois dela importa mais. A renderização no cliente, ou a híbrida com a maior parte do
   trabalho no navegador, serve.

## O planner, página por página

| página | chega-se por um link | igual para todo mundo | muda | uma escolha razoável |
|---|---|---|---|---|
| a página inicial, com a lista de cursos | sim | sim, enquanto não houver contas | quando o plano muda | no build, refeita quando os dados mudam |
| a página de um curso | sim | sim, enquanto não houver contas | quando uma sessão é adicionada | no servidor, ou no build com regeneração |
| o formulário que adiciona uma sessão | não, ele faz parte da página do curso | sim | nunca | renderizado com a sua página, posto para funcionar pelo script |

Se o planner ganhasse contas, cada página passaria a mostrar as sessões de uma pessoa, a segunda
coluna viraria "não" do começo ao fim, e o build deixaria de ser opção para qualquer uma delas.
**A escolha segue os dados, não o framework.** Foi por isso que esta aula veio antes dos frameworks:
a aula 2 mostra como cada um deixa você fazer a escolha por rota, e isso só ajuda se você já sabe o
que está escolhendo.

## Duas coisas que não são escolha

Qualquer que seja a escolha, **a página tem de funcionar quando o script atrasa.** Uma página
renderizada no servidor cujos botões não fazem nada por três segundos é uma página que parece
quebrada por três segundos, e a aula 4 é sobre deixar essa janela o mais curta possível. E uma
página renderizada no cliente tem de mostrar *alguma coisa* enquanto espera: uma tela branca vazia
e um quadro com o título e uma linha dizendo que as sessões estão carregando têm a mesma
velocidade, e não são a mesma experiência. A aula 5 dá um número a essa diferença.
