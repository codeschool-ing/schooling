---
title: Compensação não é rollback
version: 1
---

Um rollback faz parecer que a mudança nunca aconteceu. Uma compensação não consegue. O cliente do o-3 foi
cobrado e depois reembolsado, e **os dois são fatos**: o extrato do banco mostra duas linhas, um e-mail
pode ter dito "pagamento recebido", e por alguns segundos o dinheiro sumiu. Uma compensação é uma ação
nova que reverte semanticamente uma antiga, e é projetada com tanto cuidado quanto o próprio passo.

Quatro regras fazem as compensações funcionarem:

- **Uma compensação não pode falhar de vez.** Se o reembolso puder falhar permanentemente, a saga pode
  terminar presa na metade, cobrada e não entregue. Compensações são repetidas até darem certo, então em
  geral são operações que só falham de forma transitória.
- **Uma compensação tem de ser idempotente**, porque vai ser repetida, como a aula 7 disse de todo passo
  repetido. O `release` e o `refund` do laboratório não fazem nada na segunda vez, e nada para um pedido
  que nunca reservou ou pagou.
- **Alguns passos não podem ser compensados**: um e-mail enviado, um pacote entregue à transportadora,
  uma notificação num celular. Ponha-os **por último**, depois do passo que decide o resultado, que a
  literatura chama de **pivô**: depois que ele dá certo, a saga só vai para a frente. No laboratório,
  agendar a entrega é o pivô, e é por isso que não tem compensação.
- **Ordene os passos pela dificuldade de desfazê-los.** Reservar é barato de liberar; cobrar é menos
  barato de reembolsar (tarifas, uma linha no extrato); entregar não se desfaz. O checkout os roda nessa
  ordem, para uma falha desfazer as coisas mais baratas.

Uma compensação também tem um significado de negócio que alguém tem de decidir. Reembolsar não é o único
jeito de compensar uma cobrança: um vale, um reembolso parcial, uma entrega a partir de outro armazém. É
por isso que sagas são tanto uma conversa com quem toca a loja quanto um projeto técnico.
