---
title: Qual delas, para qual página
version: 1
---

**As quatro respostas desta aula são quatro pontos de uma mesma linha, de "decidido uma vez, no
build" até "decidido a cada requisição".** Cada passo ao longo dela troca algum custo no build por
algum custo na requisição, e os dados da página decidem em que ponto da linha ela fica.

| | renderizada | errada por no máximo | o servidor faz por requisição | serve para |
|---|---|---|---|---|
| geração estática | no build | até o próximo build | entrega um arquivo | páginas que mudam a cada versão: ajuda, documentação, uma landing page |
| regeneração por idade | no build, depois quando velha e pedida | a idade que você definiu, mais uma requisição | entrega um arquivo; às vezes renderiza um | catálogos, listagens, preços que podem atrasar um pouco |
| regeneração sob demanda | no build, depois quando os dados mudam | o tempo entre a mudança e a chamada | entrega um arquivo; renderiza depois de uma mudança | conteúdo editado por pessoas, que apertam um botão que pode fazer a chamada |
| renderização no servidor | a cada requisição | nunca | renderiza a página | páginas que mudam por pessoa, ou que nunca podem atrasar |

## Três perguntas que posicionam uma página

1. **Ela é igual para todo mundo?** Se não é, é renderização no servidor, ou no cliente, e nada
   desta aula se aplica. Uma cópia em cache da página de uma pessoa servida a outra é um vazamento, e
   a aula 9 mostra o cabeçalho que o impede.
2. **Por quanto tempo ela pode ficar errada?** Zero quer dizer renderização no servidor. Um ciclo de
   versão quer dizer geração estática. Qualquer coisa no meio é regeneração, por idade quando ninguém
   sabe dizer quando os dados mudam, sob demanda quando alguém sabe.
3. **O que muda os dados consegue chamar um endereço?** O salvar de um editor, um webhook de um
   provedor de pagamentos, um job de importação: cada um consegue, e então a revalidação sob demanda
   é exata. Dados que mudam pelas costas do site, como um feed lido do servidor de outra pessoa, só
   podem ser pegos por uma idade.

## O planner, posicionado

A página inicial e as páginas de curso são iguais para todo mundo enquanto o planner não tem contas,
e mudam quando o plano muda. Uma pessoa acrescentando uma sessão é a única coisa que muda o plano, e
o código que salva a sessão poderia fazer a chamada. **A revalidação sob demanda serve ao planner com
exatidão**, com uma idade de uma hora como rede de segurança caso uma chamada se perca. No dia em que
o planner ganhar contas, cada página vira a de uma pessoa, e todas vão para a última linha.

Hospedar um site assim é o assunto da aula 1 de `front-delivery`, que publica um build estático e um
build de servidor em quatro hospedagens. A aula 9 deste curso é a outra metade: os cabeçalhos de
cache que decidem por quanto tempo o navegador e uma CDN guardam o que o servidor entregou.
