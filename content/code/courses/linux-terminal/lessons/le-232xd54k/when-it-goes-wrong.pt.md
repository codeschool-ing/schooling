---
title: Lendo uma recusa
version: 1
---

Um terminal te diz mais quando recusa do que qualquer interface que você já usou te diz quando dá
certo. A informação está toda ali; ela só é seca, e ninguém ensina a gramática.

**Todo erro que você vai encontrar tem três partes:** quem está falando, no que estava trabalhando,
e o que deu errado.

```
cat: /etc/shadow: Permission denied
└┬┘  └────┬────┘  └───────┬──────┘
 │        │               └─ o que deu errado
 │        └───────────────── no que estava trabalhando
 └────────────────────────── quem está falando
```

Leia da esquerda para a direita e o erro nomeia a própria causa. O `cat` está falando, então o `cat`
rodou — o comando foi encontrado e iniciado. Ele estava trabalhando em `/etc/shadow`, então o
argumento chegou até ele. E foi recusado, o que a seção 03 já te disse ser a resposta do kernel, e
não a opinião do programa.

## Os quatro que você vai encontrar esta semana

**Comando não encontrado.**

```
ana@vm:~$ celar
bash: celar: command not found
```

O `bash:` é quem fala — o shell, não um programa, porque nenhum programa foi alcançado. Ele
procurou e não achou nada com esse nome. Um erro de digitação, ou algo que não está instalado.

**Permissão negada.**

```
ana@vm:~$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```

O programa rodou e o kernel disse não. A seção 14 mostra por quê para este arquivo. Não é bug, e
normalmente não é coisa para resolver com `sudo` antes de você ter entendido o que está pedindo.

**Arquivo ou diretório inexistente.**

```
ana@vm:~$ ls /lugarnenhum
ls: cannot access '/lugarnenhum': No such file or directory
```

O programa rodou, pegou o argumento, e o caminho não existe. Nove em cada dez vezes é erro de
digitação ou diretório errado — e o `pwd` e o Tab, das seções 06 e 08, são as duas coisas que
teriam evitado.

**Opção inválida.**

```
ana@vm:~$ ls -Z9
ls: invalid option -- '9'
Try 'ls --help' for more information.
```

O programa rodou e recusou uma flag. Repare que ele nomeia o caractere, não a palavra inteira, e
repare que ele te diz onde olhar em seguida — que é o `--help` da seção 16, oferecido pelo próprio
programa.

## O número que ninguém te mostra

Todo comando deixa para trás um número dizendo como foi, e o shell guarda o último em `$?`:

```
ana@vm:~$ true
ana@vm:~$ echo $?
0
```

**Zero quer dizer que deu certo.** Qualquer outra coisa quer dizer que não, e essa convenção é a
razão inteira de a aula 9 poder escrever `comando && proximo_comando`.

Veja as quatro falhas acima responderem diferente:

| comando | `$?` | |
|---|---|---|
| `true` | `0` | deu certo |
| `cat /etc/shadow` | `1` | uma falha geral |
| `ls /lugarnenhum` | `2` | o `ls` usa 2 para "problema sério" |
| `ls -Z9` | `2` | mesmo programa, mesmo tipo de reclamação |
| `celar` | `127` | **do shell**: não existe esse comando |
| `Ctrl+C` em qualquer coisa | `130` | interrompido — seção 08 |

Dois deles valem decorar porque são do próprio shell: **127 é "não achei"** e **130 é "você apertou
Ctrl+C"**. O resto é assunto de cada programa, e o `man` diz o que querem dizer.

## O hábito

Quando algo falha, nesta ordem:

1. **Leia a primeira palavra.** Ela nomeia quem reclama, e só isso já reduz a uma camada.
2. **Leia a última parte.** Ela diz o que deu errado, em inglês.
3. **`pwd` e `ls`.** Mais falhas são "diretório errado" do que qualquer outra coisa.
4. **`type` nele** — seção 16 — se o comando em si estiver se comportando de forma inesperada.
5. **`echo $?`** quando um comando falhou em silêncio, o que acontece.

**E não vá de `sudo` primeiro.** `Permission denied` é o sistema te dizendo que o que você pediu não
é seu para fazer. Às vezes a resposta é pedir como root; muitas vezes a resposta é que você está no
diretório errado, ou editando a cópia errada, e o `sudo` teria feito a bagunça com autoridade.
