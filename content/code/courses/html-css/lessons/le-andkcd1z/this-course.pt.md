---
title: O que é este curso, e como ele mede uma página
version: 2
---

Este curso ensina a escrever as duas linguagens de que toda página web é feita. **HTML diz o que o conteúdo é**: isto é um título, isto é uma lista, isto é um campo de formulário com aquele rótulo. **CSS diz como ele aparece e onde fica**: esta cor, tanto de espaço, estes três cartões lado a lado numa tela larga e empilhados no celular. São treze aulas, nessa ordem: quatro de HTML, depois nove de CSS, terminando com Tailwind, um framework que escreve o CSS por você quando você já sabe que CSS ele deveria escrever.

O curso pressupõe `web-fundamentals` e se apoia em duas aulas dele em particular. A aula 10 de lá explica como o navegador transforma uma resposta em pixels: o DOM, o CSSOM, o layout e a pintura. A aula 11 de lá são as ferramentas de desenvolvedor do navegador, e o painel Elements é a ferramenta que você mais vai usar neste curso. Quando este curso precisa de uma dessas ideias, ele a nomeia e segue em frente, sem ensiná-la de novo.

## O site que você vai construir

Todo exemplo do curso pertence a um mesmo site pequeno: a **Andorinha Books**, um sebo em Pinheiros, São Paulo. Ela é inventada, e foi escolhida porque um sebo precisa de um pouco de tudo: uma página inicial, uma lista de eventos, um formulário para encomendar um livro, uma tabela de horários, fotos das estantes e um layout que funcione no celular de quem está parado na frente da loja. Cada aula acrescenta a parte que ensina.

As páginas são arquivos que você escreve, numa pasta do seu próprio computador, e a próxima seção monta essa pasta. Cada aula mostra inteira cada página que usa, na seção que a usa. Você abre uma página com um clique duplo: o navegador lê um arquivo HTML do seu disco exatamente como lê um vindo de um servidor, e isso é tudo de que este curso precisa.

## Como este curso mede uma página

O resultado de HTML e CSS é uma **imagem**, e uma imagem é difícil de citar. "O cartão é mais estreito que o do lado" é uma descrição; não é algo que se possa conferir. Por isso toda afirmação deste curso sobre o que o navegador fez é uma medição, impressa por um programinha chamado `probe`.

O `probe` abre uma página no Chromium, o motor que está dentro do Chrome e do Edge, e faz a ele as perguntas que o painel Elements responde quando você clica em alguma coisa: onde está esta caixa, qual a largura dela, que cor esta regra acabou dando, o que um leitor de tela anunciaria aqui. Ele imprime as respostas como texto. Aqui ele abre a primeira página desta aula e imprime o título e o que a tecnologia assistiva enxerga nela:

```
ana@laptop:~/site$ probe skeleton.html title tree
title: "Andorinha Books"
- heading "Andorinha Books" [level=1]
- paragraph: Second-hand books in Pinheiros, São Paulo.
```

**O `probe` é o instrumento de medida do curso, não algo que você instala.** São algumas centenas de linhas de JavaScript que dirigem o Chromium pelo Playwright, uma biblioteca de testes de navegador. Ele existe para que os números destas aulas sejam números que um navegador imprimiu, e não números que alguém esperava. Você não digita as linhas que começam com `probe`: o que importa é a saída. Tudo o que ele imprime você lê no DevTools, na sua própria página, clicando no elemento e olhando a aba **Computed** e o diagrama de caixa ao lado, e o curso diz onde olhar a cada vez. As linhas que não começam com `probe`, o validador da seção 13 e o Tailwind da aula 13, são comandos que você mesmo roda.

## As perguntas são sobre prever o navegador

Uma página se confere olhando para ela, e nada nesta plataforma consegue olhar uma página que você escreveu e dizer se está certa. Por isso as perguntas destas aulas pedem a outra metade da habilidade: **dado este HTML e este CSS, o que o navegador vai fazer?** Qual será a largura daquela caixa, qual regra vence, qual elemento fica por cima naquele ponto. Essas têm uma resposta certa, e é a resposta que o `probe` imprimiu.

Não é um exercício menor. A diferença entre quem escreve CSS tentando coisas até ficar bom e quem escreve de propósito é exatamente esta: a segunda pessoa prevê o resultado antes de recarregar. A construção você faz no seu próprio navegador, a partir das páginas que cada aula mostra.

## Onde este curso fica na sua trilha

::: track frontend
Na sua trilha este é o primeiro curso pago, logo depois de `web-fundamentals`, e tudo o que vem depois desenha dentro do que ele ensina. `javascript` vem em seguida e passa boa parte do tempo mudando o DOM que este curso constrói; o framework que você escolher na bifurcação gera HTML e prende CSS nele. As aulas 8, 9 e 11, sobre Flexbox, Grid e responsividade, são as que uma entrevista de front-end vai testar.
:::

::: track backend
Na sua trilha este curso vem antes de você escolher uma linguagem de servidor, e de propósito. Quem trabalha no back-end envia HTML, renderiza templates e lê relatos de bug que dizem "a página está quebrada", então precisa saber o que é uma página correta. As aulas 1 a 4, de HTML, são as que mais importam para o seu trabalho; a aula 3, de formulários, é exatamente o que chega ao seu servidor como requisição.
:::

::: track qa
Na sua trilha você chega a este curso depois de `manual-testing`, e o valor dele para você é saber o que está olhando. Quem testa e sabe ler o HTML de um formulário, a árvore de acessibilidade de uma página e a regra de CSS que escondeu um botão escreve um relato de bug com que o desenvolvimento consegue trabalhar. `web-automation` vem depois de `javascript` e encontra cada elemento pelos seletores que a aula 5 ensina.
:::

::: track *
As aulas 1 a 4 são de HTML e as aulas 5 a 13 são de CSS. Se você só tem tempo para parte delas, as aulas 2, 5, 8 e 11 são as que todo curso de front-end posterior pressupõe: estrutura semântica, como uma regra vence, Flexbox e responsividade.
:::
