---
title: Descritores de arquivo, e ler um processo pelo `/proc`
version: 1
---

Um processo não segura nomes de arquivo. Ele segura **números**, e cada número é uma entrada numa
tabela que o kernel mantém para ele — um descritor de arquivo. Abrir um arquivo te dá o próximo
número livre; ler e escrever usam o número e nunca mais o nome.

Três deles estão sempre lá, por uma convenção que tudo obedece:

| | | |
|---|---|---|
| `0` | **stdin** | de onde a entrada vem |
| `1` | **stdout** | para onde a saída vai |
| `2` | **stderr** | para onde os erros vão |

É por isso que o `2>&1` é escrito desse jeito: não é pontuação, é **"faça o descritor 2 virar uma
cópia do descritor 1"**.

## Olhando um de verdade

Um `tail -f`, iniciado com a saída e os erros redirecionados para arquivos diferentes:

```
ana@vm:~/work$ tail -f logs/app.log > /tmp/out.txt 2>/tmp/err.txt &
ana@vm:~/work$ FDPID=$!
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
lr-x------ 1 ana ana 64 Sep 15 07:23 3 -> /home/ana/work/logs/app.log
lr-x------ 1 ana ana 64 Sep 15 07:23 4 -> anon_inode:inotify
```

**Tudo que o redirecionamento fez está visível como número.** O `1` é `/tmp/out.txt` e o `2` é
`/tmp/err.txt`, porque é isso que o `>` e o `2>` são: eles montam descritores antes do `exec`, na
lacuna entre o `fork` e o `exec` da seção 03. O `0` é `/dev/null` porque esta era uma tarefa em
segundo plano.

O `3` é o arquivo que o `tail` de fato abriu — o primeiro número livre depois dos três que ele
recebeu. O `4` é um descritor de `inotify`, que é como o `-f` fica sabendo que o arquivo mudou sem
perguntar num laço.

E leia a primeira letra do modo: `lr-x` para os abertos para leitura, `l-wx` para os abertos para
escrita. **Os bits de modo da aula 4, descrevendo uma direção em vez de uma permissão.**

## O resto do `/proc/PID`

```
ana@vm:~/work$ cat /proc/$FDPID/cmdline | tr '\0' ' '; echo
tail -f logs/app.log 
ana@vm:~/work$ ls -l /proc/$FDPID/cwd /proc/$FDPID/exe
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/cwd -> /home/ana/work
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/exe -> /usr/bin/tail
```

| | |
|---|---|
| `cmdline` | os argumentos, **separados por nulos** — daí o `tr` |
| `exe` | um symlink para o programa |
| `cwd` | um symlink para o diretório de trabalho dele |
| `environ` | o ambiente dele, também separado por nulos |
| `status` | um resumo legível: estado, threads, memória, uid |
| `fd/` | a tabela acima |

**Estes são a resposta quando um processo está fazendo algo e você não pode perguntar a ele.** O
`cwd` te diz onde ele acha que está, o que explica um caminho relativo que resolve em algum lugar
surpreendente. O `exe` te diz qual binário ele realmente é, que é como você descobre que o `python3`
rodando não é o que está no seu `PATH`.

O `lsof -p PID` imprime a mesma informação com nomes em vez de números, e bem mais que isso:

```
ana@vm:~/work$ lsof -p $FDPID 2>/dev/null | head -8
COMMAND  PID USER   FD      TYPE DEVICE SIZE/OFF    NODE NAME
tail    1402  ana  cwd       DIR  254,0     4096  573441 /home/ana/work
tail    1402  ana  rtd       DIR  254,0     4096       2 /
tail    1402  ana  txt       REG  254,0    64032  151626 /usr/bin/tail
tail    1402  ana  mem       REG  254,0  2125328  152035 /usr/lib/x86_64-linux-gnu/libc.so.6
tail    1402  ana  mem       REG  254,0   360460  151717 /usr/lib/locale/C.utf8/LC_CTYPE
tail    1402  ana  mem       REG  254,0       50  151724 /usr/lib/locale/C.utf8/LC_NUMERIC
tail    1402  ana  mem       REG  254,0     3360  151727 /usr/lib/locale/C.utf8/LC_TIME
```

