---
title: Heurísticas
version: 1
---

A imagem comum de um bom explorador é a de alguém com um talento, um faro para defeitos que o resto
de nós não tem. A experiência faz diferença, mas quase tudo o que ela dá a um testador pode ser
escrito e emprestado a quem ainda não a tem. **Uma heurística é uma regra prática, falível, para
chegar a um teste**: não promete um defeito, e não é uma lista para completar. É um jeito de se fazer
uma pergunta em que você não teria pensado, no momento em que as ideias acabaram.

## SFDPOT: seis coisas que um produto é

O modelo de James Bach para as partes de um produto dá seis palavras para percorrer, lembradas em
inglês como **San Francisco Depot**: Structure, Function, Data, Platform, Operations, Time, ou
estrutura, função, dados, plataforma, operação e tempo. Cada uma é um jeito diferente de olhar a
mesma aplicação, e cada uma sugere testes que as outras não sugerem. Para o boxoffice:

| | o que pergunta | uma pergunta para o boxoffice |
|---|---|---|
| **S**tructure, estrutura | do que o produto é feito | que páginas existem sem nenhum link levando a elas? O `/health` é uma; há outras? |
| **F**unction, função | o que ele faz | o que cada uma das quatro ações faz, a partir de cada estado em que um pedido pode estar? |
| **D**ata, dados | o que ele recebe e guarda | o que acontece com um número de pedido que não existe, ou com uma quantidade zero? |
| **P**latform, plataforma | de que ele depende | que navegador, que largura de tela, que Python? A aula 7 fez essa pergunta |
| **O**perations, operação | como as pessoas o usam de fato | como é um sábado lotado, com fila no balcão e alguém pedindo reembolso na porta? |
| **T**ime, tempo | o que muda com o passar do tempo | o que muda quando um espetáculo se aproxima, e depois que ele começou? |

A ordem das letras é só um jeito de lembrá-las. Uma sessão em geral começa pela mais próxima da
missão e passa para outra quando a primeira para de render perguntas. A missão da Ana é sobre
pedidos, então Function vem primeiro, e **Time é a letra mais fácil de esquecer**, porque um testador
na mesa testa num único momento do dia.

## Passeios

O livro *Exploratory Software Testing*, de James Whittaker, descreve a exploração como turismo: um
passeio é um jeito de andar por uma aplicação com um tema, como um visitante escolheria um roteiro
de museu ou uma caminhada pelas ruas de trás. Três dos passeios dele, e o que cada um seria no
boxoffice:

- **o passeio do dinheiro** visita as funcionalidades pelas quais o cliente paga, aquelas com que o
  produto é vendido. Para uma bilheteria isso é reservar um espetáculo e pagar, de ponta a ponta, do
  jeito que um cliente faria;
- **o passeio dos becos** visita as funcionalidades que quase ninguém usa, porque quase ninguém as
  testou também: a caixa de saída, o `/health`, uma página de pedido aberta digitando o número dele
  no endereço;
- **o passeio dos pontos turísticos** escolhe as funcionalidades principais e as visita em ordens
  diferentes: cadastrar, depois reservar, depois pagar; reservar primeiro e cadastrar depois; pagar,
  depois cancelar, depois reservar de novo. Defeitos que dependem do que aconteceu antes só aparecem
  quando a ordem muda.

## Menores, para quando você empaca

Algumas heurísticas são uma pergunta só, curta o bastante para ficar num cartão ao lado do teclado:

- **Cachinhos Dourados**, da folha de heurísticas de teste que Hendrickson escreveu com James Lyndsay
  e Dale Emery: para toda entrada, tente uma pequena demais, uma grande demais e uma na medida. Para
  ingressos, 0, 7 e 6;
- **a mesma coisa duas vezes**: pagar um pedido já pago, cancelar um já cancelado, apertar Book duas
  vezes rápido;
- **desfazer**: o que quer que a aplicação deixe você fazer, tente desfazer, e veja se tudo o que
  aquilo mudou volta junto;
- **outra porta**: o que quer que o navegador deixe você fazer, mande a mesma requisição com o curl,
  inclusive valores que a página nunca oferece. Os botões da página não são as únicas coisas que
  alcançam o servidor.

Nenhuma delas encontra um defeito sozinha. Elas impedem que a sessão seja gasta repetindo os três
testes que vieram à cabeça primeiro. A seção 05 desta aula usa duas delas de
propósito, Function e Time do SFDPOT, e uma das menores, a outra porta.
