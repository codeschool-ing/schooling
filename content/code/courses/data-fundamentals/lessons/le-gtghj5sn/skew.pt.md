---
title: Desbalanceamento: uma chave com quase todo o trabalho
version: 1
---

**Um hash espalha as chaves por igual. Ele não espalha o trabalho por igual, porque toda linha com a
mesma chave vai para a mesma partição.** Se uma estação tem um terço das viagens, a partição que
guarda essa estação tem pelo menos um terço das viagens, seja qual for a função de hash. Esse
desequilíbrio se chama **skew**, ou desbalanceamento, e a chave que o causa é uma **chave quente**.

Todo programa desta aula fica num diretório próprio, no laboratório da aula 1. Crie-o e entre nele:

```sh
mkdir -p ~/roda/spread && cd ~/roda/spread
```

O programa abaixo cria um domingo de viagens em que a Rua XV, ST02, recebe uma feira de rua, e
particiona essas viagens de três jeitos em quatro partições. Salve como `skew.py`:

```schooling-example
{"language": "python", "file": "spread/skew.py", "parts": [
{"code": "# spread/skew.py\nimport hashlib\nimport random\nfrom collections import Counter\n\nrandom.seed(9)\nSTATIONS = [f\"ST{i:02d}\" for i in range(1, 13)]\nWEIGHTS = [1] * 12\nWEIGHTS[1] = 6                       # ST02, Rua XV: a street fair on Sunday\nrides = [(f\"R{i:06d}\", random.choices(STATIONS, WEIGHTS)[0]) for i in range(1, 10001)]\n", "note": "Dez mil viagens por doze estações. A Rua XV recebe seis vezes o peso de qualquer outra estação, que é o que uma feira de rua num domingo faz com ela. A semente faz toda execução sortear as mesmas viagens."},
{"code": "\n\ndef by_hash(key, n=4):\n    return int(hashlib.md5(key.encode()).hexdigest(), 16) % n\n\n", "note": "Particionamento por hash. O MD5 transforma a chave num número grande que parece aleatório, e o resto da divisão por quatro é a partição. O `hash()` do próprio Python não serve, porque para um texto ele muda de uma execução do Python para a outra, e um particionador precisa dar a mesma resposta em toda máquina, todo dia."},
{"code": "\ndef by_range(station, n=4):\n    return (int(station[2:]) - 1) * n // 12      # ST01-ST03 to 0, ST04-ST06 to 1 ...\n\n", "note": "Particionamento por intervalo. O número da estação decide: ST01 a ST03 vão para a partição 0, ST04 a ST06 para a partição 1, e assim por diante."},
{"code": "\ndef show(title, partition_of):\n    counts = Counter(partition_of(ride_id, station) for ride_id, station in rides)\n    print(f\"{title:22}\", \" \".join(f\"{counts[p]:5}\" for p in range(4)))\n\n", "note": "Conta quantas viagens cada partição guardaria sob uma regra, uma coluna por partição."},
{"code": "\nprint(f\"{'partition':22}\", \" \".join(f\"{p:5}\" for p in range(4)))\nshow(\"range of station\", lambda ride_id, station: by_range(station))\nshow(\"hash of station\", lambda ride_id, station: by_hash(station))\nspread = Counter(by_hash(station) for station in STATIONS)\nprint(f\"{'stations, by hash':22}\", \" \".join(f\"{spread[p]:5}\" for p in range(4)))\nshow(\"hash of ride id\", lambda ride_id, station: by_hash(ride_id))\nprint(\"busiest:\", Counter(station for _, station in rides).most_common(2))\n", "note": "Três regras, sobre as mesmas viagens: por intervalo de estações, por hash da estação e por hash do id da viagem. A linha do meio conta estações em vez de viagens, e a última dá o nome das duas estações mais movimentadas."}
]}
```

```
ana@lab:~/roda/spread$ python skew.py
partition                  0     1     2     3
range of station        4724  1805  1763  1708
hash of station          544  2336  2390  4730
stations, by hash          1     4     4     3
hash of ride id         2573  2473  2508  2446
busiest: [('ST02', 3553), ('ST01', 622)]
```

Leia uma linha de cada vez.

**Por intervalo de estação**, a partição 0 tem ST01 a ST03, e a ST02 está entre elas: 4724 das
10.000 viagens, enquanto as outras três partições ficam entre 1708 e 1805 cada uma.

**Por hash da estação**, a estação quente mudou de lugar e o problema foi junto. A ST02 agora divide a
partição 3 com outras duas estações, e a partição 3 tem 4730 viagens. A linha de baixo mostra um
segundo efeito, mais discreto: doze chaves são poucas para um hash repartir por igual, e a partição 0
recebeu uma única estação e 544 viagens. Um hash é uniforme sobre milhares de chaves, não sobre doze.

**Por hash do id da viagem**, as quatro partições ficam entre 2446 e 2573. Há dez mil ids de viagem
diferentes e cada um é uma única linha, então nenhuma chave consegue ficar quente.

A última linha diz por quê: a ST02 teve 3553 viagens, e a segunda estação mais movimentada teve 622.

## Por que uma divisão desigual custa tempo

Quatro máquinas trabalhando em paralelo terminam quando a mais lenta termina. Uma divisão igual de
10.000 viagens dá 2500 para cada; particionando por estação, a partição mais cheia tem 4730. Se o
tempo de uma máquina acompanha as linhas que ela guarda, o trabalho inteiro leva quase o dobro do
necessário, e três das quatro máquinas passam o final dele esperando.

## O que se faz a respeito

O id da viagem resolveu o equilíbrio, e mudou o custo de lugar. Particionado pelo id da viagem, a
pergunta "quantas viagens saíram da Rua XV?" precisa consultar as quatro partições e somar as
respostas, quando particionado por estação ela consultava uma. **Uma carga equilibrada e uma pergunta
barata sobre uma estação puxam para lados opostos**, e escolher a chave é escolher entre as duas.

O outro remédio comum ataca só a chave quente. O **salting** a divide em várias chaves — `ST02#0`,
`ST02#1`, `ST02#2`, `ST02#3`, com o sufixo tirado do número da viagem — para que as linhas dela caiam
em quatro partições em vez de uma, e toda pergunta sobre a ST02 lê essas quatro e soma. O
desbalanceamento num join ou num group-by num cluster é uma aula inteira de `bigdata`; aqui basta
reconhecê-lo, e saber que um hash não faz ele sumir.
