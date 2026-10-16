---
title: Dado semiestruturado, em que cada registro traz os próprios nomes
version: 1
---

**Dado semiestruturado tem estrutura, mas ninguém a declarou antes: cada registro traz os nomes dos
seus campos ao lado dos valores, e dois registros podem não concordar.** JSON é o formato que você mais
vai encontrar, seguido de XML e YAML. Um documento JSON não é uma bagunça. Ele tem forma, às vezes
bem profunda. O que falta é uma regra, aplicada antes de ele ser guardado, dizendo que todo documento
precisa ter essa forma.

O aplicativo da Roda Livre envia um evento JSON toda vez que uma viagem termina, e o time de dados os
guarda do jeito que chegam, um por linha. Esse arranjo, um documento JSON por linha, se chama **JSON
Lines**, e a aula 6 o compara com os outros formatos. Este programa escreve dois dias desses eventos.
Salve como `events.py`:

```python
# shapes/events.py
import json
import random

random.seed(5)
STATIONS = [f'ST{n:02d}' for n in range(1, 13)]


def ride(n, day, version):
    start = random.choice(STATIONS)
    hour, minute, length = random.randint(6, 21), random.randint(0, 59), random.randint(4, 50)
    battery = random.randint(20, 100)
    event = {'ride_id': f'R{n:06d}', 'app': version,
             'bike': {'id': f'B{random.randint(1, 90):03d}',
                      'battery': battery if version == '4.1' else f'{battery}%'},
             'start': {'station': start, 'at': f'{day}T{hour:02d}:{minute:02d}:00-03:00'},
             'charges': [{'kind': 'unlock', 'cents': 100}]}
    if n % 4 != 0:  # every fourth ride is still going: no end, no bill yet
        event['end'] = {'station': random.choice(STATIONS), 'minutes': length}
        event['charges'].append({'kind': 'minutes', 'cents': 25 * length})
        if length > 30:
            event['charges'].append({'kind': 'overtime', 'cents': 300})
    if random.random() < 0.3:
        event['coupon'] = 'PRIMEIRA'
    if version == '4.2':
        event['helmet'] = random.random() < 0.5
    return event


for day, version, first in (('2025-09-15', '4.1', 101), ('2025-09-16', '4.2', 201)):
    with open(f'rides-{day}.jsonl', 'w') as f:
        for n in range(first, first + 6):
            f.write(json.dumps(ride(n, day, version)) + '\n')
    print('wrote', f'rides-{day}.jsonl', 'app', version)
```

O programa inventa as viagens, a partir de uma semente fixa, então os seus arquivos batem com os de
baixo. Dois detalhes dele voltam mais adiante na aula: o segundo dia é escrito pela versão 4.2 do
aplicativo, e essa versão manda o nível da bateria de outro jeito e acrescenta um campo. Rode, e olhe
o primeiro evento do primeiro dia:

```
ana@lab:~/roda/shapes$ python events.py
wrote rides-2025-09-15.jsonl app 4.1
wrote rides-2025-09-16.jsonl app 4.2
ana@lab:~/roda/shapes$ head -1 rides-2025-09-15.jsonl | python -m json.tool
{
    "ride_id": "R000101",
    "app": "4.1",
    "bike": {
        "id": "B004",
        "battery": 87
    },
    "start": {
        "station": "ST10",
        "at": "2025-09-15T14:47:00-03:00"
    },
    "charges": [
        {
            "kind": "unlock",
            "cents": 100
        },
        {
            "kind": "minutes",
            "cents": 650
        }
    ],
    "end": {
        "station": "ST08",
        "minutes": 26
    }
}
```

## Três coisas que uma tabela não tem

**Aninhamento.** `bike` não é um valor; é um objeto que guarda dois valores próprios. `start` também.
O evento agrupa o que anda junto, e o id da bicicleta é alcançado como `bike.id`, dois nomes de
profundidade. O JSON não tem limite de profundidade.

**Arrays.** `charges` é uma lista, e o número de itens nela muda de viagem para viagem: uma taxa de
desbloqueio, depois os minutos, e uma taxa extra quando a viagem passa de meia hora. Uma célula de
tabela guarda um valor. Uma lista de tamanho variável não tem uma coluna única para onde ir.

**Campos opcionais.** Uma viagem ainda em andamento quando o evento foi enviado não tem `end`. Uma
viagem sem cupom não tem a chave `coupon`, em vez de tê-la vazia. Conte os eventos que têm `end`, e os que têm cupom:

```
ana@lab:~/roda/shapes$ grep -c '"end"' rides-2025-09-15.jsonl
5
ana@lab:~/roda/shapes$ grep -c coupon rides-2025-09-15.jsonl
1
```

Cinco dos seis têm `end`, e um tem cupom. Nada está errado com o sexto. É a viagem `R000104`, que ainda não tinha terminado, e é
exatamente isso o que a falta de `end` quer dizer. Um leitor que supusesse que todo evento tem um
falharia nele, ou, pior, preencheria um valor padrão e relataria como terminada uma viagem que nunca
terminou.

## Schema on read

Sem esquema declarado na porta, o esquema é decidido por **quem lê**. O leitor diz que campos espera, o
que faz quando falta um, e que tipo quer que cada valor tenha. O jargão é **schema on read**, esquema
na leitura, e é o espelho da seção anterior: escrever nunca falha, e cada leitor precisa tomar, e
manter, as próprias decisões.

Duas dessas decisões o JSON impõe a todo leitor. **O JSON não tem tipo de data nem de hora**: os tipos
dele são texto, número, verdadeiro ou falso, nulo, objeto e array. O campo `at` acima é um texto que
parece uma hora, e transformá-lo numa é trabalho do leitor. E o JSON não distingue inteiro de decimal,
então se `battery` é `82` ou `82.0` depende do que quem enviou escreveu.

Essa liberdade é a razão de o dado semiestruturado estar em todo lugar. O time do aplicativo pode
acrescentar um campo numa terça-feira sem pedir nada a ninguém, e todo evento desde então o traz. As
duas próximas seções são o que o time de dados faz com o outro lado dessa liberdade: transformar o
aninhamento em linhas, e perceber quando a forma mudou.
