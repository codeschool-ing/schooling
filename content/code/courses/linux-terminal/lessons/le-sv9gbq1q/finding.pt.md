---
title: Achar coisas: `find`
version: 1
---

O `find` tem fama de feio, e ela é merecida por um motivo: a sintaxe dele é mais velha que a de
quase todo comando que você vai usar, e não segue as regras da seção 07 da aula 1. As opções são
*palavras* com um traço só — `-name`, não `--name` — e a ordem entre elas muda o que acontece.

Aprenda a forma uma vez e ele para de ser estranho:

```
find   ONDE   O-QUE-CASAR   O-QUE-FAZER
```

**Onde** é um diretório de partida. **O que casar** são um ou mais testes. **O que fazer** é
opcional e o padrão é *imprimir*.

```
ana@vm:~/work$ find . -name '*.c'
./src/util.c
./src/main.c
```

Comece em `.`, case nomes terminados em `.c`, imprima. E ele desceu em `src` sem ser mandado — **o
`find` é recursivo por padrão**, que é a diferença entre ele e o `ls`.

## Os testes que vale conhecer

| teste | casa |
|---|---|
| `-name '*.log'` | pelo nome, diferenciando maiúsculas |
| `-iname 'readme*'` | pelo nome, ignorando maiúsculas |
| `-type f` / `-type d` / `-type l` | arquivos / diretórios / links simbólicos |
| `-size +100k` | maior que 100 KiB — também `M`, `G`, e `-` para menor |
| `-mtime -1` | alterado no último dia |
| `-mmin -5` | alterado nos últimos cinco minutos |
| `-newer algumarquivo` | alterado mais recentemente que aquele arquivo |
| `-empty` | zero bytes, ou um diretório vazio |
| `-user ana` | pertencente a alguém |
| `-perm 644` | com exatamente aquelas permissões (aula 4) |
| `-maxdepth 1` | não descer |

Alguns deles, rodados:

```
ana@vm:~/work$ find . -iname 'readme*'
./README.md
ana@vm:~/work$ find . -type d
.
./src
./notes
./logs
./data
./build
ana@vm:~/work$ find . -size +100k
./build/util.o
./build/ledger.o
ana@vm:~/work$ find . -empty
./logs/empty.log
```

**Ponha o padrão entre aspas.** `find . -name '*.c'` funciona; `find . -name *.c` pode não
funcionar, e o motivo é a seção 10 — o shell expande o asterisco antes de o `find` sequer rodar. As
aspas entregam o asterisco intacto ao `find`, e o `find` faz a comparação dele.

### Os testes de tempo, onde os números enganam

```
ana@vm:~/work$ find . -mtime -1
./logs
./logs/today.log
ana@vm:~/work$ find . -mtime +180 -name '*.md'
./notes/2025-01-plan.md
./notes/2025-02-plan.md
./README.md
```

`-mtime` conta **dias**, e o sinal é o significado inteiro:

| | quer dizer |
|---|---|
| `-mtime -1` | menos de 1 dia atrás — *recente* |
| `-mtime +180` | mais de 180 dias atrás — *antigo* |
| `-mtime 7` | na janela de 24 horas que começou 7 dias atrás — raramente o que alguém quer |

`-mmin` é o mesmo em minutos, e é o que se usa quando você está investigando algo que aconteceu
enquanto você olhava. Se você quer uma data de verdade em vez de uma contagem, o `-newermt` aceita
uma:

```
ana@vm:~/work$ find logs -type f -newermt '2025-03-20'
logs/empty.log
logs/error.log
logs/app.log
```

## Combinando testes

Dois testes lado a lado querem dizer **e**. Para **ou**, é preciso dizer:

```
ana@vm:~/work$ find . -name '*.c' -o -name '*.h'
./src/util.h
./src/util.c
./src/main.c
```

`-o` é ou, `!` é não, e parênteses agrupam — escapados, porque senão o shell os quer para si:
`find . \( -name '*.c' -o -name '*.h' \) -type f`.

`-type f -name '*.log'` se lê como *um arquivo, e com esse nome*, e esse "e" por justaposição é
como quase todo `find` real é construído.

## Fazer algo com o que você achou

`-exec` roda um comando em cada resultado. `{}` é o lugar do arquivo, e o conjunto termina com `\;`
ou `+`:

```
ana@vm:~/work$ find . -size +100k -exec ls -lh {} +
-rw-r--r-- 1 ana ana 196K Mar 26  2025 ./build/ledger.o
-rw-r--r-- 1 ana ana 196K Mar 26  2025 ./build/util.o
```

| terminação | faz |
|---|---|
| `\;` | roda o comando **uma vez por arquivo** |
| `+` | roda **uma vez**, com todos os arquivos como argumentos |

`+` é mais rápido e normalmente é o que você quer. `\;` é o que você precisa quando o comando
aceita exatamente um arquivo, como `mv {} /algum/lugar/`.

A barra invertida está ali porque o `;`, sem ela, terminaria o comando no entender do shell — a
mesma pergunta de "quem lê isto primeiro" do asterisco entre aspas.

**Existe também o `-delete`**, e ele merece um aviso:

```
find . -name '*.tmp' -delete
```

Funciona, é rápido, não diz nada, e vai alegremente apagar mil arquivos porque um padrão era mais
largo do que você imaginava. **Rode como um `find` simples antes.** O mesmo comando sem o `-delete`
imprime exatamente a lista que o `-delete` removeria, o que torna a conferência gratuita.

## Ler apesar do ruído

```
ana@vm:~/work$ find /etc -name 'hosts'
find: ‘/etc/redis’: Permission denied
find: ‘/etc/credstore.encrypted’: Permission denied
find: ‘/etc/polkit-1/rules.d’: Permission denied
/etc/hosts
find: ‘/etc/credstore’: Permission denied
find: ‘/etc/ssl/private’: Permission denied
```

A resposta está ali — `/etc/hosts`, na quarta linha — cercada de diretórios em que você não tem
permissão de olhar. Repare no **entrelaçamento**: as reclamações vão para a saída de erro e os
resultados para a saída padrão, e o terminal está te mostrando os dois fluxos misturados em tempo
real.

```
ana@vm:~/work$ find /etc -name 'hosts' 2>/dev/null
/etc/hosts
```

`2>/dev/null` joga fora o fluxo de erro. A aula 8 explica o que é aquele `2`; por ora é o idiom que
torna o `find` usável fora do seu diretório pessoal, e você vai digitá-lo o tempo todo.

## `locate`, e por que ele não está instalado

Existe um segundo jeito de buscar, e ele funciona de um jeito completamente diferente:

```
ana@vm:~$ locate report.csv
bash: locate: command not found
```

O `locate` não vasculha o disco. Ele consulta um **banco de dados** que uma tarefa noturna monta
percorrendo o sistema de arquivos inteiro uma vez. Isso o deixa quase instantâneo numa máquina com
milhões de arquivos, e o deixa errado sobre qualquer coisa criada desde a última montagem do banco.

No Ubuntu ele não vem instalado — `apt install plocate`, e depois `sudo updatedb` para construir o
índice pela primeira vez.

| | `find` | `locate` |
|---|---|---|
| olha para | o sistema de arquivos real, agora | um índice, de ontem à noite |
| velocidade | proporcional à árvore | instantâneo |
| acha um arquivo criado há um minuto | sim | não |
| testa tamanho, tempo, dono, tipo | sim | não |

Use o `locate` quando você lembra mais ou menos de um nome de arquivo em algum lugar de uma máquina
grande. Use o `find` para todo o resto — e para qualquer coisa em que errar importa.
