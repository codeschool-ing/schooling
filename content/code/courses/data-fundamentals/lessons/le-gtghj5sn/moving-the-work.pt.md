---
title: Levar o trabalho até os dados
version: 1
---

**Numa rede, mandar o programa é barato e mandar os dados é caro, então o processamento distribuído
manda o cálculo para as máquinas que já guardam os dados.** Esse princípio se chama **localidade dos
dados**. Uma contagem de viagens por estação, sobre dados espalhados por três máquinas, não começa
copiando todas as viagens para um lugar só. Cada máquina conta o que guarda, e só as contagens
viajam.

## O shuffle

A localidade acaba quando a pergunta agrupa por uma chave diferente daquela pela qual os dados estão
particionados. Viagens guardadas pelo id da viagem, contadas por estação: as viagens da ST05 estão nas
três máquinas, e em algum lugar as contagens da ST05 precisam se encontrar. Redistribuir os dados
entre as máquinas para que tudo com a mesma chave acabe num lugar só se chama **shuffle**. Em geral
é o passo mais caro de um trabalho distribuído, porque é o passo que atravessa a rede.

O programa abaixo guarda 30.000 viagens em três nós por hash do id da viagem, e as conta por estação
de dois jeitos. O plano A manda cada viagem para o nó responsável pela estação dela. O plano B conta
em cada nó primeiro e manda só essas contagens parciais. Salve como `shuffle.py`:

```schooling-example
{"language": "python", "file": "spread/shuffle.py", "parts": [
{"code": "# spread/shuffle.py\nimport hashlib\nimport random\nfrom collections import Counter\n\nrandom.seed(4)\nSTATIONS = [f\"ST{i:02d}\" for i in range(1, 13)]\nrides = [(f\"R{i:06d}\", random.choice(STATIONS)) for i in range(1, 30001)]\n\n\n", "note": "Trinta mil viagens desta vez, sem estação concorrida."},
{"code": "def node_of(key, n=3):\n    return int(hashlib.md5(key.encode()).hexdigest(), 16) % n\n\n\n", "note": "Um mesmo hash decide duas coisas: qual nó guarda uma viagem, pelo id dela, e qual nó conta uma estação, pelo id da estação."},
{"code": "# the rides are stored on three nodes, spread by hash of ride id\nstored = [[ride for ride in rides if node_of(ride[0]) == n] for n in range(3)]\nprint(\"rides stored per node:\", [len(s) for s in stored])\n\n", "note": "As viagens estão onde o armazenamento as pôs, pelo id da viagem. É a chave errada para a pergunta, que é por estação."},
{"code": "# plan A: send every ride to the node that owns its station, and count there\nsent_a = sum(node_of(station) != n for n in range(3) for _, station in stored[n])\n\n", "note": "O plano A manda pela rede cada viagem cuja estação é contada em outro nó."},
{"code": "# plan B: count on each node first, then send one partial count per station\npartial = [Counter(station for _, station in stored[n]) for n in range(3)]\nsent_b = sum(node_of(station) != n for n in range(3) for station in partial[n])\n\n", "note": "O plano B conta em cada nó primeiro, então o que viaja é no máximo uma contagem parcial por estação por nó."},
{"code": "total = sum(partial, Counter())\nprint(\"records sent over the network, plan A:\", sent_a)\nprint(\"records sent over the network, plan B:\", sent_b)\nprint(\"same answer either way:\", total == Counter(s for _, s in rides), total.most_common(2))\n", "note": "Somar as contagens parciais dá a contagem completa; o programa confere isso contra a contagem direta de todas as viagens."}
]}
```

```
ana@lab:~/roda/spread$ python shuffle.py
rides stored per node: [9937, 9897, 10166]
records sent over the network, plan A: 19958
records sent over the network, plan B: 24
same answer either way: True [('ST12', 2606), ('ST05', 2570)]
```

O plano A mandou 19.958 viagens pela rede, cerca de duas em cada três, porque uma viagem só fica onde
está quando o nó que a guarda por acaso é o nó que conta a estação dela. O plano B mandou 24
registros: cada um dos três nós tinha uma contagem parcial para cada uma das doze estações, 36 no
total, e as 12 que já estavam no nó certo não viajaram. Os dois deram a mesma resposta.

**Contar antes é possível porque uma contagem pode ser somada em pedaços.** Uma soma, um mínimo e um
máximo também podem. Uma mediana não: a mediana de três medianas não é a mediana de todas as
viagens, então um trabalho que quer uma precisa juntar os valores. Quais operações se combinam em
pedaços é boa parte do motivo de algumas consultas distribuídas serem rápidas e outras não.

## Os nomes que você vai encontrar

O **MapReduce**, descrito pelo Google em 2004, tornou esse formato famoso: um passo de *map* roda em
cada máquina sobre os dados que ela guarda, um shuffle agrupa os resultados por chave, e um passo de
*reduce* combina cada grupo. O Hadoop foi a implementação de código aberto. O **Spark** veio depois,
guarda os resultados intermediários em memória em vez de gravá-los em disco entre os passos, e é o
que `bigdata` ensina, com shuffles, desbalanceamento e tudo. Um data warehouse na nuvem faz o mesmo
por baixo de uma consulta escrita em SQL. Nenhum deles é ensinado aqui. O que você deve conseguir é
olhar para uma pergunta, ver se ela agrupa pela chave pela qual os dados estão particionados, e saber
que, se não agrupa, alguma coisa está para atravessar a rede.
