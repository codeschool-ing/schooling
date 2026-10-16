---
title: Quando a instalação falha
version: 1
---

Preparar o ambiente é onde mais gente desiste de um curso assim, e quase sempre por um de poucos
problemas. Cada um imprime uma mensagem reconhecível. **Leia primeiro a última linha de um erro**: o
Python imprime a cadeia de chamadas que levou ao problema, e a linha que dá nome ao problema fica
embaixo.

## "No module named 'numpy'"

O programa rodou no Python errado. O `deactivate` aqui faz as vezes de um terminal em que o ambiente
nunca foi ativado, que é o que você tem num terminal aberto antes de o `~/.bashrc` ganhar as linhas
novas:

```
ana@lab:~/ml$ deactivate
ana@lab:~/ml$ python3 make_data.py
Traceback (most recent call last):
  File "/home/ana/ml/make_data.py", line 6, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'
```

`python3` é o do próprio sistema, e o NumPy foi instalado no do ambiente. Abra um terminal novo, ou
digite `source ~/ml/.venv/bin/activate`, e rode de novo. `which python` responde qual você está
prestes a rodar: deve imprimir um caminho dentro de `~/ml/.venv`.

## "externally-managed-environment"

O mesmo engano, um passo antes, na instalação:

```
ana@lab:~/ml$ deactivate
ana@lab:~/ml$ python3 -m pip install -r requirements.txt
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**O Ubuntu se recusa a deixar o pip mudar o Python em que o próprio sistema roda**, porque uma
atualização ali pode quebrar programas de que o sistema depende. A mensagem sugere um ambiente
virtual, e `~/ml/.venv` é um. Ative-o e instale de novo. Não passe `--break-system-packages`: o nome
é exato.

Se o próprio `python3 -m venv .venv` falhar no Ubuntu ou no Debian com uma mensagem que fala em
`ensurepip`, o módulo que cria ambientes vem num pacote separado. `sudo apt-get install
python3-venv` o acrescenta.

## "can't open file"

O programa achou o Python, mas não achou a si mesmo:

```
ana@lab:~/ml$ cd ~
ana@lab:~$ python make_data.py
python: can't open file '/home/ana/make_data.py': [Errno 2] No such file or directory
```

A mensagem diz o caminho em que procurou, e essa é a pista: o terminal estava em outra pasta. Todo
programa deste curso lê `data/` a partir da pasta de onde roda, então faça `cd ~/ml` antes de rodar
qualquer coisa.

## "No matching distribution found"

O pip chegou ao índice e não achou nada com aquele nome:

```
ana@lab:~/ml$ cd ~/broken
ana@lab:~/broken$ pip install --quiet -r requirements.txt
ERROR: Could not find a version that satisfies the requirement scikit-lean==1.9.1 (from versions: none)
ERROR: No matching distribution found for scikit-lean==1.9.1
```

`scikit-lean` é um erro de digitação, e o pip não distingue um erro de digitação de uma biblioteca
que não existe. **A mesma mensagem aparece para uma versão que não existe**, e para uma versão que
existe mas não para o seu Python: um Python anterior ao 3.12 é a causa de costume, e `python3
--version` resolve.

## O pip não alcança a internet

Uma mensagem que fala em `SSL`, `certificate`, `ProxyError` ou `Connection` quer dizer que há
alguma coisa entre você e o índice: um proxy da empresa, a rede da escola, um firewall. Tente uma
vez de outra rede. Se funcionar ali, o problema é a rede e não a instalação, e quem cuida daquela
rede é quem pode resolver.

## Quando não é nenhum desses

Copie a última linha do erro e procure por ela com o nome da biblioteca ao lado. Quase sempre alguém
já passou por isso. **Se você já mudou muita coisa tentando consertar, comece de novo**: apague
`~/ml/.venv` e rode outra vez as quatro linhas da instalação. Leva alguns minutos e põe você de
volta num terreno conhecido, o que vale mais que uma tarde remendando um ambiente que ninguém sabe
descrever.
