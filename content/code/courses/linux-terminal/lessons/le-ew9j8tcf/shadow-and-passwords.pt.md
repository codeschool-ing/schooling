---
title: `/etc/shadow`, e o que é uma senha guardada
version: 1
---

A conta `demo` foi criada para esta seção, e a senha dela é a string `example-password`. Eis o que
a máquina guardou:

```
root@vm:~# grep '^demo:' /etc/shadow
demo:$y$j9T$iladG9xXy9DklFOvrTOFd0$wisSqn5Qt6jQDW3xy9KJLj3qV2CE7IEoUIfRcRg2l.1:20710:0:99999:7:::
```

**A senha não está ali.** O que está ali é um hash: um valor calculado a partir da senha que não
pode ser revertido. Quando a `demo` digita algo num prompt de login, o sistema aplica o hash ao que
foi digitado e compara os dois hashes. Ele não tem como contar a ninguém qual é a senha, porque ele
não sabe.

É por isso que *"redefinimos sua senha"* é normal e *"sua senha é …"* num e-mail é um sinal
vermelho sobre o sistema que mandou.

## Lendo o campo do hash

```
$y$j9T$iladG9xXy9DklFOvrTOFd0$wisSqn5Qt6jQDW3xy9KJLj3qV2CE7IEoUIfRcRg2l.1
 ─┬─ ─┬─ ───────────┬───────── ─────────────────┬──────────────────────
  │   │             │                           └── o hash
  │   │             └── o salt
  │   └── parâmetros: quanto trabalho o hash custa
  └── o algoritmo
```

| prefixo `$` | algoritmo |
|---|---|
| `$y$` | yescrypt — o padrão do Debian e do Ubuntu desde 2021 |
| `$6$` | SHA-512 — o padrão anterior, ainda em toda parte |
| `$2b$` | bcrypt |
| `$1$` | MD5 — obsoleto, e um achado numa auditoria |

**O salt é a parte interessante.** Ele é aleatório, é diferente para cada conta, e fica guardado em
claro ao lado do hash. Duas pessoas com a mesma senha ganham hashes diferentes, então um atacante
que roube o arquivo não consegue quebrar todos de uma vez — e uma tabela pré-computada de senhas
comuns não vale nada, porque teria de ser recomputada por salt.

**E os parâmetros são o motivo de ele ser lento de propósito.** Calcular o hash de uma senha deve
levar uma fração perceptível de segundo. Você percebe uma vez, no login; um atacante tentando um
bilhão de palpites percebe um bilhão de vezes.

## Os outros oito campos

```
demo:HASH:20710:0:99999:7:::
```

| | é | aqui |
|---|---|---|
| 1 | nome | `demo` |
| 2 | hash | acima |
| 3 | última troca, em **dias desde 1970** | `20710` |
| 4 | dias mínimos antes de poder trocar de novo | `0` |
| 5 | dias máximos antes de ter de trocar | `99999` |
| 6 | dias de aviso antes disso | `7` |
| 7 | dias de tolerância após expirar | vazio |
| 8 | data de expiração da conta | vazio |
| 9 | reservado | vazio |

Ninguém lê isso a olho. O `chage -l` lê por você:

```
root@vm:~# chage -l demo
Last password change                                    : Sep 14, 2026
Password expires                                        : never
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 99999
Number of days of warning before password expires       : 7
```

`99999` dias são uns 273 anos, que é como se escreve "nunca" num campo que precisa guardar um
número.

## Envelhecimento, definido e lido de volta

```
root@vm:~# chage -M 90 -W 14 demo
root@vm:~# chage -l demo
Last password change                                    : Sep 14, 2026
Password expires                                        : Dec 13, 2026
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 90
Number of days of warning before password expires       : 14
```

`-M 90` define a idade máxima e `-W 14` o aviso. O `chage` calculou a data; o arquivo continua
guardando números de dias.

| | |
|---|---|
| `chage -l usuario` | ler os ajustes de envelhecimento |
| `chage -M 90 usuario` | precisa trocar em até 90 dias |
| `chage -E 2026-12-31 usuario` | a **conta** expira naquela data — para um contratado |
| `chage -d 0 usuario` | forçar uma troca no próximo login |

**O `chage -d 0` é o que vale saber.** Ele define "última troca" como a época, então a senha está
imediatamente vencida e o usuário é obrigado a definir uma nova ao entrar. É assim que se entrega
uma conta com senha temporária de forma honesta.

## Travar, e o que o `passwd -S` te conta

```
root@vm:~# passwd -S demo
demo P 2026-09-14 0 90 14 -1
root@vm:~# passwd -l demo
passwd: password changed.
root@vm:~# passwd -S demo
demo L 2026-09-14 0 90 14 -1
root@vm:~# passwd -u demo
passwd: password changed.
root@vm:~# passwd -S demo
demo P 2026-09-14 0 90 14 -1
```

O segundo campo é o estado:

| | |
|---|---|
| `P` | há uma senha utilizável definida |
| `L` | **travada** |
| `NP` | sem senha nenhuma — qualquer um entra |

O `passwd -l` trava pondo um `!` na frente do hash, de modo que nenhuma senha digitada consiga
resultar naquele valor. O `passwd -u` tira o `!` — e é por isso que o hash precisa continuar ali, e
por isso que travar é reversível.

**Travar a senha não impede uma chave ssh de funcionar.** Isso surpreende as pessoas no dia em que
alguém sai: `passwd -l` e a conta continua entrando por ssh, porque chaves nunca encostaram no
`/etc/shadow`. A seção 75 é onde isso mora; a versão com cinto e suspensórios é
`usermod -L -e 1 usuario`, que expira a própria conta.

Repare também que o `passwd -l` imprime `password changed.` — a única mensagem confusa desta seção,
e ela está dizendo a verdade de um jeito pouco útil. O campo guardado mudou mesmo.

## O que você vai de fato fazer com tudo isso

Quase nada, na maioria dos dias. Definir uma senha com `passwd`, forçar uma troca com `chage -d 0`,
travar uma conta quando alguém sai.

O que vale guardar é a forma: **uma senha é guardada como algo irreversível, num arquivo que só o
root lê, com um salt por conta** — e todo sistema que você construir para outras pessoas deveria
fazer o mesmo. O `-rw-r-----` da aula 4 naquele arquivo não é enfeite.
