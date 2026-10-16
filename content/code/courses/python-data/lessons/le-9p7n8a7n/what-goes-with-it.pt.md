---
title: O que vai junto, para rodar em outro lugar
version: 1
---

**Um script roda em outro lugar quando três coisas viajam com ele: o código, as versões das bibliotecas
para as quais ele foi escrito, e uma frase dizendo como rodá-lo.** A primeira é o `station_report.py`.
As outras duas são arquivos curtos, e deixá-las de fora é o que faz de "na minha máquina funciona" uma
frase que as pessoas dizem.

As versões são o `requirements.txt` da aula 3, as fixações que este curso instalou:

```
(.venv) ana@lab:~/pydata$ cat requirements.txt
jupyterlab==4.6.4
numpy==2.5.3
pandas==3.0.6
matplotlib==3.11.2
seaborn==0.13.2
pyarrow==26.0.0
openpyxl==3.1.5
```

Outra pessoa monta o mesmo ambiente a partir dele com `pip install -r requirements.txt`, e o pandas
dela imprime o que o seu imprimiu. Sem ele ela recebe o que for mais novo naquele dia, e a aula 11
mostrou quanto uma versão maior do pandas pode mudar.

A frase é um `README.md` ao lado do script: um arquivo de texto, escrito em Markdown porque o GitHub e
a maioria dos editores o desenham como uma página, e para um script deste tamanho ele é curto. Crie-o
no JupyterLab com **Text File**, dê o nome `README.md`, e escreva o que alguém precisa para rodar o
script a partir do nada:

```
(.venv) ana@lab:~/pydata$ cat README.md
# Station report

Trips per month from one Maré Bikes station, as a table and a chart.

    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    python station_report.py S05

`--data` points at another trips file, `--out` names the chart, and
`python station_report.py -h` lists both.
```

A pasta guarda o projeto e o que ele produziu:

```
(.venv) ana@lab:~/pydata$ ls
README.md  __pycache__	 quiet.png	   station_report.py  stations.ipynb  trips.csv
S05.png    make_data.py  requirements.txt  stations.csv       stations.py     weather.csv
```

Quatro desses são o projeto: `station_report.py`, `requirements.txt`, `README.md` e `stations.ipynb`.
Os arquivos CSV são os dados, o `make_data.py` os cria, e os dois gráficos são saída. `__pycache__` é
onde o Python guarda a forma compilada de um módulo que importou, aqui o `station_report`, e ele é
refeito sempre que falta, então fica fora de um repositório com uma linha no `.gitignore`. O
`stations.py`, o notebook convertido, já cumpriu o seu papel e pode ir embora.

O `stations.ipynb` fica. É onde a pergunta foi feita primeiro, e é o lugar certo para fazer a próxima.
**O notebook é para descobrir; o script é para fazer de novo.** Cada vez que uma resposta achada no
notebook precisa ser produzida de novo, ela vai para uma função no script, e o notebook a importa de
lá.

Esse é o curso inteiro num hábito: um notebook que roda de cima para baixo, tipos escolhidos de
propósito, junções e janelas conferidas contra as contagens de linhas, gráficos que dizem o que
mostram, e o trabalho que precisa durar levado para um arquivo que roda sem você.
