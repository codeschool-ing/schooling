---
title: A coluna de estado, lida numa máquina de verdade
version: 1
---

Todo processo está num de um punhado de estados, e o `ps` imprime isso numa coluna chamada `STAT`.
É uma ou duas letras, e a maioria das pessoas nunca aprende o que elas querem dizer — o que é uma
pena, porque numa máquina se comportando de forma estranha a coluna de estado costuma ser onde está
a resposta.

Aqui está uma máquina real inteira, contada:

```
ana@vm:~/work$ ps -eo stat --no-headers | sort | uniq -c | sort -rn
     36 S
     24 I<
     15 I
      2 Ss
      2 Sl
      2 SN
      1 Z
      1 SLl
      1 SL
      1 R
```

**Oitenta e cinco processos e um deles está rodando.** Isso não é uma máquina quebrada — é uma
máquina saudável. Quase tudo num computador está dormindo quase o tempo todo, esperando uma tecla,
um pacote, um temporizador ou um disco.

## Os cinco estados

| | |
|---|---|
| `R` | **rodando**, ou pronto para rodar. Ele quer o processador |
| `S` | **dormindo**, de forma interruptível — esperando algo, e um sinal o acorda |
| `D` | **sono ininterruptível** — esperando o kernel, e um sinal **não** o acorda |
| `T` | **parado** — suspenso por um sinal, normalmente `Ctrl+Z`. Seção 10 |
| `Z` | **zumbi** — terminou, e o código de saída dele não foi recolhido |
| `I` | thread de kernel **ociosa**. Não é problema, e existem muitas |

**`R` não quer dizer "usando o processador agora".** Quer dizer que ele está na fila de execução —
ele usaria um processador se houvesse um livre. Essa distinção é a carga média inteira da seção 07.

## As letras extras depois do estado

O segundo e o terceiro caractere são marcadores, e três deles vale reconhecer:

| | |
|---|---|
| `s` | é um **líder de sessão** — normalmente um shell de login ou um daemon |
| `l` | é **multi-thread** — as threads da seção 02 |
| `<` | prioridade alta, um valor de nice negativo — seção 12 |
| `N` | prioridade baixa, um valor de nice positivo |
| `+` | está em **primeiro plano** no terminal dele — seção 10 |

Então `Ss` é um líder de sessão dormindo, que é o que o seu shell é. `SN` é algo dormindo e
educadamente despriorizado. `I<` é uma thread de kernel ociosa de prioridade alta, e há vinte e
quatro delas porque o kernel mantém muitos trabalhadores por perto sem fazer nada.

## `Z` — o zumbi, criado de propósito

Este programa bifurca um filho, deixa ele terminar, e nunca chama `wait`:

```
ana@vm:~/work$ cat zombie.py
#!/usr/bin/env python3
"""Fork a child, let it exit, and never wait for it. The kernel keeps the
child's entry in the process table because nobody has collected its status."""
import os, time

if os.fork() == 0:
    os._exit(0)          # the child is finished immediately
time.sleep(60)           # the parent does not call wait()
```

E aqui está o resultado:

```
ana@vm:~/work$ ps -eo pid,ppid,stat,comm,args | grep -E 'zombie|defunct' | grep -v grep
 1173     1 S    zombie.sh       /bin/bash ./zombie.sh
 1197  1192 S    runuser         runuser -u ana -- /home/ana/work/zombie.py
 1199  1197 S    python3         python3 /home/ana/work/zombie.py
 1200  1199 Z    python3         [python3] <defunct>
```

O `1200` é o zumbi. Ele está em `Z`, pertence ao `1199` — o pai que não vai recolhê-lo — e o `ps`
escreve `<defunct>` onde haveria uma linha de comando, entre colchetes, porque não há mais programa
para nomear.

A primeira linha é outro script, de uma tentativa anterior, ainda rodando, e ela está na saída só
porque tem a palavra `zombie` no nome. **É isso que procurar processos com `grep` te dá**: tudo cuja
linha de comando contém a string, relacionado ou não. O `pgrep` da seção 05 é a versão que não faz
isso com você.

**Um zumbi não está usando nada.** Nem memória, nem processador, nem arquivos abertos. O que ele
ocupa é uma entrada na tabela de processos e um PID.

**Então não se mata um zumbi**, e um `kill -9` nele não faz nada — você não sinaliza algo que já
terminou. O que se faz é uma de duas coisas:

- **esperar.** Quando o pai terminar, o zumbi é readotado pelo PID 1, que o recolhe na hora. Na
  transcrição acima, o zumbi desapareceu quando o `sleep 60` terminou.
- **consertar o pai.** Um punhado de zumbis é um programa com um bug. Milhares deles é um programa
  com um bug e uma máquina que logo não vai conseguir iniciar nada.

`ps aux | grep defunct` é como se procura por eles, e a linha `Tasks:` do `top` os conta para você.

## `D` — o que quer dizer que algo está errado

Sono ininterruptível quer dizer que o processo está dentro de uma chamada de kernel que não pode ser
interrompida no meio — quase sempre esperando entrada e saída. **Um processo em `D` não pode ser
morto, por ninguém, inclusive root, com sinal nenhum.** Não há mecanismo: sinais são entregues
quando um processo volta ao espaço de usuário, e ele não voltou.

Um instante em `D` é normal — toda leitura de disco passa por ali. **Um processo preso em `D` por
minutos é um sintoma**, e a causa quase sempre está abaixo dele:

- um sistema de arquivos de rede cujo servidor não responde;
- um disco que está falhando e tentando de novo;
- um dispositivo que sumiu enquanto algo o usava.

Reiniciar frequentemente é a única saída, e a aula 11 volta a isso quando uma máquina está lenta por
razões que o `top` não consegue mostrar.

## `T` — parado, e ele está esperando você

Um processo em `T` foi suspenso e não está usando nada. O `Ctrl+Z` põe a sua tarefa de primeiro
plano ali, e a seção 10 é sobre trazê-la de volta. `kill -STOP` põe qualquer processo ali, e
`kill -CONT` o retoma.

**Um processo parado parece morto e não está.** Ele segura a memória, os arquivos e as travas dele, e
um banco de dados suspenso na hora errada vai segurar uma trava que mais ninguém consegue pegar. É
por isso que o `-STOP` é ferramenta de diagnóstico e não jeito de pausar produção.
