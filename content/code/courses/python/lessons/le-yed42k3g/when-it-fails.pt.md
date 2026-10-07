---
title: Quando a instalação falha
version: 1
---

A maioria das instalações falha de um de quatro jeitos, e a máquina dá nome a cada um. As
transcrições daqui foram feitas num Ubuntu 24.04 recém-instalado, o sistema que o caminho da
máquina virtual instala, numa máquina chamada `lab` com uma usuária chamada `ana`. A sua vai
mostrar os seus próprios nomes.

## `python` não é encontrado

```
ana@lab:~$ python
Command 'python' not found, did you mean:
  command 'python3' from deb python3
  command 'python' from deb python-is-python3
ana@lab:~$ python3 --version
Python 3.12.3
```

**O Ubuntu não tem `python`, só `python3`**, e diz isso: a primeira sugestão é o programa que você
já tem. Digite `python3`, como toda aula daqui faz. A segunda sugestão é um pacote que faz de
`python` um segundo nome para ele, e você não precisa dele.

## `pip` não é encontrado, e um ambiente virtual não se cria

```
ana@lab:~$ pip --version
Command 'pip' not found, but can be installed with:
sudo apt install python3-pip
ana@lab:~$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/.venv/bin/python3

```

As duas têm uma causa só: **a linha do `apt` da seção anterior foi pulada.** O Ubuntu empacota o
`pip` e o `venv` à parte do Python, então uma máquina nova tem o interpretador e não as duas peças
em que a aula 18 se apoia. As duas mensagens dizem o nome do pacote que falta. Rode aquela linha do
`apt` e tente de novo:

```
ana@lab:~$ python3 -m venv .venv
ana@lab:~$ ls .venv
bin  include  lib  lib64  pyvenv.cfg
ana@lab:~$ pip --version
pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
```

Nenhuma saída do `venv` é sucesso. A aula 18 explica o que é esse diretório; até lá, `rm -r .venv`
apaga ele.

## O Windows diz `'python' is not recognized`

A caixa **"Add python.exe to PATH"**, na primeira tela do instalador, ficou desmarcada, então o
terminal não acha o programa que ele instalou. Rode o instalador de novo, escolha **Modify** e
marque **"Add Python to environment variables"** nas opções avançadas. Depois feche o terminal e
abra outro, porque um terminal lê o PATH uma vez só, quando começa.

Se, em vez disso, digitar `python` abre a Microsoft Store, é o Windows respondendo com um atalho
dele. Use `py`, o lançador que o instalador põe lá, ou desligue o atalho em
*Configurações > Aplicativos > Configurações avançadas de aplicativos > Aliases de execução de
aplicativo*. Nenhum dos dois foi rodado neste curso, que foi gravado em Linux.

## A versão é velha demais

Um `python3 --version` respondendo 3.9 ou menos é um sistema operacional de vários anos atrás. Não
atualize o Python do sistema, de que outros programas dele dependem: no macOS, instale o do
python.org ao lado dele, e num Linux antigo vá pelo caminho da máquina virtual, que dá o 3.12 sem
mexer no que já está lá.

## Qualquer outra coisa

**Leia o que ela imprimiu antes de pesquisar.** Uma instalação que falha costuma imprimir uma
página, e a primeira linha que diz `error` é a causa; as linhas depois dela costumam ser
consequências. Uma mensagem que dá o nome de um pacote para instalar, como as duas acima, quer
dizer exatamente isso. É o mesmo hábito de ler um traceback, que é para onde esta aula vai depois
do REPL.
