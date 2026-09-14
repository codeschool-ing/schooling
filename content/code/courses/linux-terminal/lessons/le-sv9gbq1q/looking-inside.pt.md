---
title: Olhar dentro sem abrir nada
version: 1
---

Sete comandos, e entre eles respondem toda pergunta que você tem sobre um arquivo, menos editá-lo.

| | responde |
|---|---|
| `file` | *que tipo de coisa é isto?* |
| `cat` | *me mostre tudo* |
| `less` | *me deixe folhear* |
| `head` | *as primeiras linhas* |
| `tail` | *as últimas linhas — e as novas conforme chegam* |
| `wc` | *quanto disso existe?* |
| `stat` | *tudo que o sistema de arquivos sabe* |

## `file` primeiro, sempre

```
ana@vm:~/work$ file README.md
README.md: ASCII text
ana@vm:~/work$ file src/main.c
src/main.c: C source, ASCII text
ana@vm:~/work$ file data/cache.bin
data/cache.bin: data
ana@vm:~/work$ file src
src: directory
ana@vm:~/work$ file logs/empty.log
logs/empty.log: empty
```

**O `file` não olha a extensão.** Ele lê os primeiros bytes e compara com um banco de assinaturas
conhecidas — que é por que consegue distinguir um arquivo C de um arquivo de texto qualquer, e por
que um `.txt` contendo um JPEG é reportado como JPEG. No Linux a extensão é uma pista para
humanos; nada no sistema é obrigado a respeitá-la.

```
ana@vm:~/work$ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=05dad2c279f7651722809fa75adba6bf9ab1c209, for GNU/Linux 3.2.0, stripped
```

Isso é um programa, e o `file` acabou de te contar a arquitetura para a qual foi compilado, que ele
precisa de bibliotecas compartilhadas, e que os símbolos de depuração foram removidos.

**Faça deste o primeiro comando que você roda num arquivo desconhecido**, porque o de baixo é o
`cat`, e `cat` na coisa errada é desagradável.

## `cat` imprime, e é só isso que ele faz

```
ana@vm:~/work$ cat data/report.csv
date,amount
2025-01-03,1200
2025-01-09,-340
2025-02-11,880
```

Ele não pagina, não quebra linha com bom senso e não para. Quatro linhas está ótimo; quarenta mil
passam voando e você fica no fim.

Duas opções valem ter:

```
ana@vm:~/work$ cat -n data/report.csv
     1  date,amount
     2  2025-01-03,1200
     3  2025-01-09,-340
     4  2025-02-11,880
```

`-n` numera as linhas. `-A` mostra as invisíveis — tabulações, espaços no fim, e os retornos de
carro de que tratou a seção 12 da aula 1.

E o nome: `cat` é abreviação de *concatenate*, porque era para isso que ele servia.

```
ana@vm:~/work$ cat README.md data/report.csv
# ledger

A small tool that reads a CSV and totals a column.

Build with `make`. Run with `./ledger data/report.csv`.
date,amount
2025-01-03,1200
2025-01-09,-340
2025-02-11,880
```

Dois arquivos, um fluxo. Imprimir um arquivo só é o caso degenerado para o qual todo mundo usa.

**`cat` num binário vai encher seu terminal de lixo** e pode deixá-lo incapaz de desenhar texto
direito, porque alguns desses bytes são sequências de escape que o terminal obedece. Se acontecer,
digite `reset` e aperte enter — às cegas, se preciso — e o terminal volta.

## `less` é como se lê algo longo

```
less /var/log/syslog
```

O `less` pagina, busca, e não carrega o arquivo inteiro para começar — ele abre um log de quatro
gigabytes instantaneamente. As teclas que vale conhecer são poucas:

| tecla | faz |
|---|---|
| `Space`, `b` | avança, volta — uma tela |
| `↑` `↓` | uma linha |
| `g`, `G` | o começo de tudo, o fim de tudo |
| `/palavra` | busca para a frente; `n` para a próxima, `N` para a anterior |
| `-S` | (na linha de comando) para de quebrar linhas longas |
| `F` | acompanha o arquivo crescer, como `tail -f` |
| `q` | sai |

