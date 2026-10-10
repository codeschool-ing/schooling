---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, diante de um erro de uma
máquina que acabou de montar. Estas são as falhas que de fato acontecem, mais ou menos na ordem em
que você as encontraria. Onde a máquina em que o curso foi gravado produziu uma delas, ela aparece
como essa máquina a imprimiu.

**`python3 -m venv .venv` diz *ensurepip is not available*.** Falta o pacote `python3-venv`, e a
mensagem diz o nome do pacote a instalar. Rode de novo a linha do `apt-get install`, apague o `.venv`
feito pela metade com `rm -rf .venv` e crie-o outra vez.

**Um terminal novo não acha o PyTorch.**

```
ana@vm:~/dl$ python3 -c "import torch"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'torch'
```

A biblioteca está dentro de `~/dl/.venv`, e este terminal nunca o ativou: as linhas do `~/.bashrc`
foram puladas, ou o terminal foi aberto antes de elas entrarem. `. ~/dl/.venv/bin/activate` conserta
o terminal em que você está, e `which python` deve então responder `/home/ana/dl/.venv/bin/python`,
com o seu nome de usuário.

**O `pip` não é encontrado, ou recusa com *externally-managed-environment*.** É o mesmo erro visto do
outro lado: o comando rodou fora do ambiente. O Ubuntu 24.04 protege o Python de que o próprio sistema
depende e recusa um `pip install` dirigido a ele; a mensagem sugere `--break-system-packages`, e esse
conselho está errado aqui. Ative o ambiente, e o mesmo comando instala dentro dele. A máquina do curso
nunca rodou o `pip` fora de um ambiente, então isto está descrito, e não mostrado.

**A instalação para com *No space left on device*.** As bibliotecas ocupam uns 6 GB depois de
desempacotadas, e o `pip` precisa de espaço também para os downloads. Uma VM criada com disco menor
que os 30 GB acima fica sem espaço aqui. `multipass stop vm`, depois `multipass set
local.vm.disk=30G` para aumentá-lo, ou instale a versão só para processador que a seção anterior
cita, que deixa de fora as bibliotecas da NVIDIA. Isto não aconteceu na máquina em que o curso foi
gravado, então está descrito, e não mostrado.

**O `pip` diz que nenhuma versão do `torch` serve.** O PyTorch publica pacotes prontos para uma faixa
de versões do Python, e um Python mais novo que essa faixa não acha nenhum. As versões do
`requirements.txt` foram gravadas no Python 3.12, o que vem com o Ubuntu 24.04; use o Ubuntu 24.04 na
VM, que é a razão de a VM ser o caminho recomendado.

**Um treinamento termina com uma única palavra, `Killed`.** O sistema ficou sem memória e encerrou o
processo. Nada neste curso precisa de mais que uma fração de 8 GB, então a causa comum é uma VM criada
com menos, ou outro programa segurando a memória. `free -h` diz quanto está livre. Isto também não
aconteceu na máquina do curso.

**Os seus números não são os números da aula.** Isso não é uma falha. Uma rede começa de pesos
aleatórios, e os programas daqui fixam a semente para que uma máquina se repita. Um processador
diferente pode somar os mesmos números em outra ordem e arredondar diferente no último dígito, e ao
longo de milhares de passos isso vira uma segunda casa decimal diferente. O que uma aula tira de uma
execução é uma forma — a perda caindo, a acurácia contra a linha de base, uma configuração vencendo
outra — e é a forma que você deve conferir na sua.
