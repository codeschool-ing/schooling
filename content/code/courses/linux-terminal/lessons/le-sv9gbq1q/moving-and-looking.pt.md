---
title: Andar e olhar: `pwd`, `cd`, `ls`
version: 1
---

Três comandos, e você vai digitá-los mais do que todo o resto deste curso somado. `pwd` diz onde
você está, `cd` anda, `ls` olha. Esta seção é sobre o punhado de opções que vale ter nos dedos em
vez de num manual.

## `cd`, e as quatro coisas que ele aceita

```
cd /var/log        # absoluto: lá, a partir da raiz
cd logs            # relativo: para dentro de logs, daqui
cd ..              # um acima
cd                 # para casa — sem argumento nenhum
cd -               # de volta para onde você estava
```

**`cd` sem nada vai para casa.** Vale saber no primeiro dia, porque é o jeito confiável de sair de
qualquer lugar em que você se perdeu.

### Os três jeitos de recusar

```
ana@vm:~$ cd /nosuchplace
bash: cd: /nosuchplace: No such file or directory
ana@vm:~$ cd work/README.md
bash: cd: work/README.md: Not a directory
ana@vm:~$ cd /root
bash: cd: /root: Permission denied
```

Três falhas diferentes, três palavras diferentes, e a palavra é o diagnóstico:

| mensagem | o que está errado de verdade |
|---|---|
| `No such file or directory` | o caminho está errado — erro de digitação, ou você não está onde pensava |
| `Not a directory` | o caminho está certo e nomeia um **arquivo** |
| `Permission denied` | o caminho está certo e você não tem permissão de entrar (aula 4) |

Repare em quem fala: `bash:`, não `cd:`. **`cd` não é um programa** — não poderia ser, porque um
programa mudando o próprio diretório não mudaria o do shell. Ele é embutido no shell, e é por isso
que `man cd` não acha nada e `help cd` acha tudo. A seção 16 traçou essa linha.

## `ls`, e as sete opções que importam

`ls` puro dá nomes, em colunas, em ordem alfabética, escondendo tudo que começa com ponto:

```
ana@vm:~/work$ ls
Makefile  README.md  build  data  logs  notes  src
```

Todo o resto é uma destas:

| opção | faz | quando |
|---|---|---|
| `-l` | uma linha por item, com os detalhes | **o padrão que você realmente quer** |
| `-a` | inclui nomes ocultos, e `.` e `..` | procurando um dotfile |
| `-A` | inclui nomes ocultos, mas não `.` e `..` | o mesmo, com menos ruído |
| `-h` | tamanhos como `4.0K`, `196K`, `1.2G` | sempre, junto com `-l` |
| `-t` | mais novo primeiro | "o que mudou aqui?" |
| `-r` | inverte a ordem | com `-t`, para o mais novo ficar por último |
| `-S` | maior primeiro | "o que está enchendo isto?" |
| `-d` | o diretório em si, não o conteúdo | `ls -ld algumdir` |
| `-R` | desce em cada subdiretório | numa árvore pequena, ou numa longa espera |
| `-1` | um nome por linha, sem colunas | para alimentar outro comando |

Elas se combinam, e a ordem entre elas não importa:

```
ana@vm:~/work$ ls -lh
total 28K
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 build
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 data
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 src
```

A próxima seção lê essa listagem campo por campo. Três combinações valem ser aprendidas como
palavras, porque você vai usá-las pelo resto da carreira:

**`ls -la`** — tudo, com detalhes. A que se digita por reflexo.

**`ls -ltr`** — o mais novo embaixo, logo acima do seu prompt:

```
ana@vm:~/work$ ls -ltr
total 28
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 src
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 build
```

Num diretório com duzentos arquivos de log, essa é a única listagem útil, porque o que você quer é
a última linha impressa em vez de algo perdido no meio da rolagem.

**`ls -lSh`** — maior primeiro, tamanhos legíveis. O primeiro movimento quando um disco enche.

## `-a` e `-A`, e o ponto que esconde

```
ana@vm:~/hid$ ls
visible.txt
ana@vm:~/hid$ ls -a
.  ..  .cache  .config  .hidden.txt  visible.txt
ana@vm:~/hid$ ls -A
.cache  .config  .hidden.txt  visible.txt
```

Um diretório, três respostas. **Um nome que começa com ponto está oculto**, e esse é o mecanismo
inteiro — não existe atributo de "oculto" em lugar nenhum, só uma convenção que o `ls` respeita. A
seção 11 tratou da convenção; a seção 49 trata do que as pessoas guardam nesses arquivos.

`-A` é o `-a` sem `.` e `..`, e normalmente é o que você queria dizer.

## `-d`, e a pergunta que as pessoas fazem errado

```
ana@vm:~/work$ ls -ld logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
ana@vm:~/work$ ls -l logs
total 12
-rw-r--r-- 1 ana ana 440 Mar 26  2025 app.log
-rw-r--r-- 1 ana ana   8 Mar 19  2025 app.log.1
-rw-r--r-- 1 ana ana   0 Mar 26  2025 empty.log
-rw-r--r-- 1 ana ana  31 Mar 26  2025 error.log
```

Dado um diretório, o `ls` lista **o que está dentro dele**. `-d` diz *não, a coisa em si* — que é o
que você quer quando a pergunta é sobre a permissão, o dono ou a data do próprio diretório.

Você vai precisar disso o tempo todo na aula 4, e é a opção que iniciante nunca encontra porque o
manual a descreve como "list directories themselves, not their contents" e ninguém lê essa linha
antes de já saber o que ela quer dizer.

## Uma surpresa que vale encontrar agora

```
ana@vm:~/work$ ls -l /bin
lrwxrwxrwx 1 root root 7 Apr 22  2024 /bin -> usr/bin
ana@vm:~/work$ ls -ld /bin/
drwxr-xr-x 2 root root 36864 Mar 31 13:31 /bin/
```

`/bin` é um link simbólico para `usr/bin`. Com `-l`, o `ls` mostra **o link**. Acrescente uma barra
no final e ele segue o link e mostra **o diretório**. Os mesmos sete caracteres digitados, duas
perguntas diferentes feitas.

A seção 46 é sobre links. O hábito a levar daqui é menor e imediatamente útil: **uma barra no final
quer dizer "através dele, para dentro da coisa"** — e quando uma listagem te surpreender, confira se
o que você está olhando não é um link.
