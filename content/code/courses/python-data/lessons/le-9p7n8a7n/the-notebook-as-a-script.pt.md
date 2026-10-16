---
title: O notebook, como script
version: 1
---

**Um notebook é o lugar certo para achar uma resposta e o lugar errado para continuar produzindo-a.**
No dia em que alguém pede o mesmo gráfico todo mês, para uma estação diferente a cada vez, o notebook
precisa rodar sem você: de um terminal, em outro computador, num agendamento. Esta aula leva um
notebook até lá, passo a passo, e cada passo é uma falha que o notebook escondia.

O notebook da Ana, `stations.ipynb`, conta as viagens de uma estação por mês e salva um gráfico. As
quatro células dele, rodadas de cima para baixo:

```py
import pandas as pd
import matplotlib.pyplot as plt
```

```py
%time trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")
```

```py
station = "S05"
mine = trips[trips["start_station"] == station]
per_month = mine.groupby(mine["started_at"].dt.month).size()
per_month
```

```py
fig, ax = plt.subplots(layout="constrained")
ax.bar(per_month.index, per_month.to_numpy())
ax.set_title(f"Trips from {station}, 2025")
fig.savefig(f"{station}.png")
```

Ele funciona no JupyterLab, e o teste da aula 2 passa: Restart and Run All dá a mesma tabela e o mesmo
gráfico. O primeiro movimento é o que o próprio JupyterLab oferece. `jupyter nbconvert --to script`
grava as células de código como um arquivo Python:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to script stations.ipynb
[NbConvertApp] Converting notebook stations.ipynb to script
[NbConvertApp] Writing 576 bytes to stations.py
```

```
(.venv) ana@lab:~/pydata$ cat stations.py
#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import matplotlib.pyplot as plt


# In[2]:


get_ipython().run_line_magic('time', 'trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")')


# In[3]:


station = "S05"
mine = trips[trips["start_station"] == station]
per_month = mine.groupby(mine["started_at"].dt.month).size()
per_month


# In[4]:


fig, ax = plt.subplots(layout="constrained")
ax.bar(per_month.index, per_month.to_numpy())
ax.set_title(f"Trips from {station}, 2025")
fig.savefig(f"{station}.png")

```

Toda célula de código está lá, em ordem, embaixo de um comentário com a contagem de execução,
`# In[3]:`. Duas coisas mudaram no caminho. A linha do `%time` virou
`get_ipython().run_line_magic(...)`, porque `%time` não é Python: é um comando para o IPython, o
programa dentro do kernel, e o `nbconvert` a escreveu como a chamada que o IPython faria. E `per_month`
sozinho numa linha continua lá, como uma linha que calcula um valor e não faz nada com ele.

Rodado como programa, o arquivo mostra as duas coisas:

```
(.venv) ana@lab:~/pydata$ python stations.py
Traceback (most recent call last):
  File "/home/ana/pydata/stations.py", line 14, in <module>
    get_ipython().run_line_magic('time', 'trips = pd.read_csv("trips.csv", parse_dates=["started_at"], date_format="%Y-%m-%d %H:%M:%S")')
    ^^^^^^^^^^^
NameError: name 'get_ipython' is not defined
```

**`get_ipython` só existe dentro do IPython**, então o script para na segunda célula. Se a mágica não
estivesse ali, ele rodaria até o fim, salvaria o gráfico, e não imprimiria nada: a tabela que o
notebook mostrou embaixo da terceira célula era o notebook exibindo o último valor de uma célula, e um
script só exibe o que ele imprime.

Um notebook convertido é um começo, não um script. O resto desta aula o reescreve como um.
