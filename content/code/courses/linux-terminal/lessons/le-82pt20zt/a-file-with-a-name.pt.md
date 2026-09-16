---
title: Um script são os comandos que você já digita, num arquivo
version: 1
---

Não há linguagem nova nesta aula. **Um script de bash é um arquivo com os comandos que você teria
digitado**, e o primeiro deles tem uma linha.

```
ana@vm:~/work/scripts$ printf '%s\n' 'echo "hello from a file"' > greeting.sh
ana@vm:~/work/scripts$ cat greeting.sh
echo "hello from a file"
ana@vm:~/work/scripts$ ls -l greeting.sh
-rw-r--r-- 1 ana ana 25 Sep 15 09:58 greeting.sh
ana@vm:~/work/scripts$ greeting.sh
bash: greeting.sh: command not found
ana@vm:~/work/scripts$ ./greeting.sh
bash: ./greeting.sh: Permission denied
ana@vm:~/work/scripts$ bash greeting.sh
hello from a file
ana@vm:~/work/scripts$ chmod +x greeting.sh
ana@vm:~/work/scripts$ ./greeting.sh
hello from a file
```

Quatro tentativas, três resultados diferentes, e cada um é uma regra.

| | |
|---|---|
| `greeting.sh` | **command not found** — o shell procura no `$PATH`, e `.` não está nele |
| `./greeting.sh` | **permission denied** — o arquivo é legível, mas não executável |
| `bash greeting.sh` | funciona — você está rodando o `bash` e entregando um arquivo para ele ler |
| `chmod +x` e aí `./` | funciona — agora o kernel executa o arquivo ele mesmo |

**O `./` não é enfeite.** Ele é um caminho, e é obrigatório porque o diretório atual está
deliberadamente fora do `$PATH` — se estivesse nele, um arquivo chamado `ls` largado num diretório
em que você por acaso entrou rodaria no lugar do de verdade. A aula 3 seção 04 tratou disso; aqui é
onde você sente.

## O shebang

O `bash greeting.sh` funcionou sem um, porque você mesmo nomeou o interpretador. O `./greeting.sh`
precisa que o arquivo o nomeie, e isso é a primeira linha:

```
#!/bin/bash
```

O `#!` é lido pelo kernel, não pelo bash. Ele diz: *rode este programa, e dê a ele este arquivo
como argumento.* É por isso que ele precisa ser os **dois primeiros bytes do arquivo** — não depois
de um comentário, não depois de uma linha em branco.

Erre e a mensagem nomeia a coisa errada:

```
ana@vm:~/work/scripts$ cat badshebang.sh
#!/usr/bin/bsh
echo never
ana@vm:~/work/scripts$ ./badshebang.sh
bash: ./badshebang.sh: cannot execute: required file not found
```

**O "required file" é o `/usr/bin/bsh`, não o `badshebang.sh`.** O script está bem ali e é legível;
o que falta é o interpretador. Essa mensagem já custou mais de uma hora a mais de uma pessoa, e
agora não vai custar uma sua.

## O `/bin/sh` não é o bash

```
ana@vm:~/work/scripts$ ls -l /bin/sh
lrwxrwxrwx 1 root root 4 Mar 31  2024 /bin/sh -> dash
ana@vm:~/work/scripts$ cat which.sh
echo "the shell running me is $0"
x=hello
if [[ $x == h* ]]; then echo "double brackets work"; fi
ana@vm:~/work/scripts$ bash which.sh
the shell running me is which.sh
double brackets work
ana@vm:~/work/scripts$ sh which.sh
the shell running me is which.sh
which.sh: 3: [[: not found
```

**No Debian e no Ubuntu, o `/bin/sh` é o `dash`** — um shell menor, mais rápido e estritamente
POSIX, escolhido porque os próprios scripts de boot do sistema rodam nele milhares de vezes. Ele
não tem `[[ ]]`, não tem arrays, e não tem a aritmética completa do `$(( ))`.

