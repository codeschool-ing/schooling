---
title: Um failover que você não executou
version: 1
---

O failover de um serviço gerenciado é o da lição 16, executado pelo provedor: um standby em outro
data center, algo que decide que o primário se foi, uma promoção, e o **nome DNS** ao qual a aplicação
se conecta reapontado para o novo primário. Cada peça tem uma lição neste curso:

- **Leva tempo**, tipicamente um ou dois minutos entre a falha e um nome que volte a responder,
  porque a detecção espera um timeout passar (o `ttl` da lição 16) e as respostas de DNS ficam em
  cache (lição 19). A documentação do provedor dá um número; o honesto é o que você mede.
- **Toda conexão cai.** A aplicação reconecta e tenta de novo, exatamente como o `orders.sh` da lição
  19 precisou fazer, e um driver ou um pool (lição 18) que guarda o endereço antigo continua se
  conectando a um servidor que não é o primário.
- **O standby em geral é síncrono dentro da região**, então um failover não perde nenhum commit
  confirmado, e os commits pagam a ida e volta (lição 12). Confira se o seu é, porque "alta
  disponibilidade" numa página de produto não diz.
- **As réplicas de leitura são separadas** do standby que assume no failover, e assíncronas: as
  leituras desatualizadas da lição 13 valem do mesmo jeito.

A maioria dos provedores deixa você **forçar um failover**, muitas vezes como uma opção de um reboot.
É o ensaio da lição 23 nos servidores de outra pessoa, e o único jeito de saber o que a sua aplicação
faz durante esses minutos antes que um failover de verdade mostre.
