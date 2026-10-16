---
title: Anotando o ambiente, e provando que ele se reconstrói
version: 1
---

**O ambiente que você tem é um acaso do dia em que foi montado; o arquivo que você escreve é o
ambiente que você pode ter de novo.** A aula 1 instalou sete bibliotecas com um `pip install`, e
o pip trouxe tudo de que elas precisam. Pergunte a ele o que há agora:

```
(.venv) ana@lab:~/pydata$ pip freeze | wc -l
103
(.venv) ana@lab:~/pydata$ pip freeze | grep -E "^(numpy|pandas|python-dateutil|pytz|tzdata)=="
numpy==2.5.3
pandas==3.0.6
python-dateutil==2.9.0.post0
tzdata==2026.5
```

Cento e três pacotes, a partir de sete pedidos. A maioria você nunca escolheu: `tzdata` é a base
de fusos horários que o pandas lê, `python-dateutil` interpreta datas para ele, e uma longa cauda é
do JupyterLab. Há dois jeitos honestos de anotar isso, e um projeto de dados quer os dois.

## Os requisitos diretos, à mão

`requirements.txt` em `pydata`, com o que você pediu e mais nada:

```
jupyterlab==4.6.4
numpy==2.5.3
pandas==3.0.6
matplotlib==3.11.2
seaborn==0.13.2
pyarrow==26.0.0
openpyxl==3.1.5
```

É curto o bastante para ler, e cada linha é uma decisão: **este** projeto usa pandas, **nesta**
versão. O teste do arquivo é montar um ambiente a partir dele em outro lugar e ver se é o mesmo.
Uma segunda pasta na mesma máquina, feita só com o arquivo:

```
ana@lab:~$ mkdir rebuilt && cd rebuilt
ana@lab:~/rebuilt$ python3 -m venv .venv && source .venv/bin/activate
(.venv) ana@lab:~/rebuilt$ pip install -q -r ../pydata/requirements.txt
(.venv) ana@lab:~/rebuilt$ pip freeze | wc -l
103
(.venv) ana@lab:~/rebuilt$ pip check
No broken requirements found.
```

`-q` deixa o pip quieto. O ambiente novo tem os mesmos cento e três pacotes, e o `pip check`
confirma que os requisitos de cada pacote são satisfeitos pelas versões ao lado dele.

## A lista completa, à máquina

O arquivo direto fixa sete pacotes e deixa noventa e seis ao critério do pip no dia em que ele
roda. Hoje o pip escolheu o que escolheu na aula 1; no mês que vem uma dependência do JupyterLab
vai publicar uma versão nova, e o mesmo arquivo vai montar um ambiente um pouco diferente. Para um
notebook cujos números importam, anote também o estado inteiro:

```
(.venv) ana@lab:~/pydata$ pip freeze > requirements-lock.txt
(.venv) ana@lab:~/pydata$ diff <(pip freeze) <(cd ~/rebuilt && .venv/bin/pip freeze) && echo same
same
```

`pip freeze` lista cada pacote instalado com a versão exata, na mesma forma `nome==versão` que o
`pip install -r` lê. O `diff` compara as listas dos dois ambientes e não acha nada, então o
`echo same` roda: o arquivo montou um ambiente idêntico, hoje. `requirements-lock.txt` é o que faz
de "hoje" qualquer dia.

Guarde os dois, e saiba qual usar:

| arquivo | escrito por | guarda | reconstrua com ele quando |
|---|---|---|---|
| `requirements.txt` | você | o que o projeto precisa, fixado | você está atualizando de propósito e quer que o pip escolha o resto de novo |
| `requirements-lock.txt` | `pip freeze` | tudo, exatamente | você quer o mesmo ambiente, e os mesmos números |

O curso `python`, aula 19, faz o mesmo com `uv` e `pyproject.toml`, em que um comando mantém as
duas listas para você; para um projeto que está virando um pacote, essa é a ferramenta melhor. Dois
arquivos de texto simples bastam para uma análise, e funcionam sem nada instalado além do pip.

**Os dois vão para o controle de versão ao lado dos notebooks; o `.venv` nunca.** A pasta se
reproduz em minutos a partir de qualquer um dos arquivos, e os arquivos são a parte que vale guardar.
