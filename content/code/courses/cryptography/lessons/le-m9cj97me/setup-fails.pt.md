---
title: Quando a montagem falha
version: 1
---

**Uma montagem que falha avisa, e quase sempre com palavras que dizem o conserto.** As cinco falhas
abaixo são as comuns, e cada uma foi provocada de propósito na máquina em que estas aulas foram
gravadas, então as mensagens são as de verdade. **Leia a mensagem até o fim antes de tentar qualquer
outra coisa.**

## O ambiente virtual não é criado

Um Ubuntu Server recém-instalado tem Python, mas não a parte dele que cria ambientes virtuais. Pule
o `python3-venv` na linha do `apt-get` e é isto que aparece:

```
ana@lab:~$ python3 -m venv ~/lab/venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/lab/venv/bin/python3
```

A mensagem dá o conserto: o pacote que ela cita, com `sudo`. Instale-o e rode o mesmo comando de
novo. Ele reaproveita o diretório feito pela metade:

```sh
sudo apt-get install -y python3-venv
```

```
ana@lab:~$ python3 -m venv ~/lab/venv && echo created
created
```

Depois continue da linha do `pip install`. Se o próprio `pip install` parar num erro de rede, a
máquina não está alcançando o Python Package Index, de onde vêm as duas bibliotecas. Confira se a
máquina chega à internet, com `curl -I https://pypi.org`, e, numa máquina virtual, se o adaptador de
rede dela está conectado.

## `vcrypt: command not found`

As linhas acrescentadas ao `~/.bashrc` valem nos terminais abertos depois delas. No que já estava
aberto, o shell não sabe onde o `vcrypt` está:

```
ana@lab:~$ vcrypt derive iv-a 16
bash: vcrypt: command not found
ana@lab:~$ source ~/.bashrc; vcrypt derive iv-a 16
ad5784f4861a73ec2a48dadd23983178
```

Leia o arquivo de novo neste terminal, ou abra outro. A mesma causa faz o `python3` desse terminal
ser o do Ubuntu, e não o do laboratório, e a conferência de versões da seção anterior mostra isso.

## `Permission denied`

Um arquivo só é programa quando tem permissão para rodar. Esqueça o `chmod +x` e o shell encontra o
`vcrypt` e o recusa:

```
ana@lab:~/lab$ vcrypt derive iv-a 16
bash: /home/ana/lab/bin/vcrypt: Permission denied
ana@lab:~/lab$ chmod +x bin/vcrypt; vcrypt derive iv-a 16
ad5784f4861a73ec2a48dadd23983178
```

## Uma colagem que perdeu a indentação

O Python lê a indentação como estrutura, então uma colagem que perdeu os espaços do começo de uma
linha não é um erro de digitação que o programa possa ignorar. Aqui a linha debaixo de `if raw:` no
`derive.py` chegou encostada na margem:

```
ana@lab:~/lab$ vcrypt derive iv-a 16
  File "/home/ana/lab/tools/derive.py", line 12
    sys.stdout.buffer.write(data)
    ^
IndentationError: expected an indented block after 'if' statement on line 11
```

A mensagem dá o arquivo, a linha e o que esperava. Abra o arquivo, compare com o bloco da aula e
conserte a linha. Se o editor acrescentou espaços por conta própria enquanto você colava, coisa que
alguns editores fazem a cada linha nova, cole no `nano`, ou desligue a indentação automática do
editor.

## Um arquivo com os bytes errados

Os resumos do fim da seção anterior são a conferência de tudo o que um comando gravou. Aqui o
`data/slots.dat` foi digitado com quatro espaços depois de `free` em vez de cinco:

```
ana@lab:~/lab$ sha256sum data/slots.dat; wc -c data/slots.dat
62dbb24783542ecf59afb8dfaa8ee562c95269b5d43ed6e65e7094e8f8d0dc39  data/slots.dat
490 data/slots.dat
```

O resumo não tem nada em comum com o certo, e o `wc -c` diz o tamanho do desvio: 490 bytes onde
deveriam ser 512, ou seja, 22 bytes a menos, um para cada horário livre. Toda transcrição posterior
que usa o arquivo discordaria da sua. **O conserto é rodar de novo o comando que gravou o
arquivo**, copiado da aula em vez de redigitado.

## Começar de novo

Nada em `~/lab` é precioso. Se ele chegou a um estado que você não consegue explicar, apague e monte
de novo: `rm -rf ~/lab`, depois os comandos desta aula a partir do `mkdir`, deixando de fora o `cat
>> ~/.bashrc`, cujas linhas já estão lá. As chaves voltam idênticas, porque são derivadas dos seus
rótulos. As aulas seguintes acrescentam arquivos próprios, e cada uma diz como criá-los, então um
laboratório remontado na aula 9 precisa também dos comandos das aulas 1 a 8. Numa máquina virtual,
um snapshot tirado no fim desta aula é um caminho de volta mais rápido.