Então um script com `#!/bin/sh` que usa sintaxe de bash falha, e falha *no meio*:

```
ana@vm:~/work/scripts$ cat shebang.sh
#!/bin/sh
echo "argv zero is $0"
[[ x == x ]] && echo "bash-only syntax ran"
ana@vm:~/work/scripts$ ./shebang.sh
argv zero is ./shebang.sh
./shebang.sh: 3: [[: not found
```

A linha 2 rodou. A linha 3 não. **Um script que rodou pela metade é pior que um que não começou**,
e esta é a forma mais comum de produzir um.

A regra é curta: **se você está escrevendo bash, diga bash.** O `#!/bin/sh` é uma promessa de que o
arquivo não contém nada além de POSIX, e é uma promessa que a maioria das pessoas quebra sem
querer.

## `#!/bin/bash` ou `#!/usr/bin/env bash`

```
ana@vm:~/work/scripts$ type -a bash; command -v env
bash is /usr/bin/bash
bash is /bin/bash
/usr/bin/env
```

| | |
|---|---|
| `#!/bin/bash` | exatamente aquele arquivo. Ok no Linux, errado no macOS com um bash novo do Homebrew |
| `#!/usr/bin/env bash` | o primeiro `bash` do `$PATH`, seja qual for |

**O `env bash` é o portátil** e o padrão a adotar. O `/bin/bash` é o de usar quando você quer
especificamente o bash do sistema e não o de um usuário — um script de inicialização, algo rodando
como root, qualquer coisa em que o `$PATH` não é o seu.

## Rodar versus carregar

Esta é a distinção que pega todo mundo uma vez.

```
ana@vm:~/work/scripts$ cat goto.sh
#!/bin/bash
cd /tmp
echo "inside the script, pwd is $PWD"
VISITED=yes
ana@vm:~/work/scripts$ ./goto.sh
inside the script, pwd is /tmp
ana@vm:~/work/scripts$ pwd
/home/ana/work/scripts
ana@vm:~/work/scripts$ echo "VISITED is [${VISITED:-unset}]"
VISITED is [unset]
ana@vm:~/work/scripts$ source goto.sh
inside the script, pwd is /tmp
ana@vm:/tmp$ pwd
/tmp
ana@vm:/tmp$ echo "VISITED is [${VISITED:-unset}]"
VISITED is [yes]
```

**O `./goto.sh` começou um shell novo.** Ele trocou de diretório, definiu uma variável, e então
saiu — e tudo que mudou morreu junto. Repare no prompt: ele nunca se moveu.

**O `source goto.sh` rodou as mesmas linhas no shell em que você está sentado.** O prompt mudou
para `/tmp`, e o `VISITED` continua definido depois.

| | |
|---|---|
| `./script.sh` | um processo filho. Não consegue mudar seu diretório, suas variáveis nem seu shell |
| `bash script.sh` | a mesma coisa, escrita de outro jeito |
| `source script.sh` | o seu próprio shell roda as linhas. Tudo que ele faz, fica |
| `. script.sh` | o `source`, escrito do jeito POSIX |

**Um script não consegue mudar o diretório do shell que o rodou, e isso não é uma limitação para
contornar — é a razão de scripts serem seguros de rodar.** Quando você quer que o efeito fique, a
ferramenta é o `source`, e é por isso que coisas como o `activate` de um virtualenv de Python
mandam você carregá-las em vez de rodá-las.

## Onde colocar

O `./script.sh` a partir do diretório em que ele está funciona. Para algo que você vai rodar
sempre, ponha no `$PATH`:

```
mkdir -p ~/.local/bin
mv logreport.sh ~/.local/bin/logreport      # the .sh is only a habit, not a requirement
```

O `~/.local/bin` está no `$PATH` na maioria das distribuições modernas; o `echo $PATH` te diz. **A
extensão `.sh` não significa nada para o kernel** — quem decide o que roda é o shebang — e tirá-la
faz seu script parecer com qualquer outro comando, que é a ideia.