A coluna `FD` é onde os números estariam; `cwd`, `rtd` e `txt` não são descritores mas o diretório de
trabalho, o diretório raiz e o executável, e as linhas `mem` são bibliotecas mapeadas. **O `lsof` é a
ferramenta mais amigável e o `/proc` é a que está sempre instalada.**

## O truque que vale a seção inteira

Apague um arquivo que algo ainda tem aberto, e o espaço não volta.

```
ana@vm:~/work$ ls -lh /tmp/big.bin
-rw-r--r-- 1 ana ana 2.0G Sep 15 08:19 /tmp/big.bin
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   13G   25G  34% /
ana@vm:~/work$ tail -f /tmp/big.bin > /dev/null &
[1] 3200
ana@vm:~/work$ P=$!
ana@vm:~/work$ rm /tmp/big.bin
ana@vm:~/work$ ls /tmp/big.bin
ls: cannot access '/tmp/big.bin': No such file or directory
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   13G   25G  34% /
ana@vm:~/work$ ls -l /proc/$P/fd/3
lr-x------ 1 ana ana 64 Sep 15 08:20 /proc/3200/fd/3 -> '/tmp/big.bin (deleted)'
ana@vm:~/work$ kill $P
ana@vm:~/work$ df -h /tmp | tail -1
/dev/vda        252G   11G   27G  29% /
```

Leia as três linhas do `df`. **13G, depois 13G depois de apagar dois gigabytes, e depois 11G depois
de matar um processo que nem estava escrevendo nele.**

A seção 10 da aula 3 disse que o `rm` remove um nome, não um arquivo. Esta é a consequência: a
entrada de diretório sumiu — o `ls` não a acha — e os dados continuam lá porque **um descritor também
é uma referência**. O kernel libera os blocos quando o último nome e o último descritor aberto
sumiram, e não antes.

E o `/proc` diz isso em voz alta: `-> '/tmp/big.bin (deleted)'`.

**Esta é de longe a história mais comum de "o disco está cheio e eu não acho o que está usando".** O
log foi rotacionado, o arquivo antigo foi apagado, o serviço ainda o tem aberto, e o `du` não reporta
nada porque o `du` percorre nomes. Os comandos que o encontram:

```
lsof +L1                  # every open file with no name left
lsof -nP | grep deleted   # the same thing, cruder and more portable
```

E o conserto não é o `rm` — não sobrou nada para remover. **Reinicie ou sinalize o processo que o
segura**, o que para um log costuma ser um `kill -HUP`, dizendo ao daemon para reabrir os arquivos
dele. Esse é o hangup da seção 08 usado para o que ele de fato serve num servidor.

## Ficando sem eles

Uma tabela de descritores tem tamanho, e é um limite em que dá para bater:

```
ana@vm:~/work$ ulimit -n
20000
ana@vm:~/work$ ulimit -u
64318
```

O `ulimit -n` é o número máximo de arquivos abertos para um processo. **Vinte mil parece muito e um
servidor ocupado chega lá**, porque toda conexão de rede também é um descritor — a mesma tabela, os
mesmos números.

`Too many open files` num log quer dizer exatamente isso, e é quase sempre um vazamento: algo abre e
nunca fecha. O `ls -l /proc/PID/fd | wc -l` os conta, e a lista normalmente nomeia o culpado
repetindo uma coisa milhares de vezes.

O `ulimit -a` imprime o conjunto inteiro, e o `LimitNOFILE=` num arquivo de unit é onde a versão
disso para um serviço é configurada — a aula 5 de novo, porque um serviço não recebe os limites do
seu shell.
