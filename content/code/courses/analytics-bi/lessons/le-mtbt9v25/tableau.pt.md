---
title: Tableau
version: 1
---

O **Tableau** é a ferramenta que fez da tela visual o jeito padrão de explorar dados. Faz parte da
Salesforce desde 2019. O programa de desktop roda no Windows e no macOS, e os produtos de servidor
publicam pastas de trabalho num navegador.

## Como ele pensa

A ideia central do Tableau é que um gráfico é uma **consulta desenhada**. Você arrasta um campo para
*Columns*, outro para *Rows*, um terceiro para *Colour*, e o Tableau escreve a consulta, roda e desenha
o resultado de uma vez. O motor que faz essa tradução se chama VizQL. Todo campo é de um de dois tipos:

- uma **dimensão**, pela qual o Tableau agrupa — região, segmento, mês;
- uma **medida**, que ele agrega — receita líquida, quantidade — com `SUM` se ninguém disser outra
  coisa.

É a divisão da aula 2 de novo, aplicada pela ferramenta a toda coluna no momento em que ela lê uma
tabela. Ela adivinha pelo tipo da coluna, e um palpite é uma definição que ninguém escolheu: um
`order_id` guardado como número chega como medida, e um gráfico que soma ids de pedido é o primeiro
engano da maioria das pessoas.

## Ao vivo ou extrato

Uma fonte de dados do Tableau ou consulta o banco toda vez — uma conexão **ao vivo** — ou copia os
dados para um **extrato**, um arquivo no formato do próprio Tableau, atualizado num horário. É a
escolha que a aula 4 chamou de DirectQuery e Import, com outros nomes, com a mesma troca entre frescor e
velocidade.

## Onde as definições dele moram

Um campo calculado no Tableau — o equivalente de uma medida — mora na **pasta de trabalho** onde foi
escrito, a não ser que tenha sido definido numa **fonte de dados publicada** que muitas pastas de
trabalho compartilham. Uma empresa que deixa cada analista construir a partir de tabelas cruas chega às
nove receitas da aula 3; uma que publica uma fonte de dados sobre a camada chega a uma. A ferramenta
permite as duas coisas.

## Experimentando

O Tableau vende licenças por pessoa, com preços diferentes para quem constrói e para quem só lê. O
**Tableau Public** é uma edição gratuita com uma condição importante: o que você constrói é publicado
num perfil público na internet. Serve para um portfólio feito com dados abertos, e é errado para
qualquer coisa que uma empresa não poria num outdoor — inclusive os clientes da Lantern, mesmo
inventados.
