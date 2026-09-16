---
title: Entrar na máquina, e qual arquivo roda quando
version: 1
---

Uma conta é uma linha num arquivo. Uma **sessão** é o que acontece quando alguém a usa — e as duas
são tão fáceis de confundir que os comandos de cada uma são diferentes.

## Quem está aqui, agora

```
root@vm:~# who
root@vm:~# w
 23:22:27 up  1:30,  0 user,  load average: 0.00, 0.02, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
root@vm:~# last -n 5
wtmp begins Tue Feb 17 02:02:53 2026
```

Três comandos, e nesta máquina os três estão vazios. **Essa é uma resposta de verdade e vale parar
nela**, porque é a resposta que você recebe na maioria dos contêineres.

`who`, `w` e `last` não olham processos. Eles leem dois arquivos — `/var/run/utmp` para as sessões
atuais e `/var/log/wtmp` para as passadas — e **alguém precisa escrever esses arquivos**. O `login`
escreve. O `sshd` escreve. Um shell iniciado por um runtime de contêiner, por um gerenciador de
processos, ou por um `docker exec`, não escreve.

Então: há shells rodando nesta máquina, e ninguém está logado. Os dois fatos são verdade ao mesmo
tempo, e falam de coisas diferentes.

Numa máquina com logins de verdade os mesmos comandos são densos:

| | mostra |
|---|---|
| `who` | uma linha por sessão: usuário, terminal, início, de onde |
| `w` | o mesmo, mais **o que cada uma está rodando** e há quanto tempo está parada |
| `last` | o histórico, do mais novo ao mais velho, do `wtmp` |
| `last -f /var/log/btmp` | as tentativas que **falharam**, onde se olha depois de uma invasão |
| `lastlog` | o último login por conta, incluindo as que nunca entraram |

O cabeçalho do `w` é a saída do `uptime` — tempo de máquina, contagem de sessões, carga média — e a
aula 6 desmonta esse último número.

## Shell de login contra shell interativo, e por que isso decide o que roda

O bash lê arquivos de inicialização diferentes conforme foi iniciado, e isso derruba todo mundo
pelo menos uma vez.

```
ana@vm:~$ shopt login_shell
login_shell     off
ana@vm:~$ bash -lc 'shopt login_shell'
login_shell     on
ana@vm:~$ bash -c 'shopt login_shell'
login_shell     off
```

Três shells, uma máquina, e a flag difere. Eis o que ela seleciona:

| como o shell começou | lê |
|---|---|
| **shell de login** — ssh, login no console, `su -`, `bash -l` | `/etc/profile`, depois o primeiro entre `~/.bash_profile`, `~/.bash_login`, `~/.profile` |
| **interativo, não login** — uma aba nova de terminal, `bash` | `/etc/bash.bashrc`, depois `~/.bashrc` |
| **não interativo** — um script, `ssh host 'comando'` | nenhum; só o `$BASH_ENV`, se estiver definido |

**Essa terceira linha é a que custa uma tarde.** Um `PATH` que você define no `~/.bashrc` funciona
quando você entra e está ausente quando uma tarefa do cron ou um `ssh host 'algumcomando'` roda. O
conserto é pôr onde o shell vá de fato olhar, ou não depender de um shell.

No Debian e no Ubuntu os dois são costurados de propósito. O `~/.profile` contém:

```
ana@vm:~$ head -5 ~/.profile
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
```

e mais abaixo ele carrega o `~/.bashrc` se o shell for interativo. É por isso que pôr coisas no
`~/.bashrc` normalmente funciona — alguém arranjou para funcionar. É convenção, não regra, e é por
isso que os mesmos dotfiles se comportam diferente noutra distribuição.

**A divisão prática**, e vale seguir:

| | |
|---|---|
| `~/.profile` | ambiente: `PATH`, `EDITOR`, `LANG`. Coisas que um processo filho deve herdar |
| `~/.bashrc` | interação: aliases, prompt, opções de shell. Coisas que só uma pessoa precisa |

Um alias no `~/.profile` não faz nada de útil. Uma variável exportada no `~/.bashrc` funciona e é
reexportada a cada shell novo, o que é inofensivo e levemente bobo.

E o `~/.bash_logout` roda quando um shell de login termina — o lugar do `clear`, se você gosta
desse tipo de coisa.

## Do que uma sessão é feita

Quando o `login` ou o `sshd` te aceita, quatro coisas acontecem, nesta ordem:

1. sua **identidade** é definida — uid, grupo primário, e os grupos suplementares da aula 4 seção 08;
2. uma **sessão** é registrada no `utmp` e no `wtmp`;
3. seu shell do campo 7 do `/etc/passwd` é iniciado, como **shell de login**;
4. esse shell lê os arquivos acima, e imprime um prompt.

Cada um desses pode falhar sozinho, e a falha parece diferente em cada caso. Um shell errado no
campo 7 te dá uma conexão que fecha na hora. Um diretório pessoal que não existe te dá um shell em
`/` reclamando. Um grupo acrescentado enquanto você estava logado não está no passo 1 desta sessão —
o que é a seção 08 da aula 4, enunciada como sequência.

## Três perguntas e o comando de cada uma

```
ana@vm:~$ whoami        # qual conta eu sou
ana@vm:~$ id            # e que grupos contam para mim
ana@vm:~$ tty           # qual terminal é este
```

O `tty` imprime algo como `/dev/pts/1` num terminal e `not a tty` quando a entrada do shell é um
pipe ou um script. Essa resposta é genuinamente útil: **é como um programa decide se há um humano
olhando** — se usa cor, se faz uma pergunta, se desenha uma barra de progresso. A aula 8 volta a
isso quando um comando se comporta diferente num pipe do que se comportava na tela.
