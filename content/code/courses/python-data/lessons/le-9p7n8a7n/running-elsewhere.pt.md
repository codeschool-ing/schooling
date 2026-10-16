---
title: Rodando de outro lugar
version: 1
---

**Um caminho relativo é relativo à pasta de onde você roda o programa, não à pasta onde o programa
está.** No JupyterLab as duas são sempre a mesma pasta, então um notebook nunca encontra a diferença. Um
script a encontra na primeira vez que é rodado de outro lugar: um agendamento, que costuma começar na
pasta pessoal, ou um colega que guarda o script num lugar e os dados em outro.

Rodado de `/tmp`, com os dados nomeados do jeito que o notebook os nomeava:

```
(.venv) ana@lab:~/pydata$ cd /tmp
(.venv) ana@lab:/tmp$ python ~/pydata/station_report.py S05 --data trips.csv
Traceback (most recent call last):
  File "/home/ana/pydata/station_report.py", line 50, in <module>
    main()
  File "/home/ana/pydata/station_report.py", line 39, in main
    trips = load(args.data)
            ^^^^^^^^^^^^^^^
  File "/home/ana/pydata/station_report.py", line 13, in load
    return pd.read_csv(path, parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 872, in read_csv
    return _read(filepath_or_buffer, kwds)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 300, in _read
    parser = TextFileReader(filepath_or_buffer, **kwds)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 1643, in __init__
    self._engine = self._make_engine(f, self.engine)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/parsers/readers.py", line 1907, in _make_engine
    self.handles = get_handle(
                   ^^^^^^^^^^^
  File "/home/ana/pydata/.venv/lib/python3.12/site-packages/pandas/io/common.py", line 930, in get_handle
    handle = open(
             ^^^^^
FileNotFoundError: [Errno 2] No such file or directory: 'trips.csv'
```

O `trips.csv` foi procurado em `/tmp`, onde o comando foi digitado, e não está lá. O traceback é longo,
a maior parte dentro do pandas, e a última linha é a que se lê.

O padrão do script não tem esse problema, porque é montado a partir de `HERE`, a pasta do próprio
script:

```py
HERE = Path(__file__).parent
```

`__file__` é o caminho do arquivo em execução, e `.parent` a pasta dele, então `HERE / "trips.csv"` são
os dados ao lado do script, onde quer que o comando seja digitado:

```
(.venv) ana@lab:/tmp$ python ~/pydata/station_report.py S05
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

O gráfico, porém, foi para `/tmp/S05.png`. O padrão da saída é relativo de propósito: um relatório é
salvo onde a pessoa que o roda está trabalhando, que é o esperado de um programa de linha de comando.
**Entradas que pertencem ao script são achadas a partir da pasta dele; saídas vão para onde está quem
chama, ou para onde o `--out` disser.**

A mesma regra responde à pergunta de onde ficam os dados em outra máquina. O script aceita `--data`,
então os dados podem morar em qualquer lugar, e nada no código precisa ser editado para apontar para
eles.
