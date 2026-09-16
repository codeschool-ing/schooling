---
title: Olhar um arquivo antes de processá-lo
version: 1
---

Todo pipeline desta aula começa do mesmo jeito: olhe uma linha e descubra quais são os campos. Pular
esse passo é como se escreve um `cut -f9` que pega a coluna errada.

```
ana@vm:~/work$ head -1 logs/access.log
10.0.1.6 - - [14/Sep/2026:06:01:23 +0000] "GET /static/app.js HTTP/1.1" 200 3484 "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" 87
```

Conte os campos separados por espaço e você tem o mapa que o resto da aula usa: o endereço é o `$1`,
o horário é o `$4` e o `$5`, o método é o `$6`, o caminho é o `$7`, o status é o `$9`, o tamanho é o
`$10`, e os milissegundos são o último.

## O `head` e o `tail`

```
ana@vm:~/work$ head -3 logs/app.log
app started
app ready
app handled a request
ana@vm:~/work$ tail -3 logs/app.log
app started
app ready
app handled a request
```

Os dois têm dez linhas como padrão. O `-n 3` e o `-3` são a mesma coisa.

**O `tail -n +29` é o que vale aprender**, porque o `+` muda o que o número quer dizer:

```
ana@vm:~/work$ tail -n +29 logs/app.log
app ready
app handled a request
```

"Da linha 29 até o fim", em vez de "as últimas 29". **É assim que se pula um cabeçalho** — o
`tail -n +2` num CSV descarta a primeira linha e mantém o resto, que é um padrão que você vai usar
o tempo todo com o `cut` da seção 08.

O `head -c 40` conta bytes em vez de linhas:

```
ana@vm:~/work$ head -c 40 logs/access.log; echo
10.0.1.6 - - [14/Sep/2026:06:01:23 +0000
```

Útil para olhar o começo de algo que talvez nem tenha linhas.

**E o `tail -f` acompanha um arquivo enquanto ele cresce** — a transcrição da aula 6 com o descritor
de `inotify` era exatamente isso. O `tail -F` é a versão que aguenta o arquivo ser rotacionado
debaixo dela, que num log você observa por mais de um minuto é a que você quer.

## O `cat`, e as duas opções que o tornam útil

O `cat` imprime arquivos inteiros. As opções úteis dele são sobre ver o que *não* é imprimível:

```
ana@vm:~/work$ cat -n logs/app.log | head -3
     1	app started
     2	app ready
     3	app handled a request
ana@vm:~/work$ cat -A logs/error.log
could not open data/report.csv$
```

O `-n` numera linhas. **O `-A` mostra o invisível**: `$` para o fim de uma linha, `^I` para uma
tabulação, e sequências `M-BM-` para bytes não-ASCII.

Essa última é o motivo de saber que o `cat -A` existe. Quando um arquivo de configuração não é
interpretado, ou um script falha numa linha que parece perfeita, o `cat -A` te mostra o espaço no
fim, a tabulação que devia ser espaços, ou o `^M` no fim de cada linha que quer dizer que o arquivo
veio do Windows.

O `nl` é o `cat -n` com mais controle sobre a numeração, e por padrão ele só numera linhas não
vazias:

```
ana@vm:~/work$ nl logs/app.log | head -3
     1	app started
     2	app ready
     3	app handled a request
```

**Para o que o `cat` não serve** é para alimentar um arquivo num comando. O `cat arquivo | grep x`
funciona, e o `grep x arquivo` faz a mesma coisa com um processo a menos. É um hábito inofensivo e
vale largar, porque a versão sem o `cat` é mais curta e deixa o `grep` nomear o arquivo na saída.

## O `less`, para quando não cabe

O `less` é um paginador de tela cheia, então não há nada para colar aqui — a mesma propriedade que o
`htop` tinha na aula 6. O que importa são as teclas:

| | |
|---|---|
| `Espaço`, `b` | avançar e voltar uma página |
| `g`, `G` | primeira linha, última linha |
| `/texto` | buscar para a frente; `n` para o próximo, `N` para o anterior |
| `?texto` | buscar para trás |
| `-N` | ligar números de linha |
| `F` | acompanhar, como o `tail -f`. O `Ctrl+C` para de acompanhar e te deixa no `less` |
| `q` | sair |

**O `less +F` num log é melhor que o `tail -f`**, porque o `Ctrl+C` te larga num paginador com tudo
que passou, em vez de encerrar o comando.

O `less` é também o que o `man` usa, que é por que aquelas teclas funcionam numa página de manual. E
o nome é uma piada com o `more`, o paginador mais antigo que ele substituiu, que só andava para a
frente.

## A ordem de fazer isso

1. **`head -1`** — como é uma linha?
2. **`wc -l`** — quanto tem?
3. **`head -20` ou `less`** — toda linha tem essa forma?

**O passo três é o que as pessoas pulam**, e é onde você descobre que o arquivo tem cabeçalho, ou
uma linha em branco entre registros, ou que cinquenta linhas no meio são um stack trace. O
`awk '{print NF}' | sort -u` da seção 14 é a versão rápida dessa conferência, e neste log ela acha
quatro contagens de campo diferentes em linhas que parecem todas iguais.
