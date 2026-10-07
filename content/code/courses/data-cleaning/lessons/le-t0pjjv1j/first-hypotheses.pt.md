---
title: Primeiras hipóteses
version: 1
---

A exploração termina em hipóteses, não em conclusões. Uma **hipótese** é uma afirmação precisa o
bastante para estar errada, escrita junto com o que mostraria que ela está errada. As descobertas
desta aula dão três, e cada uma está escrita assim:

| Hipótese | Vem de | Seria refutada por |
|---|---|---|
| O crescimento de dezembro nas famílias é compra de Natal, não clientes novos | famílias em dezembro um terço acima de novembro | o crescimento de dezembro vir de clientes cujo primeiro pedido é em dezembro |
| A onda da noite são pessoas pedindo depois do trabalho, para o dia seguinte | pedidos com pico às 19 horas | pedidos da noite com entrega marcada para a mesma noite |
| Pedidos maiores custam mais sobretudo por terem mais itens, não itens mais caros | Spearman 0,644, Pearson 0,427 sem as empresas | o preço mediano por item subir tanto quanto o número de itens |

Três hábitos fazem uma lista assim ser útil e não decorativa.

- **Cada uma nomeia os dados que poderiam refutá-la.** A primeira pode ser conferida hoje, com a
  tabela `per_customer` da aula 12 e a coluna `first`. A segunda não: os arquivos não têm horário
  de entrega agendado, então a hipótese também diz que dado teria de ser coletado.
- **Nenhuma é informada como descoberta.** "Dezembro é compra de Natal" pode muito bem ser verdade,
  e até a verificação rodar, um relatório diz que dezembro foi um terço maior e que o Natal é a
  explicação mais provável, não que o Natal causou isso.
- **As surpresas entram na lista primeiro.** O preço do açúcar e os pedidos corporativos pareciam
  fatos do negócio à primeira vista e eram defeitos dos dados. Uma lista de hipóteses que só tem o
  que todo mundo esperava não explorou nada.

Vale lembrar a aula 3 aqui também. O NPS da pesquisa parecia uma medida de satisfação, e era uma
medida de quem escolheu responder. **Toda hipótese construída sobre uma coluna com uma lacuna
conhecida carrega a lacuna junto**, e dizer isso pertence à mesma linha da tabela.
