---
title: Quando a instalação falha
version: 1
---

**Quatro falhas respondem por quase tudo, e cada uma imprime o próprio nome.** Leia as últimas
linhas que um comando imprimiu antes de qualquer outra coisa: o primeiro erro é o que importa, e o
que vem depois costuma ser consequência dele.

## `jupyter: command not found`

Um terminal novo, e a linha do ambiente foi esquecida:

```
ana@lab:~$ cd pydata
ana@lab:~/pydata$ jupyter lab
bash: jupyter: command not found
```

O `jupyter` está instalado dentro de `.venv`, e só um terminal que rodou
`source .venv/bin/activate` sabe procurar lá. O prompt diz que tipo de terminal é este: sem
`(.venv)` na frente, sem ambiente. Rode a linha, de dentro de `pydata`, e tente de novo. Num Ubuntu
de desktop o mesmo engano pode imprimir, em vez disso, uma sugestão de instalar um pacote `jupyter`
com `apt`; isso não foi gravado aqui, e a resposta é a mesma. **Não instale.** Um segundo
JupyterLab fora do ambiente iniciaria, e os notebooks dele rodariam num Python sem as suas
bibliotecas.

## `externally-managed-environment`

O `pip` rodou fora do ambiente, no Python de que o próprio Ubuntu depende:

```
ana@lab:~/pydata$ python3 -m pip install pandas==3.0.6
error: externally-managed-environment

× This environment is externally managed
```

O Ubuntu recusa de propósito: uma biblioteca instalada ali pode quebrar um programa do sistema
operacional que esperava outra versão. A mensagem segue sugerindo um ambiente virtual, que é o que
`.venv` é. Ative-o e o mesmo `pip install` vai para o lugar certo. Se o próprio
`python3 -m venv .venv` falhar, reclamando que `ensurepip` não está disponível, falta o pacote
`python3-venv` da primeira linha do `apt-get`.

## `Could not find a version that satisfies the requirement`

O Python é antigo demais para as versões fixadas. Isto foi gravado numa segunda pasta, `oldpy`,
com um Python 3.11 que um Ubuntu 24.04 recém-instalado não tem; em outro sistema é o Python que
veio com ele:

```
(.venv) ana@lab:~/oldpy$ python --version
Python 3.11.17
(.venv) ana@lab:~/oldpy$ pip install numpy==2.5.3
ERROR: Ignored the following yanked versions: 2.4.0
ERROR: Ignored the following versions that require a different python version: 1.21.2 Requires-Python >=3.7,<3.11; 1.21.3 Requires-Python >=3.7,<3.11; 1.21.4 Requires-Python >=3.7,<3.11; 1.21.5 Requires-Python >=3.7,<3.11; 1.21.6 Requires-Python >=3.7,<3.11; 2.5.0 Requires-Python >=3.12; 2.5.0rc1 Requires-Python >=3.12; 2.5.1 Requires-Python >=3.12; 2.5.2 Requires-Python >=3.12; 2.5.3 Requires-Python >=3.12
ERROR: Could not find a version that satisfies the requirement numpy==2.5.3 (from versions: 1.3.0, 1.4.1, 1.5.0, 1.5.1, 1.6.0, 1.6.1, 1.6.2, 1.7.0, 1.7.1, 1.7.2, 1.8.0, 1.8.1, 1.8.2, 1.9.0, 1.9.1, 1.9.2, 1.9.3, 1.10.0.post2, 1.10.1, 1.10.2, 1.10.4, 1.11.0, 1.11.1, 1.11.2, 1.11.3, 1.12.0, 1.12.1, 1.13.0, 1.13.1, 1.13.3, 1.14.0, 1.14.1, 1.14.2, 1.14.3, 1.14.4, 1.14.5, 1.14.6, 1.15.0, 1.15.1, 1.15.2, 1.15.3, 1.15.4, 1.16.0, 1.16.1, 1.16.2, 1.16.3, 1.16.4, 1.16.5, 1.16.6, 1.17.0, 1.17.1, 1.17.2, 1.17.3, 1.17.4, 1.17.5, 1.18.0, 1.18.1, 1.18.2, 1.18.3, 1.18.4, 1.18.5, 1.19.0, 1.19.1, 1.19.2, 1.19.3, 1.19.4, 1.19.5, 1.20.0, 1.20.1, 1.20.2, 1.20.3, 1.21.0, 1.21.1, 1.22.0, 1.22.1, 1.22.2, 1.22.3, 1.22.4, 1.23.0, 1.23.1, 1.23.2, 1.23.3, 1.23.4, 1.23.5, 1.24.0, 1.24.1, 1.24.2, 1.24.3, 1.24.4, 1.25.0, 1.25.1, 1.25.2, 1.26.0, 1.26.1, 1.26.2, 1.26.3, 1.26.4, 2.0.0, 2.0.1, 2.0.2, 2.1.0, 2.1.1, 2.1.2, 2.1.3, 2.2.0, 2.2.1, 2.2.2, 2.2.3, 2.2.4, 2.2.5, 2.2.6, 2.3.0, 2.3.1, 2.3.2, 2.3.3, 2.3.4, 2.3.5, 2.4.0rc1, 2.4.1, 2.4.2, 2.4.3, 2.4.4, 2.4.5, 2.4.6)
ERROR: No matching distribution found for numpy==2.5.3
```

A linha útil é a segunda, perto do fim: `2.5.3 Requires-Python >=3.12`. O pip encontrou a versão e
a recusou, porque este NumPy é feito para o 3.12 em diante. Instale um Python mais novo, apague o
`.venv` da pasta e crie-o de novo com o interpretador novo: um ambiente fica preso ao Python que o
criou e não se atualiza no lugar.

## A porta 8888 está ocupada

Um segundo `jupyter lab` enquanto o primeiro ainda roda em algum lugar, muitas vezes num terminal
de que você esqueceu. Estas são as linhas do log do segundo que dizem isso:

```
[I 2026-10-10 04:06:19.655 ServerApp] The port 8888 is already in use, trying another port.
[I 2026-10-10 04:06:19.655 ServerApp] Jupyter Server 2.21.1 is running at:
[I 2026-10-10 04:06:19.656 ServerApp] http://localhost:8889/lab?token=20d69fcf11ddafde11d7f86434cbd4047ec8b7ad5bb0f3f3
```

Nada quebrou: o segundo servidor achou a `8888` ocupada e foi para a `8889`. Mas agora você tem
dois servidores, cada um com os seus kernels, e um notebook aberto num não vê o que roda no outro.
Ache o primeiro terminal e pare-o com Control-C, duas vezes, ou fique com ele e feche o segundo. O
comando `jupyter server list` imprime cada servidor rodando para o seu usuário, com o endereço.

## O notebook roda, e `import pandas` falha

É o kernel rodando um Python que não é o do ambiente, o que acontece quando o próprio JupyterLab
foi iniciado de fora dele. A segunda célula do primeiro notebook é a conferência:
`sys.executable` tem de terminar em `pydata/.venv/bin/python`. Se não terminar, pare o JupyterLab,
ative o ambiente naquele terminal e inicie de novo.

Se falhar algo que não está aqui, comece do zero em vez de consertar: apague o `.venv`, crie-o de
novo com os comandos da seção do laboratório e rode o `pip install` mais uma vez. Tudo nele se
reproduz a partir daquelas linhas, que é o motivo de guardá-las, e a aula 3 as transforma num
arquivo.
