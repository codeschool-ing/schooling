---
title: Um plano de rastreamento é um contrato
version: 1
---

Eventos são escritos por desenvolvedores, em muitos lugares, ao longo de anos, e nada no navegador
impede uma versão nova de chamar um evento de `addToCart` onde a antiga dizia `add_to_cart`. Todo funil
montado sobre o nome antigo para de contar essa etapa, em silêncio. A defesa é um **plano de
rastreamento**: a lista dos eventos que a empresa combinou mandar, com o que cada um significa e que
propriedades carrega, escrita antes do código.

Um plano faz duas coisas. É documentação, então o analista sabe o que `checkout` quer dizer. E pode ser
**checado**: cada evento que chega é comparado com o plano, e um que não está nele é uma violação.

A versão do Segment se chama **Protocols**. Um tracking plan é ligado a uma fonte, todo evento é
validado contra ele, e uma divergência é uma violação. A comparação é estrita: a documentação diz que o
nome precisa bater exatamente, maiúsculas e espaços incluídos. Para eventos fora do plano, uma fonte pode
ser configurada para **bloqueá-los**, de modo que nunca cheguem a um destino, e para propriedades fora do
plano, para **omiti-las**. O Protocols é vendido como um adicional do plano Business do Segment.

Bloquear é a configuração forte, e a documentação do Segment dá o aviso que vem com ela: um evento
bloqueado que não é repassado a outro lugar é descartado de vez. A ordem segura é **observar as violações
primeiro, corrigi-las, e só então bloquear**, porque no primeiro dia em que um plano bloqueia alguma
coisa ele costuma bloquear algo que ninguém sabia que estava sendo mandado.

Você não precisa do Protocols para ter um plano de rastreamento. Ele é uma tabela, e a checagem é uma
consulta, que é o que a próxima seção monta sobre os eventos da Lantern.
