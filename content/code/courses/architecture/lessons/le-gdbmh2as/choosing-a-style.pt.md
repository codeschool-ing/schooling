---
title: Escolhendo o estilo de uma conversa
version: 1
---

A escolha é feita por conversa, não por sistema. O checkout da Quitanda vai usar os dois, com razão:
pergunta o total ao preço e espera, porque não consegue mostrar ao cliente uma cesta sem ele, e anuncia
`OrderPlaced` e segue, porque o e-mail, os pontos de fidelidade e o depósito podem se atualizar cada um
no seu tempo.

**A pergunta que decide é se quem chama precisa do resultado antes de poder seguir.**

| situação na Quitanda | estilo | por quê |
| --- | --- | --- |
| mostrar o preço da cesta | consulta síncrona | a página não é desenhada sem ele |
| autorizar o cartão no checkout | comando síncrono | o cliente está esperando sim ou não, e um não muda o que acontece depois |
| mandar o e-mail de confirmação | evento assíncrono | ninguém está esperando, e o serviço de e-mail fora do ar não pode parar um pedido |
| mandar o depósito separar o pedido | comando assíncrono, numa fila | o depósito trabalha no seu ritmo, e uma rajada no almoço deve esperar na fila |
| montar o relatório do mês | requisição e resposta assíncronas | lento demais para segurar uma conexão, e alguém quer mesmo o resultado |
| atualizar um índice de busca com um produto novo | evento assíncrono | alguns segundos de atraso até ser buscável não custam nada |

## Três perguntas antes de ir para o assíncrono

1. **O que quem manda diz ao seu próprio chamador?** "Aceito" é a resposta honesta, e a tela precisa ser
   projetada para ela. "O seu pedido está sendo processado" é uma promessa diferente de "o seu pedido
   está confirmado".
2. **O que acontece se a mensagem for entregue duas vezes, ou nenhuma?** Aula 7. Se a resposta é "o
   cartão é cobrado duas vezes", o destinatário precisa ser idempotente antes de qualquer outra coisa.
3. **Por quanto tempo os dois lados podem discordar?** Segundos, para um e-mail. Para um estoque que os
   clientes estão comprando, a aula 9 mostra a discordância na tela, e a aula 8 explica por que ela não
   some com boa vontade.

**Síncrono não é a escolha ingênua e assíncrono não é a avançada.** Cada um é o formato certo para um tipo
diferente de conversa, e boa parte dos problemas em sistemas distribuídos vem de usar um onde a
conversa tem o formato do outro.
