---
title: Garantias de entrega, e uma queda no lugar errado
version: 1
---

**Um consumidor faz duas coisas para cada lote de eventos: faz o trabalho e grava o offset. Qual das
duas vem primeiro decide quanto custa uma queda entre elas.** A garantia que um sistema oferece é o nome
desse custo.

- *No máximo uma vez* (at most once): grave o offset primeiro, depois faça o trabalho. Uma queda no
  meio perde o lote: ao reiniciar, o offset diz que ele foi lido, então ninguém o lê de novo. Nada é
  contado duas vezes, e algumas coisas nunca são contadas.
- *Pelo menos uma vez* (at least once): faça o trabalho primeiro, depois grave. Uma queda no meio
  repete o lote: ao reiniciar, o offset ainda aponta para antes dele, então ele é lido e processado de
  novo. Nada se perde, e algumas coisas são contadas duas vezes.
- *Exatamente uma vez* (exactly once) é o que todo mundo quer e o que nenhuma rede consegue prometer
  sobre a *entrega*, porque quem envia e não recebe resposta não sabe distinguir uma mensagem perdida de
  uma resposta perdida. O que um sistema consegue prometer é que o *efeito* aconteça uma vez, e isso
  costuma se chamar **efetivamente uma vez** (*effectively once*).

O `consumer.py` da seção de fluxo é um consumidor pelo menos uma vez: ele grava `rides.json` primeiro e
`offset.txt` depois. A opção `--crash` o para entre os dois, que é onde uma queda de energia, uma
implantação ou um processo morto por falta de memória pode cair a qualquer momento. Comece de um estado
vazio e derrube a segunda execução:

```
ana@lab:~/roda/stream$ rm offset.txt rides.json
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python consumer.py 300 --crash
crashed before committing the offset
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 300 to 599; rides so far: 466
ana@lab:~/roda/stream$ python consumer.py 300
read offsets 600 to 719; rides so far: 515
```

A execução que caiu já tinha gravado a sua contagem, 311, e nunca registrou que tinha lido os offsets de
300 a 599. O reinício os leu de novo e somou as 155 viagens deles uma segunda vez. O consumidor terminou
com 515 viagens em manhãs que tiveram 360, e **toda execução depois da queda imprimiu uma linha
normal**. É a viagem contada duas vezes da aula 1 de novo, na escala de um fluxo.

## Efetivamente uma vez: tornar a repetição inofensiva

Há duas saídas, e as duas mudam a escrita, não a entrega. Uma é fazer do resultado e do offset uma
escrita só, para que uma queda deixe os dois ou nenhum: uma transação de banco de dados comporta os
dois, e alguns processadores de fluxo guardam os offsets dentro do mesmo snapshot do seu estado por esse
motivo. A outra é tornar o trabalho **idempotente**, para que fazê-lo duas vezes deixe o mesmo resultado
que fazê-lo uma.

As viagens são fáceis de tornar idempotentes, porque todo evento tem um id. Em vez de somar um a um
contador, o consumidor registra *quais* eventos já contou, e um evento processado duas vezes é a mesma
chave escrita duas vezes. Salve `stream/keyed.py`, que difere do `consumer.py` no estado que guarda e
nos seus próprios dois arquivos:

```python
# stream/keyed.py
import json
import sys

how_many = int(sys.argv[1])
crash = '--crash' in sys.argv


def load(path, empty):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return empty


offset = load('keyed-offset.txt', 0)
rides = load('keyed-rides.json', {})             # event id -> station
with open('docks.jsonl') as f:
    batch = f.readlines()[offset:offset + how_many]
for line in batch:
    e = json.loads(line)
    if e['kind'] == 'undock':
        rides[e['id']] = e['station']            # the same event twice is one key
with open('keyed-rides.json', 'w') as f:
    json.dump(rides, f)
if crash:
    sys.exit('crashed before committing the offset')
with open('keyed-offset.txt', 'w') as f:
    json.dump(offset + len(batch), f)
if batch:
    print(f'read offsets {offset} to {offset + len(batch) - 1};', 'rides so far:', len(rides))
else:
    print(f'nothing new at offset {offset}')
```

A mesma queda, no mesmo lugar:

```
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 0 to 299; rides so far: 156
ana@lab:~/roda/stream$ python keyed.py 300 --crash
crashed before committing the offset
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 300 to 599; rides so far: 311
ana@lab:~/roda/stream$ python keyed.py 300
read offsets 600 to 719; rides so far: 360
```

O lote ainda foi entregue duas vezes, porque o consumidor continua sendo pelo menos uma vez. A segunda
entrega não mudou nada, e a contagem termina em 360.

**A idempotência se paga em memória.** O `keyed-rides.json` guarda todo id de viagem que já viu, e num
fluxo que nunca termina ele nunca pararia de crescer. Uma deduplicação de verdade guarda os ids só
enquanto uma duplicata ainda pode chegar, que é o atraso permitido da seção anterior, perguntado de novo
sobre outra coisa. A aula 9 encontra a mesma ideia onde ela custa mais caro, numa requisição repetida
através de uma rede.
