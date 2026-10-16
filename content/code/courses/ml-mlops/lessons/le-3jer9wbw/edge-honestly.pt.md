---
title: O que a borda custa
version: 1
---

Um arquivo de menos de dois kilobytes que responde sem rede parece o melhor dos três. **A borda leva
três problemas para dentro do aparelho, e nenhum deles fica mais fácil lá.**

**Os atributos.** O `edge.py` os leu de um CSV. Um aparelho de verdade precisa calcular
`recency_days`, `visits_180d` e o resto sozinho, a partir dos dados que guarda, com um código que
não é o `features.py`. É exatamente a segunda implementação contra a qual a lição 5 alertou, agora
rodando num hardware que você não alcança. Um caixa conhece a compra de hoje, não os últimos 180
dias de um membro, então muitos atributos nem podem ser calculados num aparelho, e um modelo que
precisa deles não pode ir para lá.

**As atualizações.** Mover o apelido muda o que o job de lote e o serviço carregam hoje à noite. Um
modelo em dez mil celulares muda quando dez mil pessoas atualizam um aplicativo, então por meses
várias versões respondem ao mesmo tempo, e todo relatório precisa saber qual aparelho rodou qual.

**A evidência.** Um lote grava cada nota numa tabela e um serviço pode registrar cada pedido. As
respostas de um aparelho ficam no aparelho a menos que ele as mande de volta, e o monitoramento da
lição 9 depende dessas respostas e do que aconteceu depois delas.

**Então a borda é escolhida por um motivo que os outros dois não atendem**: falta de rede, um prazo
mais curto que uma ida e volta, ou dados que não podem sair do aparelho. Para o modelo de afastamento
da Ponto Final nenhum desses vale, e o arquivo é uma demonstração e não um plano. Para um caixa que
recomenda um livro a partir do que está na cesta agora, com a conexão da loja fora do ar, seria a
resposta certa.
