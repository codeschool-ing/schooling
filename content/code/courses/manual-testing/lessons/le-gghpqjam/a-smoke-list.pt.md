---
title: Uma lista de fumaça para o boxoffice
version: 1
---

Uma lista de fumaça costuma ser montada pegando os casos de teste mais importantes e rodando-os
primeiro. Isso produz uma lista lenta demais, que precisa de julgamento para ser lida e que falha por
motivos que nada têm a ver com a versão funcionar. **Uma checagem de fumaça é escolhida por outra
qualidade: a falha dela, sozinha, quer dizer que a versão não vale a pena ser testada**, e um
sucesso é decidido em segundos por alguém que nunca viu o produto.

## O que faz uma boa checagem de fumaça

Cada item da lista precisa cumprir cinco condições:

- toca uma área principal, para que a lista inteira cubra todas;
- segue o caminho principal dessa área, com dados comuns e nada incomum;
- o resultado esperado está escrito e se vê num relance: um título de página, uma linha, um número;
- não depende de nenhuma outra checagem ter passado, a não ser o servidor estar no ar;
- dá a mesma resposta sempre que roda, seja qual for o dia e a hora.

A última condição é fácil de quebrar sem perceber. O boxoffice fecha as reservas de um espetáculo
uma hora antes do início, e The Seagull começa às 20:00 do dia em que a aplicação sobe. Uma checagem
de fumaça que reserva The Seagull passa a tarde toda e falha toda noite depois das 19:00, por um
motivo que não diz nada sobre a versão. **É por isso que a checagem de reserva do boxoffice usa
Hamlet**, a uma semana de distância, que pode ser reservado a qualquer hora.

## As cinco checagens

| checagem | o que ela prova | requisito |
|---|---|---|
| `/health` responde `ok boxoffice` | o servidor está no ar, e qual é a versão | o critério de entrada do plano |
| a página inicial lista os três espetáculos | o catálogo de espetáculos carrega e é desenhado | R1 |
| a página de cadastro carrega | o formulário de cadastro é servido | R2 |
| o membro reserva dois ingressos de Hamlet | um pedido é criado, o coração do produto | R4 |
| a caixa de saída abre | o ponto de parada dos e-mails da versão de teste responde | seção 04 da aula 1 |

Cada uma é a versão mais rasa de uma área inteira. A checagem da página inicial procura três
títulos, e não as datas, os preços ou os lugares, que são casos do R1. A checagem do cadastro
pergunta se o formulário está lá, não se dá para criar uma conta com ele; criar uma exigiria um
endereço novo a cada rodada, e o link de confirmação que vem depois é da aula 22. A checagem de
reserva é o único passo mais fundo da lista, porque reservar é aquilo para que o teatro comprou o
sistema, e uma versão em que nada pode ser reservado não vale uma tarde de casos de desconto.

## O que fica de fora, de propósito

Uma parte igualmente grande do produto fica fora da lista, e cada omissão tem um motivo:

| de fora | por que não é fumaça |
|---|---|
| preços e descontos | muitos casos, com contas a conferir; a tabela de decisão da aula 5 |
| entrada errada | dezenas de valores e julgamento sobre cada mensagem; aula 4 |
| a vida de um pedido | vários passos que dependem uns dos outros; as transições de estado da aula 5 |
| o layout no celular | precisa de um navegador numa largura definida e de uma pessoa olhando; aula 7 |
| o e-mail e o link de confirmação | precisam de uma conta nova e de um segundo passo; aula 22 |

Nenhum deles é menos importante que os cinco da lista. Eles são o assunto do teste que a fumaça
decide se começa, e **um defeito em qualquer um deles torna a versão pior, não intestável**.

## Quão longa é a lista

Para o boxoffice, cinco checagens e uns dois minutos à mão. Um produto maior tem uma lista maior,
dez ou vinte checagens para uma loja na web com busca, carrinho, pagamento e contas, e as mesmas
regras: uma checagem por área, caminho principal, segundos cada. Times que veem a lista de fumaça
se arrastando para cinquenta itens geralmente deixaram casos entrarem, e o remédio é perguntar de
cada item se a falha dele, sozinha, pararia o teste.

A lista fica junto dos casos de teste, sob controle de versão ou na ferramenta de casos que o time
usa, e muda quando o produto muda. Quando chega uma área nova, uma página de avaliações para cada
espetáculo, por exemplo, a pergunta é se o produto ainda vale ser testado com essa área morta. Se
sim, ela não precisa de checagem de fumaça. Se não, ganha uma.
