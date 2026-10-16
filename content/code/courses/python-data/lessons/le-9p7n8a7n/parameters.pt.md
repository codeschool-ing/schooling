---
title: Parâmetros, pela linha de comando
version: 1
---

**Um parâmetro é o que quem roda um script escolhe sem editá-lo.** No notebook a estação era uma linha
de código, `station = "S05"`; mudá-la queria dizer abrir o notebook, editar uma célula e rodar tudo de
novo. O `argparse` a transforma numa palavra digitada depois do nome do script.

A ajuda que o `argparse` escreve a partir dos argumentos que o script declarou:

```
(.venv) ana@lab:~/pydata$ python station_report.py -h
usage: station_report.py [-h] [--data DATA] [--out OUT] station

Trips per month from one station of Maré Bikes.

positional arguments:
  station      a station code, such as S05

options:
  -h, --help   show this help message and exit
  --data DATA  the trips file (default: trips.csv beside this script)
  --out OUT    where to save the chart (default: STATION.png)
```

Ninguém escreveu esse texto. O `argparse` o montou a partir de cada `add_argument`: `station` é
**posicional**, obrigatório e dado pela posição; `--data` e `--out` são **opções**, nomeadas e
opcionais, com os padrões que o `help` delas descreve. O `-h` veio de graça.

Uma execução para uma estação:

```
(.venv) ana@lab:~/pydata$ python station_report.py S05
started_at
1     359
2     346
3     345
4     352
5     318
6     348
7     343
8     340
9     334
10    376
11    354
12    339
saved S05.png
```

A tabela que o notebook exibia é impressa, porque o script disse `print`, e o gráfico está em
`S05.png`. Outra estação é outra execução, sem nada editado:

```
(.venv) ana@lab:~/pydata$ python station_report.py S12 --out quiet.png
started_at
1     71
2     65
3     88
4     64
5     70
6     68
7     73
8     64
9     66
10    76
11    69
12    73
saved quiet.png
```

## Dizer não

Uma estação que não existe:

```
(.venv) ana@lab:~/pydata$ python station_report.py S99
no trips from station 'S99'
(.venv) ana@lab:~/pydata$ echo $?
1
```

**O `sys.exit` com uma mensagem a imprime e termina o script com status 1**, que o `echo $?` mostra:
`$?` é o status do último comando, e 0 quer dizer sucesso. Qualquer coisa que rode o script, um
agendamento, outro script, um pipeline, lê esse número para saber se continua. Um script que salvasse
um gráfico vazio e terminasse com 0 teria relatado sucesso para um erro de digitação.

Um argumento que falta é recusado pelo próprio `argparse`, antes de qualquer código do script rodar:

```
(.venv) ana@lab:~/pydata$ python station_report.py
usage: station_report.py [-h] [--data DATA] [--out OUT] station
station_report.py: error: the following arguments are required: station
(.venv) ana@lab:~/pydata$ echo $?
2
```

Status 2 desta vez: o `argparse` o usa para uma linha de comando que não conseguiu entender, então quem
chama consegue distinguir uma chamada errada de uma execução que falhou.
