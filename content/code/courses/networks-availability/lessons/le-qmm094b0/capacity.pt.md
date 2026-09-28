---
title: Capacidade é tempo de ar, não número de clientes
version: 1
---

O datasheet de um ponto de acesso diz que ele suporta algumas centenas de clientes, e o número é
verdadeiro no sentido estreito de que ele mantém essa quantidade associada. **O que acaba primeiro é o
tempo de ar.** Um canal leva uma transmissão por vez, como a aula 6 mostrou, então todo cliente nele
espera a vez, e a vez de um cliente dura o tempo que os dados dele levam para ir na taxa dele.

É por isso que o cliente grudento da primeira seção importa para todo mundo. O mesmo download, em três
taxas de dados:

```schooling-example
{"language": "python", "file": "airtime.py", "parts": [{"code": "payload_bits = 10 * 8_000_000        # a 10 MB download", "note": "Um download, o mesmo para todos os clientes: dez megabytes são oitenta milhões de bits."}, {"code": "rates = [(\"near the AP\", 400), (\"mid-cell\", 150), (\"sticky, far away\", 12)]\nfor where, mbps in rates:\n    seconds = payload_bits / (mbps * 1_000_000)\n    print(f\"{where:18} {mbps:4} Mbit/s  {seconds:6.2f} s of airtime\")", "note": "Três clientes em três taxas de dados. As taxas são ilustrativas e tratadas como a velocidade a que os dados de fato andam, deixando de fora o custo do protocolo que a aula 6 contou, o que alonga cada linha e não muda nada na comparação."}, {"code": "near = payload_bits / 400e6\nfar = payload_bits / 12e6\nprint(f\"the far client holds the channel {far / near:.0f} times as long\")", "note": "A razão é o que importa. Enquanto o cliente distante transmite, ninguém mais naquele canal transmite."}], "output": "near the AP         400 Mbit/s    0.20 s of airtime\nmid-cell            150 Mbit/s    0.53 s of airtime\nsticky, far away     12 Mbit/s    6.67 s of airtime\nthe far client holds the channel 33 times as long"}
```

**O cliente distante segura o canal 33 vezes mais tempo** que um cliente ao lado do AP pelos mesmos dez
megabytes, e durante 6,67 segundos ninguém mais naquele canal transmite. Uma sala cheia de clientes em
taxas boas pode ser mais rápida que uma com poucos clientes em taxas ruins.

## Planejar pela demanda

Então um projeto começa pelo que os clientes vão fazer, não por quantos são:

1. Conte os aparelhos que estarão ativos ao mesmo tempo em cada área, não as pessoas.
2. Multiplique pelo que cada um precisa: uma videochamada, alguns Mbit/s em cada sentido; um leitor de
   código de barras, quase nada além de um roaming curto.
3. Divida pelo que um rádio entrega de verdade nas taxas que as suas células permitem, bem abaixo da taxa
   anunciada (aula 6), e deixe folga.

Os guias de planejamento dos fabricantes costumam citar algumas dezenas de clientes ativos por rádio para
uso de escritório, e menos para voz ou vídeo. **Esses são pontos de partida para conferir contra o passo
3, não limites.** Um auditório com 200 notebooks precisa de vários rádios em canais diferentes, postos de
modo que cada um ouça só a sua parte da sala, e o conselho da aula 7 vale aqui: mais APs com menos
potência, não menos APs gritando.

## Band steering

A maioria dos clientes consegue usar 2,4 GHz e 5 GHz, e 5 GHz tem mais canais e menos interferência
(aulas 6 e 7). Deixados à vontade, alguns clientes escolhem 2,4 GHz porque o sinal ali é mais forte à
distância. O **band steering** empurra clientes de banda dupla para 5 GHz: o AP, tendo ouvido o cliente
fazer probe nas duas bandas, demora ou se cala ao responder em 2,4 GHz, ou manda uma sugestão 802.11v
depois que ele entrou.

**Não é um mecanismo padronizado**, e a versão de cada fabricante se comporta de um jeito. Ajustado de
forma agressiva demais, ele atrasa a primeira conexão de um cliente, que fica esperando resposta na banda
em que perguntou. A medida de que funciona é onde os clientes de banda dupla vão parar, e a lista de
clientes da controladora mostra isso.
