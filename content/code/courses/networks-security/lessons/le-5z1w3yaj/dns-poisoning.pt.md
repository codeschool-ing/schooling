---
title: Como o cache de um resolvedor é envenenado
version: 1
---

Um **resolvedor** (*resolver*) pergunta nomes a outros servidores em nome dos seus clientes e guarda
cada resposta em um **cache** pelo tempo que o TTL dela permite. Todo cliente do resolvedor passa então
a receber a resposta guardada sem que ninguém pergunte de novo. É isso que torna o DNS rápido, e é
isso que torna tão valiosa uma resposta falsa no cache: **envenene um cache e todo cliente daquele
resolvedor é mandado para o endereço errado até a entrada expirar**, sem que nenhum deles tenha feito
nada de errado.

A entrada clássica é uma corrida. O DNS viaja quase sempre sobre UDP, que não tem handshake, e o
resolvedor aceita a primeira resposta que combina com a sua pergunta. Um atacante que consegue
adivinhar quando o resolvedor vai perguntar envia respostas forjadas, com o endereço do servidor
verdadeiro como origem, torcendo para que uma chegue primeiro e combine. Para combinar, a resposta
precisa trazer o mesmo **ID de transação** (*transaction ID*), um número de 16 bits, e chegar à
**porta de origem** certa da pergunta.

As defesas se somam, e vale conhecer cada uma pelo que ela faz:

| defesa | o que ela tira de quem forja |
|---|---|
| IDs de transação aleatórios | 1 chance em 65.536 por resposta forjada, em vez de um número previsível |
| portas de origem aleatórias | multiplica o chute pelo número de portas; resolvedores modernos fazem isso por padrão |
| não ser um resolvedor aberto | desconhecidos não conseguem fazer o resolvedor perguntar na hora que escolherem (a aula 6) |
| filtragem de endereço de origem | respostas forjadas que dizem vir do endereço do servidor verdadeiro ficam mais difíceis de enviar (esta aula) |
| **DNSSEC** | a resposta é assinada; uma forjada falha na verificação, seja qual for o momento |

As quatro primeiras tornam a falsificação improvável. **Só o DNSSEC a torna inútil**, porque ele
confere a própria resposta em vez do jeito como ela chegou. As duas próximas seções o colocam no
laboratório.

O envenenamento também tem formas mais discretas, contra as quais nenhum protocolo defende: um
roteador doméstico comprometido que distribui um resolvedor malicioso, ou um arquivo `hosts` alterado
em uma máquina. As duas são locais, e as duas aparecem como uma máquina resolvendo diferente das
vizinhas.
