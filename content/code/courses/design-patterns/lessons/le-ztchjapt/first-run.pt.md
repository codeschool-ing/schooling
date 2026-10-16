---
title: A primeira execução
version: 1
---

**Antes que a primeira lição peça para você rodar alguma coisa, confira a única coisa de que o curso
inteiro depende.** Abra um terminal na máquina que escolheu e pergunte ao Python qual é a versão
dele:

```
ana@laptop:~$ python3 --version
Python 3.12.3
```

Esse é o Python do próprio Ubuntu 24.04, aquele com que todas as transcrições do curso foram
gravadas. Qualquer coisa do 3.12 para cima serve. No Windows, pergunte `py --version`.

Cada lição guarda seus programas num diretório próprio dentro de `~/patterns`, para que duas lições
nunca sobrescrevam o `main.py` uma da outra. Crie o diretório desta lição e entre nele:

```sh
mkdir -p ~/patterns/oo
cd ~/patterns/oo
```

Depois salve este programa como `check.py` nesse diretório. É o jeito do curso de dizer que o
laboratório está pronto, e ele recusa com educação um Python velho demais:

```python
# check.py
import platform
import sys

need = (3, 12)
have = sys.version_info[:2]
print("Python", platform.python_version(), "on", platform.system())
if have < need:
    print(f"This course needs Python {need[0]}.{need[1]} or newer.")
    sys.exit(1)
print("Ready for the course.")
```

```
ana@laptop:~/patterns/oo$ python3 check.py
Python 3.12.3 on Linux
Ready for the course.
```

`platform.system()` responde `Darwin` num Mac e `Windows` no Windows; o que importa é a segunda
linha. Se a sua imprimiu essa linha, todo programa do curso vai rodar na sua máquina. Se não
imprimiu, a próxima seção traz o que costuma dar errado e como passar por isso.

## O que as transcrições mostram

As transcrições são gravadas como Ana, uma desenvolvedora da biblioteca, numa máquina chamada
`laptop`, então o prompt é `ana@laptop:~/patterns/oo$`. O seu mostra seu nome, sua máquina e seu
diretório. Tudo depois do prompt é o que o programa imprimiu, byte a byte. Quando um programa imprime
algo que muda de uma execução para outra, como uma hora ou a ordem em que threads terminaram, a lição
avisa ao lado.
