---
title: Durações, e o fuso horário em que um horário está
version: 1
---

**Subtrair dois datetimes dá um timedelta, uma duração, com o seu próprio acessor.** A duração de
cada viagem é uma linha:

```python
trips["duration"] = trips["ended_at"] - trips["started_at"]
trips["duration"].dtype, trips["duration"].head(2).tolist()
```

```
(dtype('<m8[us]'),
 [Timedelta('0 days 00:34:25'), Timedelta('0 days 00:16:52')])
```

```python
minutes = trips["duration"].dt.total_seconds() / 60
minutes.describe().round(1)
```

```
count    33191.0
mean        16.7
std         10.1
min          1.8
25%          9.8
50%         14.2
75%         20.7
max        175.1
Name: duration, dtype: float64
```

`total_seconds()` transforma cada duração num número, e dividir por 60 dá minutos. A viagem mediana
dura uns quinze minutos, e a mais longa durou quase três horas. A contagem é 33.191: as bicicletas
perdidas não têm fim, então não têm duração, e o `describe` as pula.

## Fusos horários

Um datetime sem fuso horário é **ingênuo**: diz 12:22 sem dizer onde. O Recife está três horas atrás
do UTC, e um sistema que guarda horários em UTC, como a maioria dos servidores, vai discordar destes
arquivos em três horas. Prenda o fuso em que os horários foram registrados, e a conversão fica exata:

```python
local = trips["started_at"].dt.tz_localize("America/Recife")
local.iloc[0], local.dt.tz_convert("UTC").iloc[0]
```

```
(Timestamp('2025-01-01 12:22:38-0300', tz='America/Recife'),
 Timestamp('2025-01-01 15:22:38+0000', tz='UTC'))
```

`tz_localize` declara em que fuso estava um horário ingênuo; `tz_convert` expressa o mesmo momento
em outro fuso. O momento não muda, só o relógio em que é lido. O Recife não tem horário de verão desde
2000, então o deslocamento dele é um `-03:00` fixo; São Paulo teve horário de verão até 2019, e um
horário ingênuo ali pode ser ambíguo ou nem existir na noite em que os relógios mudaram. Esse é o melhor motivo para guardar horários em UTC e convertê-los só para mostrar.

**Nunca compare uma coluna ingênua com uma com fuso**: o pandas recusa, e a recusa está certa, porque
ele não tem como saber que fuso a ingênua queria dizer.
