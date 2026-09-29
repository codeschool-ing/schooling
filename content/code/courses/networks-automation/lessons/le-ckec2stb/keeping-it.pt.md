---
title: O que fazer com um stream
version: 1
---

Uma inscrição produz valores para sempre, e um script que os imprime é uma demonstração, não um
sistema. **Em produção, um coletor se inscreve e grava cada valor num banco de dados de séries
temporais**, e dashboards e alertas leem de lá. O próprio `gnmic` pode rodar como esse coletor,
com saídas para Prometheus, InfluxDB e Kafka, e o Telegraf tem uma entrada gNMI que faz o mesmo.
Nenhum deles roda no laboratório; o que todos precisam acertar são as mesmas poucas coisas que os
scripts desta aula já tocaram.

- **O timestamp vem do equipamento.** O `rate.py` dividiu pelo tempo entre duas amostras como o
  `edge1` o mediu. Um coletor que usa a própria hora de chegada transforma cada soluço da rede num
  pico no gráfico.
- **Contadores são cumulativos, e recomeçam.** Um contador volta a zero quando o equipamento
  reinicia ou a interface é recriada, e um contador antigo de 32 bits dá a volta depois de cerca de
  4,3 bilhões. Uma taxa calculada através do reinício é negativa; um coletor precisa detectá-la e
  pular esse intervalo em vez de desenhá-lo.
- **Espere o `sync-response`** antes de confiar no estado atual. Antes dele, o coletor tem só parte
  do quadro.
- **Uma inscrição morre com a sua conexão.** O gRPC roda sobre uma única conexão TCP de longa
  duração, e quando o equipamento reinicia ou um firewall derruba a conexão por timeout, o stream
  simplesmente para. O coletor precisa perceber o silêncio e se inscrever de novo, e um stream
  ON_CHANGE que parou em silêncio parece exatamente uma rede onde nada está mudando.

**Amostre o que você põe em gráfico; inscreva-se por mudança no que gera alerta.** Contadores a
cada dez ou trinta segundos bastam para gráficos de capacidade. Oper-status, adjacências de
roteamento e qualquer outra coisa pela qual uma pessoa deva ser acordada pertencem a uma inscrição
ON_CHANGE, onde a mensagem chega quando o evento chega.
