---
title: Uma lista de verificação para uma origem nova
version: 1
---

**Antes de uma origem nova ser copiada pela primeira vez, cada pergunta desta aula ganha uma resposta
por escrito.** Uma resposta escrita pode ser conferida contra o que acontece no mês seguinte; uma
resposta que só existiu numa reunião, não. Aqui está a lista, preenchida para o pedido de Caio, as
leituras dos sensores das docas.

| pergunta | a resposta para os sensores das docas |
|---|---|
| **para que serve?** | o modelo de demanda de Caio, retreinado no domingo à noite; o relatório de Marta sobre estações vazias |
| quem é dono da origem? | o time que opera o servidor dos sensores; ele guarda dois dias |
| linhas por dia | 216.000 hoje; 354.240 com as oito estações novas |
| bytes por linha | 102,6 em JSON Lines, medidos numa amostra de uma hora |
| um ano, guardado | 8,1 GB hoje, 13,3 GB com as estações novas |
| quão fresco? | o dia anterior, completo, até as 07:00; ninguém aqui precisa do minuto |
| pull ou push? | pull, uma vez por noite; o servidor não oferece outra coisa |
| completa ou incremental? | incremental pelo horário da leitura, com sobreposição para leituras que chegam atrasadas |
| verificações do arquivo | as colunas esperadas; uma contagem de leituras por estação |
| verificações de cada linha | uma estação e uma doca conhecidas; um horário dentro do dia; uma tensão entre limites combinados com o dono |
| para onde vão as rejeitadas | um arquivo de quarentena por dia, lido por Davi na segunda de manhã |
| reconciliada contra | a contagem do próprio servidor de leituras por dia |
| quanto custa | o armazenamento é pequeno; qualquer painel sobre ela lê um dia, não o ano |
| dado pessoal? | nenhum: uma leitura descreve uma doca, não uma pessoa |
| por quanto tempo fica guardada | o bruto para sempre; o resto decidido com Caio quando o modelo existir |

Três respostas merecem um segundo olhar. **A primeira linha vem primeiro** porque todas as outras
respostas dependem dela: "quão fresco" não quer dizer nada até alguém dizer para quê. Os dois dias do
dono são um prazo, já que um pipeline que fica parado num feriado prolongado perde dados que ninguém
consegue coletar de novo. E a linha do dado pessoal é curta aqui, mas é a mais longa para as viagens, que
carregam um cliente, um lugar e um horário; a mesma lista para a tabela de viagens terminaria com os três
jeitos de precisar de menos da seção 09.

## A lista é uma conversa

A maioria dessas respostas não vem do dado. Vem de Caio, de Marta, do time dos sensores e da conta, e a
lista é o jeito de garantir que cada um deles foi perguntado. Várias delas pertencem ao contrato de dados
com o dono da origem que a aula 4 descreveu: as colunas, as contagens, os limites, e o que acontece
quando uma entrega quebra um deles.

Duas respostas desta lista são sobre tempo — quão fresco, e quando uma leitura conta como atrasada. A
aula 8 leva as duas adiante: o que muda quando o dado é processado à medida que chega em vez de uma vez
por noite, e o que fazer com um evento que aparece depois que a janela dele já fechou.
