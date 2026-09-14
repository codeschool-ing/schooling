---
title: Dotfiles, e os arquivos que não são arquivos
version: 1
---

Dois tipos de coisa na árvore não são o que parecem. O primeiro fica oculto por uma convenção tão
fina que é quase uma piada. O segundo não está em disco nenhum.

## Um ponto na frente, e o mecanismo é esse

```
bruno@vm:~$ ls
projects
bruno@vm:~$ ls -a
.  ..  .bash_logout  .bashrc  .cache  .config  .gitconfig  .local  .profile  .ssh  projects
```

Um diretório, duas respostas. **Não existe atributo de "oculto".** O `ls` pula nomes que começam
com `.` a menos que você peça, e o `*` do shell também (seção 45). Nada mais está envolvido:
renomeie `notas.txt` para `.notas.txt` e ele está oculto; renomeie de volta e não está.

Essa convenção existe porque seu diretório pessoal seria inutilizável sem ela. Todo programa que
você roda guarda as configurações ali, e nenhuma delas é coisa que você queira ver quando está
procurando os seus próprios arquivos.

### O que mora neles

| | guarda |
|---|---|
| `.bashrc`, `.profile` | as configurações do seu shell — aula 9 |
| `.ssh/` | chaves e hosts conhecidos. **O diretório mais sensível que você tem** |
| `.gitconfig` | seu nome, seu e-mail, seus aliases |
| `.config/` | o lugar moderno: um subdiretório por programa |
| `.local/` | programas e dados instalados só para você |
| `.cache/` | descartável. Seguro de apagar, e frequentemente grande |

```
bruno@vm:~$ cat .gitconfig
[user]
        name = Bruno
        email = bruno@example.com
```

Texto puro, como todo o resto. É o ponto que a seção 37 fez sobre o `/etc`, um nível abaixo: **suas
configurações são arquivos que você pode ler, comparar e copiar para outra máquina.**

### O `.ssh` é o que exige cuidado

```
bruno@vm:~$ ls -ld .ssh
drwx------ 2 bruno bruno 4096 Sep 14 22:27 .ssh
bruno@vm:~$ ls -la .ssh
total 12
drwx------ 2 bruno bruno 4096 Sep 14 22:27 .
drwxr-x--- 7 bruno bruno 4096 Sep 14 22:27 ..
-rw------- 1 bruno bruno   42 Sep 14 22:27 config
```

`drwx------` no diretório, `-rw-------` no que está dentro: ninguém além do dono, de jeito nenhum.
**O `ssh` confere isso e se recusa a funcionar se estiver errado**, o que é o comportamento certo e
pega todo mundo uma vez, normalmente depois de copiar uma chave de algum lugar com um `cp`
descuidado. A aula 4 torna esses caracteres legíveis.

### E o `.cache` é o que se apaga

```
bruno@vm:~$ du -sh .cache
8.0K    .cache
```

Oito kilobytes numa conta nova, e gigabytes numa conta em uso. Quando a caçada da seção 48 leva a
um diretório pessoal, o `~/.cache` costuma ser a resposta, e apagá-lo custa só o tempo de
reconstruir o que estava lá.

## `/proc` é o kernel, fingindo ser arquivos

```
ana@vm:~$ ls -ld /proc /sys
dr-xr-xr-x 91 root root 0 Sep 14 21:50 /proc
dr-xr-xr-x 12 root root 0 Sep 14 21:58 /sys
```

Tamanho zero, nos dois. Nada aqui está guardado em lugar nenhum. O `/proc` é um **sistema de
arquivos que o kernel inventa conforme você lê** — e é a expressão mais pura do "tudo é um arquivo"
da aula 1.

Faça uma pergunta e ele responde:

```
ana@vm:~$ cat /proc/uptime
2142.03 8389.82
ana@vm:~$ cat /proc/loadavg
0.00 0.02 0.00 1/112 2104
ana@vm:~$ head -3 /proc/meminfo
MemTotal:       16482220 kB
MemFree:        15875500 kB
MemAvailable:   15912844 kB
ana@vm:~$ grep 'model name' /proc/cpuinfo | head -1
model name      : Intel(R) Xeon(R) Processor @ 2.10GHz
```

Aqueles números não existiam antes de você perguntar. Aqui está a prova, e ela vale um momento:

```
ana@vm:~$ ls -l /proc/uptime
-r--r--r-- 1 root root 0 Sep 14 21:50 /proc/uptime
ana@vm:~$ wc -c /proc/uptime
16 /proc/uptime
```

