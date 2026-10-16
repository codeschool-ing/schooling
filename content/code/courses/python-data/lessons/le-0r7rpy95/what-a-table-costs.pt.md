---
title: Quanto custa uma tabela
version: 1
---

**Um DataFrame vive na memória, e quanta memória depende muito mais dos tipos do que dos valores.**
Uma coluna de números custa oito bytes por linha; uma coluna de texto custa o texto, mais a
contabilidade do Python para cada string. Antes de uma tabela ficar grande demais para carregar, já vale
saber quais colunas dela são caras, e por quê.

As viagens como o `read_csv` as entrega, sem nenhum tipo escolhido:

```python
import os
import time
import numpy as np
import pandas as pd

trips = pd.read_csv("trips.csv")
trips.dtypes
```

```
trip_id          int64
started_at         str
ended_at           str
start_station      str
end_station        str
plan               str
bike               str
dtype: object
```

Uma coluna inteira e seis de texto: os horários também são texto, porque nada disse ao `read_csv` que
eram datas. Quanto custa cada uma, em bytes:

```python
trips.memory_usage(deep=True)
```

```
Index               132
trip_id          266696
started_at       900099
ended_at         901493
start_station    366707
end_station      370437
plan             437021
bike             511710
dtype: int64
```

`deep=True` mede as próprias strings; sem ele o pandas informa só o tamanho das referências a elas, o
que parece barato e não é a memória que a tabela usa. `trip_id` custa 8 bytes por linha, 266.696 para
33.337 linhas. Cada coluna de horário custa mais que o triplo disso, e `bike`, que só guarda uma de
duas palavras, custa quase o dobro de `trip_id`, porque cada linha guarda a sua própria cópia de
`classic` ou `electric`.

A tabela contra o arquivo de onde veio:

```python
trips.memory_usage(deep=True).sum(), os.path.getsize("trips.csv")
```

```
(np.int64(3754295), 2267957)
```

**A tabela ocupa mais memória do que o arquivo ocupa em disco**, 3,75 MB contra 2,27 MB aqui. Essa
razão é o número a lembrar quando alguém lhe entrega um arquivo: um CSV de alguns gigabytes precisa de
mais que isso em memória depois que o pandas o lê como texto, 1,6 vez aqui e mais onde o texto é curto e
repetido, e a memória de um notebook é onde o trabalho para. A próxima seção traz a tabela para baixo do
tamanho do arquivo, mudando só os tipos.
