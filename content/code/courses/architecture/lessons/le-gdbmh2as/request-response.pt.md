---
title: Requisição e resposta
version: 1
---

Comunicação **síncrona** é o estilo que todo mundo aprende primeiro: quem chama manda uma requisição e
espera, sem fazer mais nada naquele caminho, até a resposta chegar. Uma chamada HTTP é síncrona a não
ser que se faça algo para ela ser diferente. Uma chamada a um banco também, e também era cada chamada de
função dentro do monólito da aula 1.

É o padrão certo por um bom motivo. O código se lê em ordem, a resposta está ali na linha seguinte, e um
erro chega onde a chamada foi feita, sem nada para correlacionar depois. **Quando quem chama precisa da
resposta para continuar**, um preço para mostrar ou um sim ou não num pagamento, síncrono é
simplesmente o formato do problema.

## O que isso amarra

O custo é o **acoplamento temporal**: para a chamada dar certo, os dois lados precisam estar de pé, e
respondendo, no mesmo momento. Quem chama pega emprestadas a disponibilidade e a velocidade de quem é
chamado pelo tempo da chamada.

| se o serviço que você chama está | então você está |
| --- | --- |
| lento | lento, pelo menos na mesma medida |
| fora do ar | fora do ar, para toda requisição que precisava dele, a não ser que tenha uma alternativa |
| sobrecarregado | esperando, segurando uma thread ou uma conexão enquanto espera |

A loja da aula 2 mostrou a segunda linha: com o serviço de estoque parado, o catálogo respondeu `503`. A
terceira linha é a perigosa, porque as threads paradas esperando também são um recurso, e a aula 12
mostra uma dependência lenta esgotando todas elas.

## Síncrono não quer dizer bloqueante, exatamente

Um programa pode fazer uma chamada síncrona sem bloquear uma thread, usando um laço de eventos, `async`
e `await`, ou futures: a thread faz outro trabalho enquanto a requisição está no ar. Isso muda quantas
chamadas um processo consegue ter esperando ao mesmo tempo. **Não muda o acoplamento**: a requisição
continua sem poder terminar até o outro lado responder. Neste curso "síncrono" quer dizer o formato da
conversa, uma requisição que precisa da resposta agora, seja qual for a cara do código que espera por
ela.
