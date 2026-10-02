---
title: Acione por sintomas, não por causas
version: 1
---

A aula 5 terminou com um alerta chamado `PaymentsFailing`: mais de 2% das cobranças falhando por dois
minutos, severidade `page`. Ele funciona, e é o tipo de alerta que esta aula substitui. **Ele aciona
alguém por uma causa**, uma das muitas coisas que podem dar errado, em vez de pelo que o cliente sente.

A diferença importa nas duas direções:

- **Uma causa pode disparar sem estrago.** Se o `orders` repetisse uma cobrança que falhou, o payments
  poderia falhar 3% das primeiras tentativas enquanto todo checkout dava certo, e o `PaymentsFailing`
  acionaria alguém por nada.
- **Pode haver estrago sem nenhuma causa alertando.** Se o banco fica lento, ou a vitrine dá erro numa
  versão nova, ou a fila enche, o `PaymentsFailing` não diz nada, e precisaria existir um alerta de
  causa para cada um. A lista nunca acaba, e a que falta nela é a que acontece.

Um **sintoma** é o que o cliente vê, e o da loja já está medido: o SLI da aula 15, a fração dos
checkouts que não falharam do nosso lado. Um alerta sobre ele cobre todas as causas de uma vez, as
conhecidas e as que ninguém imaginou, porque não importa por que os checkouts falharam.

Isso deixa as causas com outro trabalho. O payments falhando, um disco enchendo, um alvo que parou de
responder ao scrape: são **tickets**, sinais para alguém olhar no horário de trabalho, e o lugar certo
para começar uma investigação depois de o sintoma ter acionado alguém. Duas severidades bastam para a
maioria das equipes:

| severidade | significa | chega a |
|---|---|---|
| page | clientes estão sendo prejudicados agora, ou vão ser antes do amanhecer | uma pessoa, imediatamente, a qualquer hora |
| ticket | algo precisa de atenção, e pode esperar o horário de trabalho | uma fila lida todo dia |

O teste de um page é uma pergunta sobre a pessoa que o recebe: **há algo que ela precisa fazer agora,
que não pode esperar até de manhã?** Se a resposta é *dar uma olhada, provavelmente*, é um ticket.
