---
title: Camadas, unidades de taxa de transferência e a porta do Kafka
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.** O emulador não
tem camadas, nem limites de vazão, nem conta; aceitou cada clique que esta lição enviou tão rápido
quanto o Python conseguia enviar.

**A camada é escolhida no namespace e decide três coisas: como se compra capacidade, o que o hub pode
guardar e quais recursos existem.** Quatro camadas, e as diferenças documentadas entre elas:

| | Basic | Standard | Premium | Dedicated |
|---|---|---|---|---|
| capacidade comprada em | unidades de taxa de transferência | unidades de taxa de transferência | unidades de processamento | unidades de capacidade, num cluster |
| retenção mais longa | 1 dia | 7 dias | 90 dias | 90 dias |
| grupos de consumidores por hub | 1 | 20 | 100 | 1.000 |
| partições por hub | 32 | 32 | 100 | 1.024 |
| Capture | não | com cobrança à parte | incluído | incluído |
| endpoint Kafka | não | sim | sim | sim |

**O Basic é uma camada para um leitor só**, porque o único grupo de consumidores dele é o
`$Default`: a checagem de fraude e a cópia para o lake da Quitanda não poderiam ler os dois, então o
Basic sai da lista antes de o preço ser mencionado. O Standard é onde fica a maioria das cargas. O
Premium e o Dedicated dão ao namespace recursos que não são divididos com outros clientes, e são as
camadas em que o número de partições pode crescer.

## Uma unidade de taxa de transferência

**No Basic e no Standard, a capacidade é um número de unidades de taxa de transferência (throughput
units) comprado para o namespace inteiro**, dividido por todos os hubs dele. A documentação define uma
unidade como até 1 MB por segundo ou 1.000 eventos por segundo entrando, o que for atingido primeiro,
e até 2 MB por segundo ou 4.096 eventos por segundo saindo. Um namespace que recebe mais do que suas
unidades permitem tem as requisições recusadas como ocupado, e as bibliotecas cliente as repetem; o
produtor fica mais lento em vez de perder eventos, desde que continue repetindo.

Duas consequências saem da definição. **Os leitores contam no limite de saída, uma vez por grupo de
consumidores**: a checagem de fraude e a cópia para o lake leem cada clique, então o hub manda para
fora o dobro do que entrou. E o limite conta eventos além de bytes, então um stream de muitos eventos
minúsculos pode precisar de unidades mesmo movendo pouquíssimos dados.

**O auto-inflate sobe as unidades de um namespace Standard quando o tráfego pede**, até um máximo que
você define, que na declaração da seção anterior é seis. Ele nunca as baixa de novo por conta própria,
e a documentação diz isso: depois de uma noite movimentada o namespace fica no número mais alto, e é
cobrado por ele, até alguém ou alguma coisa baixá-lo. Uma métrica monitorada e um job agendado que
põe o número de volta são os companheiros de costume dessa configuração.

O Premium e o Dedicated não contam unidades desse jeito. Uma unidade de processamento do Premium e
uma unidade de capacidade do Dedicated compram uma parte de recursos isolados, e quanto tráfego uma
delas carrega depende do tamanho dos eventos e do número de leitores, e não de um número fixo por
segundo.

## A porta do Kafka

**Um namespace Standard, Premium ou Dedicated também fala o protocolo do Kafka**, na porta 9093 do
mesmo endereço, então um programa escrito para o Apache Kafka pode enviar para um event hub e ler
dele mudando a configuração e não o código. O event hub faz o papel de um tópico do Kafka, as
partições são as partições do tópico, e os grupos de consumidores são os grupos de consumidores do
Kafka. A Quitanda não tem programas Kafka, e este curso não usa o protocolo: o laboratório publica só
a porta AMQP do emulador, a 5672, então esta lição não faz mais do que apontar a porta; ela importa para uma empresa que leva um
sistema Kafka existente para o Azure sem reescrevê-lo.

## Quanto custariam os cliques da Quitanda

**Os medidores de um namespace Standard são unidades de taxa de transferência por hora, eventos de
entrada por milhão e o Capture por unidade e hora.** Um evento de entrada é contado a cada 64 KB de
dados, então um clique de meio kilobyte é um evento. A conta abaixo usa preços ilustrativos, que são
números redondos para a soma e não os do Azure: 0,03 USD por unidade-hora, 0,03 USD por milhão de
eventos de entrada e 0,10 USD por unidade-hora para o Capture.

O app da Quitanda envia 150 cliques por segundo em média e 600 no pico da noite. O pico são 600
eventos e cerca de 0,3 MB por segundo entrando, abaixo dos 1.000 eventos de uma unidade; os dois
leitores tiram 1.200 eventos por segundo, abaixo dos 4.096 de uma unidade. Uma unidade basta e duas
deixam folga para uma promoção, então o namespace tem duas, com o auto-inflate como teto:

| medidor | quantidade num mês de 30 dias | preço ilustrativo | mês |
|---|---|---|---|
| unidades de taxa de transferência | 2 × 730 horas = 1.460 unidades-hora | 0,03 USD | 43,80 USD |
| eventos de entrada | 150 × 86.400 × 30 = 388,8 milhões | 0,03 USD por milhão | 11,66 USD |
| Capture | 1.460 unidades-hora | 0,10 USD | 146,00 USD |
| | | | **201,46 USD** |

**Com esses números o Capture é a maior parte da conta, e ele é cobrado por unidade**, então cada
unidade que o auto-inflate acrescenta numa noite movimentada é paga duas vezes, uma pelo hub e outra
pelo Capture. Essa é a forma que vale lembrar, sejam quais forem os preços reais: o custo de um
namespace Standard acompanha o número de unidades, e um número de unidades deixado alto depois de um
pico é o desperdício mais comum. A alternativa ao Capture, um leitor seu gravando arquivos, tem conta
própria, uma máquina ou uma function e as escritas no armazenamento, e vale fazer a comparação com
números reais.

Para os preços reais, a tabela de preços do curso, da lição 1, com rede:

```sh
python prices.py "Event Hubs" Standard
```

Ele não foi executado para este curso, como a lição 1 explica. Leia a unidade de cada linha antes do
preço: unidades de taxa de transferência têm preço por hora, e eventos de entrada, por milhão.