**`q` é a primeira a aprender**, porque ficar preso dentro de um paginador que você não queria
abrir é uma experiência genuinamente comum na primeira semana.

Existe um mais antigo chamado `more`, que é o `less` com menos recursos — a piada no nome é
deliberada, e `less` é o que todo mundo usa.

## `head` e `tail`

```
ana@vm:~/work$ head -2 logs/app.log
app started
app ready
ana@vm:~/work$ tail -3 logs/app.log
app started
app ready
app handled a request
```

Dez linhas por padrão, `-n` para outra quantidade. Duas formas menos óbvias:

```
ana@vm:~/work$ tail -n +29 logs/app.log
app ready
app handled a request
```

`+29` quer dizer *da linha 29 em diante*, e não *as últimas 29*. Útil para pular um cabeçalho.

```
ana@vm:~/work$ head -c 40 data/cache.bin
```

`-c` conta bytes em vez de linhas. Quarenta bytes de um arquivo binário saem como quarenta bytes de
bobagem — mas só quarenta, que é o ponto: é o jeito limitado de espiar algo sobre o qual você não
tem certeza.

### `tail -f` é o que você mais vai usar

```
tail -f /var/log/nginx/error.log
```

Ele imprime o fim do arquivo e depois **fica**, imprimindo cada linha nova conforme ela é escrita.
É assim que se observa um serviço enquanto se provoca ele: `tail -f` num terminal, a requisição que
falha em outro. `Ctrl+C` para parar.

`tail -F` — maiúsculo — continua acompanhando mesmo se o arquivo for apagado e recriado, que é
exatamente o que acontece quando os logs rotacionam à meia-noite. A aula 5 volta a isso com
`journalctl -f`.

## `wc` conta

```
ana@vm:~/work$ wc logs/app.log
 30  80 440 logs/app.log
```

Três números, sempre nesta ordem: **linhas, palavras, bytes**. Peça um deles e ele imprime só
aquele:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -c README.md
118 README.md
```

Dê vários arquivos e ele acrescenta um total:

```
ana@vm:~/work$ wc -l logs/*.log
 30 logs/app.log
  0 logs/empty.log
  1 logs/error.log
 31 total
```

`wc -l` é a ferramenta de contagem mais usada no Linux, porque ela fica no fim de um pipe: *quantos
arquivos casaram, quantas linhas tinham aquela palavra, quantos processos estão rodando.* A aula 8
é onde isso vira reflexo.

## `stat` é o registro inteiro

```
ana@vm:~/work$ stat README.md
  File: README.md
  Size: 118             Blocks: 8          IO Block: 4096   regular file
Device: 254,0   Inode: 573447      Links: 1
Access: (0644/-rw-r--r--)  Uid: ( 1001/     ana)   Gid: ( 1002/     ana)
Access: 2026-09-14 22:02:12.911149501 +0000
Modify: 2025-03-22 14:30:00.000000000 +0000
Change: 2026-09-14 21:58:33.143136437 +0000
 Birth: 2026-09-14 21:58:33.115136436 +0000
```

Tudo que o `ls -l` mostra e várias coisas que ele não mostra. Duas importam:

**O número do inode** — `573447` — é o nome que o sistema de arquivos dá a estes dados, e a seção
46 é construída em cima dele.

**Três marcas de tempo, não uma:**

| | muda quando |
|---|---|
| **Access** (atime) | o conteúdo é lido |
| **Modify** (mtime) | o conteúdo muda — *é este que o `ls -l` mostra* |
| **Change** (ctime) | o conteúdo **ou os metadados** mudam — um rename, um `chmod`, um novo dono |

A distinção paga o aluguel no dia em que alguém jura que não mexeu num arquivo. O `mtime` diz que o
conteúdo é de março. O `ctime` diz que algo no arquivo mudou hoje — então a permissão ou o nome
mudou, e essa é outra conversa.

**`Birth` é a hora de criação**, e é a mais nova das quatro: sistemas de arquivos antigos não
registravam isso, e muita ferramenta ainda ignora. Não construa nada em cima dela sem conferir que
está lá.

`stat -c` imprime só o campo que você pediu, que é o que se quer dentro de um script:

```
ana@vm:~/work$ stat -c '%s %n' README.md
118 README.md
```
