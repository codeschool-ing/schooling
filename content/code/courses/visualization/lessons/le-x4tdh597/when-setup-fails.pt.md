---
title: Quando a instalação falha
version: 1
---

Instalar é onde a maioria das pessoas desiste de um curso como este, e quase sempre por um de cinco
problemas. Cada um tem uma mensagem que você reconhece e uma solução que leva um minuto.

## "No module named 'matplotlib'"

```
ana@vm:~/viz$ python3 bars.py
Traceback (most recent call last):
  File "/home/ana/viz/bars.py", line 2, in <module>
    import matplotlib.pyplot as plt
ModuleNotFoundError: No module named 'matplotlib'
```

**O programa rodou no Python errado.** `python3` é o do sistema, e o matplotlib foi instalado no do
ambiente virtual. Rode como `.venv/bin/python bars.py`, ou ative o ambiente antes. Em alguns
computadores o Python do sistema por acaso também tem matplotlib, e aí o erro fica escondido até o
dia em que as duas versões diferem.

## "can't open file"

```
ana@vm:~/viz$ .venv/bin/python bar.py
.venv/bin/python: can't open file '/home/ana/viz/bar.py': [Errno 2] No such file or directory
```

A mensagem diz o caminho que procurou, e esse caminho é a pista: um erro de digitação no nome, como
aqui, ou um terminal aberto em outra pasta. `ls` mostra o que existe de fato.

## "No such file or directory: 'monthly.csv'"

O programa achou a si mesmo, mas não os dados. Os arquivos CSV são escritos pelo `horta.py` **na
pasta de onde você o roda**, e os programas os leem da pasta de onde *eles* são rodados. Rode tudo
da pasta do curso e o problema some.

## O pip diz "externally-managed-environment"

Distribuições Linux recentes recusam `pip install` no Python do próprio sistema, para proteger os
pacotes de que o sistema depende. **É para isso que existe o ambiente virtual**: instale no `.venv`,
nunca com `sudo pip`. Se o próprio `python3 -m venv` falhar no Ubuntu ou no Debian, o módulo vem num
pacote separado: `sudo apt install python3-venv`.

## O pip não alcança a internet

Uma mensagem que fala em `SSL`, `certificate` ou `Could not find a version` em geral indica uma
rede no meio do caminho: um proxy da empresa, um firewall da escola. Tente uma vez de outra rede; se
funcionar lá, o problema é a rede e não a sua instalação, e o caminho online de "O computador onde
você vai desenhar" evita o problema por completo.

## Quando não é nenhum desses

Leia primeiro a **última linha** do erro. O Python imprime toda a cadeia de chamadas que levou ao
problema, e a linha que dá nome a ele fica embaixo. Procure essa linha exata junto com a palavra
`matplotlib`, e você quase sempre acha alguém que passou por isso antes.
