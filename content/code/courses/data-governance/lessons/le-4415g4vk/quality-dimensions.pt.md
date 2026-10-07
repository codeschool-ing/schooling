---
title: O que "dado bom" quer dizer
version: 1
---

**Qualidade de dados é adequação a uma finalidade**, e a finalidade importa: um endereço bom o
bastante para um relatório de vendas por estado não é bom o bastante para entregar uma encomenda. Por
isso qualidade não é um número só. É um conjunto de perguntas, em geral chamadas de **dimensões**,
cada uma com o seu teste:

| dimensão | a pergunta | na Ipê |
|---|---|---|
| **validade** | o valor tem o formato e a faixa permitidos? | um e-mail sem `@`; um pedido com data do ano que vem |
| **unicidade** | cada coisa está registrada uma vez? | o mesmo cliente cadastrado duas vezes |
| **completude** | tudo o que deveria estar lá está? | um pedido sem cliente |
| **consistência** | dois lugares que deveriam concordar concordam? | um pagamento diferente do pedido; consentimento antes de a conta existir |
| **atualidade** | está em dia quando é usado? | um estoque da carga de ontem |
| **exatidão** | corresponde ao mundo real? | um endereço de onde o cliente já se mudou |

A última é de outra natureza. As cinco primeiras se medem **dentro do banco**, com uma consulta. A
exatidão precisa de algo de fora — o cliente, o entregador, um documento —, e a maioria dos programas a
mede por amostragem: ligar para cinquenta clientes, comparar. Um relatório de qualidade que diz medir
exatidão só com SQL está medindo uma das outras.

## Por que a governança se importa

Dado ruim é um problema de privacidade além de um problema de negócio, e é por isso que ele está neste
curso e que a LGPD lista a **qualidade dos dados** entre os seus princípios (aula 7): exatos, claros,
relevantes e atualizados. Cada defeito abaixo quebra algo que as aulas anteriores construíram:

- **um cliente duplicado** é uma pessoa cujo pedido de acesso devolve metade dos dados dela, e cujo
  pedido de eliminação deixa a outra metade para trás (aula 7);
- **um e-mail malformado** é um cliente que nunca recebeu o aviso de um incidente (aula 7);
- **um consentimento registrado antes de a conta existir** é um consentimento que ninguém consegue
  provar (aula 7, artigo 8º).

A próxima seção os mede.
