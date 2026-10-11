---
title: Quanto: linhas por dia vezes bytes por linha
version: 1
---

**Volume é uma estimativa que dá para fazer antes de coletar uma única linha: linhas por dia, vezes
bytes por linha, vezes os dias que o dado fica guardado.** As linhas vêm do negócio e são fáceis de
acertar. Os bytes são onde as estimativas erram, porque as pessoas os contam de cabeça em vez de
medir.

## Linhas por dia

As linhas são aritmética sobre fatos que alguém na Roda Livre já sabe. As doze estações têm 150 docas
no total, de dez na menor a dezoito na Rodoferroviária, e cada doca informa uma vez por minuto se está
com uma bicicleta. São 150 leituras por minuto, e um dia tem 1.440 minutos.

## Bytes por linha, medidos

**Os bytes são medidos numa amostra, escrita no formato em que o dado vai mesmo ser guardado.** Uma
leitura tem cinco valores: uma estação, uma doca, um horário, se a doca está ocupada e a tensão da
bateria. Contando os caracteres dos valores, dá uns quarenta bytes, e é desse palpite que se deve
desconfiar.

Todos os programas desta aula ficam no diretório da aula, `~/roda/collect`. Crie-o e entre nele:

```sh
mkdir -p ~/roda/collect && cd ~/roda/collect
```

Este programa escreve uma hora de leituras em JSON Lines, uma leitura por linha, que é como o servidor
dos sensores as envia. Depois mede o arquivo, divide, e multiplica pelos números do negócio: as 150
docas de hoje, e as 246 que vão existir quando as oito estações novas de doze docas cada, previstas
para o ano que vem, estiverem abertas. Salve como `collect/volume.py`:

```python
# collect/volume.py
import json
import os
import random

random.seed(7)
DOCKS = {"ST01": 15, "ST02": 12, "ST03": 10, "ST04": 12, "ST05": 18, "ST06": 12,
         "ST07": 15, "ST08": 10, "ST09": 12, "ST10": 12, "ST11": 12, "ST12": 10}

# a sample: one hour of readings, every dock reporting once a minute
with open("sample.jsonl", "w") as f:
    for minute in range(60):
        for station, n in DOCKS.items():
            for dock in range(1, n + 1):
                f.write(json.dumps({
                    "station": station,
                    "dock": dock,
                    "at": f"2025-09-15T08:{minute:02d}:00-03:00",
                    "occupied": random.random() < 0.6,
                    "voltage": round(random.uniform(11.8, 12.6), 2),
                }) + "\n")

rows = 60 * sum(DOCKS.values())
size = os.path.getsize("sample.jsonl")
per_row = size / rows
print(f"sample: {rows} rows, {size} bytes, {per_row:.1f} bytes a row")

# the estimate: rows a day times bytes a row, today and with the new stations
for docks in (sum(DOCKS.values()), sum(DOCKS.values()) + 8 * 12):
    a_day = docks * 24 * 60
    print(f"{docks} docks: {a_day} rows a day, {a_day * per_row / 1e6:.1f} MB a day, "
          f"{a_day * per_row * 365 / 1e9:.1f} GB a year")
```

```
ana@lab:~/roda/collect$ python volume.py
sample: 9000 rows, 923206 bytes, 102.6 bytes a row
150 docks: 216000 rows a day, 22.2 MB a day, 8.1 GB a year
246 docks: 354240 rows a day, 36.3 MB a day, 13.3 GB a year
```

A linha medida tem mais que o dobro do palpite. A primeira linha da amostra diz por quê:

```
ana@lab:~/roda/collect$ head -1 sample.jsonl
{"station": "ST01", "dock": 1, "at": "2025-09-15T08:00:00-03:00", "occupied": true, "voltage": 11.92}
```

Os cinco valores somam 39 caracteres. O resto são os nomes das chaves, as aspas, os dois-pontos e os
espaços, **escritos de novo em toda linha**, porque cada linha de JSON Lines carrega os próprios nomes
de campo. Um formato que guarda os nomes uma vez por arquivo, e os valores de uma coluna juntos, escreve
bem menos bytes para as mesmas leituras; a aula 6 mede exatamente isso. A estimativa só é tão boa quanto
a amostra, e é por isso que a amostra é escrita no formato que vai ser guardado, e não no mais fácil de
imaginar.

## Crescimento, e o pico

**Uma estimativa feita para hoje está errada no ano que vem, então ela é feita para o crescimento que
o negócio já planejou.** As oito estações novas aumentam o volume diário em 64% sem um único cliente a
mais. Pergunte a quem planeja o negócio, não aos dados: nada nas leituras de hoje prevê uma estação que
ainda não foi construída.

O volume de um dia também é uma média. Os sensores informam no mesmo ritmo às quatro da manhã e às seis
da tarde, então o pico deles é a média. As viagens são o contrário: a maioria acontece em dois horários
de pico, e um sistema dimensionado pela média diária de viagens fica pequeno duas vezes por dia. Quando o
dado é processado à medida que chega, que é a aula 8, o pico é o número que importa.

## O que o número decide

Com 8,1 GB por ano, os sensores das docas cabem num notebook. Vale saber isso cedo, porque o volume é a
resposta que escolhe as ferramentas: alguns gigabytes por ano pedem uma máquina e a biblioteca padrão,
e a aula 9 trata do que muda quando é preciso mais de uma. Anote a estimativa com as premissas — 150
docas, uma leitura por minuto, 102,6 bytes por linha em JSON Lines — para que, no dia em que ela se
mostrar errada, todo mundo veja qual premissa mudou.
