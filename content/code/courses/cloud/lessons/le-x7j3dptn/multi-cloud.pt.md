---
title: "Multicloud: dois provedores ao mesmo tempo"
version: 1
---

A híbrida liga um ambiente privado a um público. **Multicloud é usar dois ou mais provedores públicos
ao mesmo tempo**, e as duas coisas se combinam: uma empresa pode ter um datacenter, um provedor e
outro, todos ligados. A palavra é usada para tudo, desde uma equipe experimentando um serviço de um
segundo provedor até uma aplicação feita para rodar em qualquer um dos dois. O caso interessante é o
segundo, e a pergunta é por que alguém faria isso.

## Motivos que se sustentam

Um serviço que só um provedor tem. Um banco de dados gerenciado específico, um serviço de aprendizado
de máquina, um data warehouse que a equipe já conhece: se a melhor ferramenta para um trabalho está no
segundo provedor, usá-la lá é uma escolha de engenharia comum. O resto fica onde estava.

A exigência de um cliente ou de um regulador. O contrato de um cliente grande pode nomear o provedor
onde os dados dele devem ficar, e um produto vendido pelo marketplace de cada provedor precisa rodar
em cada um deles.

Uma aquisição. A empresa comprou outra empresa, e a outra rodava no outro provedor. Muita multicloud
começa assim, e ninguém planejou.

Negociação. Um cliente que conseguiria sair tem com o que barganhar quando os preços entram na
conversa. **O argumento só funciona se a saída for real**, o que quer dizer que o trabalho de
conseguir sair já foi feito e pago.

## O motivo fraco: resiliência por padrão

"Se o nosso provedor cair, fazemos failover para o outro." Parece o seguro óbvio, e é o motivo mais
caro da lista. Para funcionar, cada parte da aplicação precisa rodar nos dois provedores, os dados
precisam ser copiados continuamente entre eles — saindo de um provedor ao preço de saída para a
internet, todo mês — e o failover precisa ser testado com frequência suficiente para funcionar no dia.
Um failover sem teste é um plano para descobrir durante a queda.

Uma segunda região do mesmo provedor protege contra a perda de uma região com **um conjunto de
ferramentas, um sistema de identidade e uma conta**. O que um segundo provedor acrescenta a isso é
proteção contra o provedor inteiro cair de uma vez, e se esse risco vale o preço é uma pergunta para
responder com números, não por padrão. A lição 9 mostra o que envolve uma segunda região.

## O que custa, mesmo quando o motivo é bom

O primeiro custo é **o mínimo denominador comum**. Uma aplicação que precisa rodar nos dois só pode
usar o que os dois oferecem de forma compatível: máquinas virtuais, armazenamento de objetos, um motor
de banco de dados que os dois hospedam. Os serviços gerenciados de cada provedor — muitas vezes o
motivo de estar numa nuvem — são abandonados ou construídos duas vezes, uma por provedor.

Dois de todo o resto vêm em seguida:

- dois sistemas de identidade, com dois modelos de usuários, papéis e políticas que diferem nos
  detalhes que importam (a lição 7 mostra um);
- duas redes, ligadas pelo mesmo tipo de emenda de uma híbrida, e pagando saída de dados dos dois
  lados;
- duas contas, em dois formatos, conciliadas por alguém todo mês;
- dois conjuntos de habilidades, e um plantão que conheça os dois.

Nada disso é motivo para nunca fazer. É o preço, e **o motivo precisa ser maior que o preço**. Para a
maioria das equipes, na maior parte do tempo, um provedor bem usado é a posição mais forte.