**O `ls` diz que o arquivo tem zero bytes. O `wc` leu dezesseis.** O `ls` perguntou o tamanho e o
kernel disse zero, porque não há conteúdo parado em lugar nenhum para ter tamanho. O `wc` abriu, e
o kernel gerou a resposta na hora.

**Por que isso importa além do truque:** quer dizer que toda ferramenta que você já conhece
funciona sobre o sistema em execução. `cat`, `grep`, `head`, `wc` — sem API, sem cliente especial.
O `top` e o `ps` da aula 6 estão lendo o `/proc` e formatando para você; a aula 11 vai lá direto
quando o `top` não basta.

### Os diretórios numerados são processos

```
ana@vm:~$ ls /proc | head -20
1
10
104
11
1147
1163
12
...
```

Um diretório por processo em execução, com o nome sendo o PID. Dentro de cada um está tudo sobre
ele — o que está rodando, o que tem aberto, quanta memória segura. E existe um atalho:

```
ana@vm:~$ readlink /proc/self/exe
/usr/bin/readlink
```

`/proc/self` é *o processo que está lendo*. Então o `readlink` perguntou qual programa ele era, e a
resposta foi ele mesmo. A aula 6 mora nesses diretórios.

### `/proc/sys` é diferente: dá para escrever

O `/proc/sys` guarda ajustes do kernel em vez de fatos do kernel, e escrever um valor num desses
arquivos muda o kernel em execução na hora:

```
ana@vm:~$ cat /proc/sys/kernel/hostname
vm
```

O `sysctl` é a fachada educada para os mesmos arquivos, e o `/etc/sysctl.conf` é onde se põe uma
mudança para ela sobreviver a um reboot — porque nada em `/proc` sobrevive.

## `/sys` é o hardware, arrumado como árvore

```
ana@vm:~$ cat /sys/class/net/lo/mtu
65536
```

Mesma ideia, assunto diferente: o `/proc` cresceu em torno de processos e foi acumulando o resto, e
o `/sys` foi construído depois para expor dispositivos e drivers numa estrutura que faz sentido.
Nível de bateria, brilho da tela, ajustes de interface de rede, quais discos existem — tudo
legível, muita coisa gravável como root.

Você vai encontrá-lo por meio de outras ferramentas muito antes de ir lá por conta própria.

## Os dispositivos em `/dev` que não são dispositivos

```
ana@vm:~$ ls -l /dev/null /dev/zero /dev/urandom /dev/tty
crw-rw-rw- 1 root root 1, 3 Sep 14 21:50 /dev/null
crw-rw-rw- 1 root root 5, 0 Sep 14 21:50 /dev/tty
crw-rw-rw- 1 root root 1, 9 Sep 14 21:50 /dev/urandom
crw-rw-rw- 1 root root 1, 5 Sep 14 21:50 /dev/zero
```

`c` na primeira coluna — o campo 1 da seção 41 — de *character device*. E onde estaria o tamanho,
dois números: o major e o minor do dispositivo, que é como o kernel sabe a qual driver entregar a
requisição.

Nenhum desses quatro é hardware. São comportamentos vestidos de arquivo.

| | ler dá | escrever nele |
|---|---|---|
| `/dev/null` | nada, na hora | descarta |
| `/dev/zero` | bytes zero sem fim | descarta |
| `/dev/urandom` | bytes aleatórios sem fim | mexe no reservatório |
| `/dev/tty` | o que você digitar | aparece no seu terminal |

```
ana@vm:~$ echo 'goes nowhere' > /dev/null
ana@vm:~$ cat /dev/null
ana@vm:~$ wc -c < /dev/null
0
```

**O `/dev/null` é o que você vai usar o tempo todo.** O `2>/dev/null` da seção 44 é exatamente
isso: mande o fluxo de erro para a coisa que joga tudo fora. Não é um recurso especial do shell. É
um arquivo, e escrever nele por acaso não faz nada.

```
ana@vm:~$ head -c 8 /dev/zero | od -c
0000000  \0  \0  \0  \0  \0  \0  \0  \0
0000010
ana@vm:~$ head -c 8 /dev/urandom | od -An -tx1
 e1 6d 57 c2 d5 97 26 ca
```

O `/dev/zero` enche coisas: `dd if=/dev/zero of=disk.img bs=1M count=64` é como a imagem de 64 MB
da seção 47 foi feita. O `/dev/urandom` é de onde todo gerador de senha e todo nome de arquivo
aleatório desta máquina tira os bytes.

**E eles são infinitos.** `cat /dev/zero > arquivo` não termina; ele para quando o disco enche.
Vale saber antes de tentar.
