---
title: Fluxo, um consumidor que lembra o seu offset
version: 1
---

**Um processador de fluxo lê um log em que só se acrescenta, um evento depois do outro, e anota até onde
já leu.** Essa anotação, o **offset**, é quase tudo o que faz dele um processador de fluxo, e não um
programa que lê um arquivo.

O log é a estrutura por baixo. Os eventos são escritos no fim dele na ordem em que chegam e nunca mais
são alterados, então cada evento tem uma posição fixa: o primeiro está no offset 0, o seguinte no 1, e
assim por diante. Quem lê não retira eventos. Lê a partir de uma posição, e outro leitor pode ler os
mesmos eventos a partir de outra posição, porque nada some por ter sido lido. O `docks.jsonl` já tem
esse formato: um evento por linha, na ordem de chegada, então o número de uma linha é o offset dela.

**O Apache Kafka é o log desse tipo mais conhecido**, e quem lê dele se chama consumidor (*consumer*).
`streaming` é o curso que constrói com ele. Aqui um programa curto faz o mesmo trabalho sobre o arquivo.
Salve-o como `stream/consumer.py`:

```schooling-example
{"language": "python", "file": "stream/consumer.py", "parts": [
{"code": "# stream/consumer.py\nimport json\nimport sys\nfrom collections import Counter\n\nhow_many = int(sys.argv[1])                      # events to read on this run\ncrash = '--crash' in sys.argv\n", "note": "Quantos eventos ler nesta execução, e o `--crash`, que a seção sobre garantias de entrega usa. Por enquanto, deixe de fora."},
{"code": "\n\ndef load(path, empty):\n    try:\n        with open(path) as f:\n            return json.load(f)\n    except FileNotFoundError:\n        return empty\n", "note": "O `load` lê um arquivo JSON, ou devolve `empty` quando o arquivo ainda não existe, que é o caso da primeiríssima execução."},
{"code": "\n\noffset = load('offset.txt', 0)                   # where the last run stopped\nrides = Counter(load('rides.json', {}))\nwith open('docks.jsonl') as f:\n    batch = f.readlines()[offset:offset + how_many]\n", "note": "As duas coisas que sobrevivem entre execuções: o offset, de onde começar a ler, e a contagem até agora. `readlines()[offset:offset + how_many]` lê a partir dessa posição. Um log de verdade pula direto para uma posição sem ler tudo o que vem antes."},
{"code": "for line in batch:\n    e = json.loads(line)\n    if e['kind'] == 'undock':\n        rides[e['station']] += 1\n", "note": "O trabalho: mais uma viagem para a estação de cada `undock`."},
{"code": "with open('rides.json', 'w') as f:               # 1. write the result\n    json.dump(rides, f)\nif crash:\n    sys.exit('crashed before committing the offset')\nwith open('offset.txt', 'w') as f:               # 2. commit the offset\n    json.dump(offset + len(batch), f)\n", "note": "Depois, duas escritas, nesta ordem: primeiro o resultado, depois o offset. O offset gravado é a posição do próximo evento a ler. É entre as duas escritas que o `--crash` para o programa."},
{"code": "if batch:\n    print(f'read offsets {offset} to {offset + len(batch) - 1};', 'rides so far:', sum(rides.values()))\nelse:\n    print(f'nothing new at offset {offset}')\n", "note": "O que a execução leu, e a contagem até agora."}
]}
```

O programa lê uma quantidade de eventos, trezentos de cada vez aqui, e para. Um consumidor de verdade
nunca para: quando chega ao fim do log ele espera, e lê o próximo evento no instante em que ele é
acrescentado. Parar a cada execução é o que deixa você olhar o offset entre uma execução e outra:

```
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 300 to 599; rides so far: 311
ana@lab:~/roda/stream$ cat offset.txt
600
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 600 to 719; rides so far: 360
ana@lab:~/roda/stream$ python consumer.py 300
nothing new at offset 720
```

Depois de duas execuções o offset é 600, que é a posição do próximo evento a ler, e não a do último
lido. A terceira execução lê os 120 restantes e a quarta não encontra nada novo. Nesse ponto a contagem
é 360, três manhãs de 120 viagens, o mesmo total que o job em lote encontrou.

## Reiniciar é ler a partir do offset

Cada execução desse programa é um reinício. Ela começa sem nada na memória, lê do disco o offset e a
contagem acumulada, e continua exatamente de onde a execução anterior parou. Um consumidor em produção
é reiniciado o tempo todo, para implantar uma versão nova ou porque a máquina em que rodava sumiu, e
**o offset gravado é o que transforma um reinício numa pausa, e não num recomeço do zero**.

A mesma posição permite outras duas coisas. O consumidor pode **voltar**: com o offset em 0, todos os
eventos são lidos de novo, e é assim que um fluxo é reprocessado depois que um bug é corrigido. E um
segundo consumidor, com o seu próprio offset, pode ler o mesmo log para outro fim: o mapa ao vivo das
docas, e o alerta que manda uma van a uma estação vazia, cada um no seu ritmo e sem que um saiba do
outro.

A resposta difere da de um job em lote num ponto que importa. **Depois de cada execução, a contagem é a
contagem até agora.** Ela nunca é "as viagens de segunda", porque o consumidor não tem como saber se a
segunda acabou. A próxima seção mostra por que essa pergunta é mais difícil do que parece.
