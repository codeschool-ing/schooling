---
title: Quando a instalação falha
version: 1
---

Instalar é onde a maioria das pessoas desiste de um curso como este, e quase sempre por um de cinco
problemas. Cada um tem uma mensagem que você reconhece e uma solução que leva um minuto.

## "No such file or directory: 'daily_orders.csv'"

```
ana@vm:~/bi$ .venv/bin/python look.py
Traceback (most recent call last):
  File "/home/ana/bi/look.py", line 3, in <module>
    orders = pd.read_csv("daily_orders.csv", parse_dates=["date"], index_col="date")["orders"]
             ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 872, in read_csv
    return _read(filepath_or_buffer, kwds)
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 300, in _read
    parser = TextFileReader(filepath_or_buffer, **kwds)
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 1643, in __init__
    self._engine = self._make_engine(f, self.engine)
                   ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py", line 1907, in _make_engine
    self.handles = get_handle(
                   ~~~~~~~~~~^
        f,
        ^^
    ...<6 lines>...
        storage_options=self.options.get("storage_options", None),
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/common.py", line 930, in get_handle
    handle = open(
        handle,
    ...<3 lines>...
        newline="",
    )
FileNotFoundError: [Errno 2] No such file or directory: 'daily_orders.csv'
```

**Leia a última linha primeiro.** O Python imprime toda a cadeia de chamadas que levou ao
problema, e a maior parte dela está dentro do pandas, que não é onde o problema está. A última
linha diz qual é: o programa procurou o `daily_orders.csv` e o arquivo não estava lá. Ou o
`panela.py` ainda não foi rodado, como aqui, ou foi rodado em outra pasta. Os arquivos são escritos
na pasta de onde você roda o `panela.py`, e os programas os leem da pasta de onde *eles* são
rodados. Rode tudo a partir da pasta do curso e o problema desaparece.

## "No module named 'statsmodels'"

```
ana@vm:~/bi$ python3 -c "import pandas, statsmodels, sklearn"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import pandas, statsmodels, sklearn
ModuleNotFoundError: No module named 'statsmodels'
```

**O programa rodou no Python errado.** O `python3` é o do sistema, e os pacotes foram instalados
no do ambiente virtual. Na máquina em que estas aulas foram gravadas, o Python do sistema por acaso
tem o pandas e não o statsmodels, então o erro aparece no segundo pacote e não no primeiro. Essa é
a versão perigosa do problema: um programa que só usa pandas rodaria, numa versão diferente da
aula, e imprimiria números diferentes sem motivo visível. Rode todo programa como
`.venv/bin/python`.

## "can't open file"

```
ana@vm:~/bi$ .venv/bin/python lok.py
.venv/bin/python: can't open file '/home/ana/bi/lok.py': [Errno 2] No such file or directory
```

A mensagem diz o caminho que procurou, e esse caminho é a pista: um erro de digitação no nome,
como aqui, ou um terminal aberto em outra pasta. O `ls` mostra o que existe de verdade.

## O pip diz "externally-managed-environment"

Distribuições Linux recentes, o Ubuntu 24.04 entre elas, recusam `pip install` no Python do próprio
sistema, para proteger os pacotes de que o sistema depende. **É para isso que existe o ambiente
virtual**: instale dentro do `.venv`, nunca com `sudo pip`. Se o próprio `python3 -m venv` falhar no
Ubuntu ou no Debian, o módulo vem num pacote separado e `sudo apt install python3-venv` o
acrescenta.

## O pip não acha uma versão, ou não alcança a internet

O pip recusa um pacote cujos requisitos o seu Python não cumpre, e o numpy e o scipy precisam do
3.12 ou mais novo: num Python mais antigo a instalação para com uma mensagem de que nenhuma versão
compatível foi encontrada. O `python3 --version` resolve a dúvida, e a solução é um Python mais
novo. Uma mensagem que fala de `SSL` ou `certificate` é outra coisa: uma rede no meio do caminho,
como um proxy de empresa ou um firewall de escola. Tente uma vez de outra rede. Se funcionar lá, o
problema é a rede e não a sua instalação, e o caminho online de "O computador em que você vai
analisar" evita isso por inteiro.

## Quando não é nenhum desses

Pesquise a **última linha** do erro, palavra por palavra, junto com o nome do pacote. Quase toda
mensagem que uma instalação nova produz já foi encontrada e respondida por alguém antes de você.
