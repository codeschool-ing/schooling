---
title: O registro da noite
version: 1
---

Enquanto você segue um runbook, **anote o que vê e o que faz, na hora em que faz**, uma linha de
cada vez, com a hora na frente. Não depois: o relato escrito na manhã seguinte é uma história,
arrumada por uma memória cansada na ordem em que as coisas deveriam ter acontecido. As linhas
escritas durante a noite são evidência, e três pessoas precisam delas — quem assume se você passa
o incidente adiante, quem escreve a revisão depois (lição 22 de db-reliability) e quem mantém o
runbook verdadeiro (a próxima seção).

Não é preciso ferramenta nenhuma, mas uma pequena tira todas as desculpas. Salve isto como
`~/bin/note` e torne-o executável:

```bash
#!/usr/bin/env bash
# note: add one line, with the time, to today's incident log.
#   note "df says 91%, pg_wal is 40G"
mkdir -p ~/incidents
printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" >> ~/incidents/"$(date +%F)".log
```

```sh
mkdir -p ~/bin
nano ~/bin/note
chmod +x ~/bin/note
```

O `~/.profile` do Ubuntu põe o `~/bin` no seu `PATH` quando ele existe no login, então saia e entre
de novo uma vez (ou rode `source ~/.profile`), e o `note` funciona de qualquer lugar. Cada chamada
acrescenta uma linha a um arquivo com o nome do dia, em `~/incidents`.

## O que vai numa linha

**O que você viu, com o número.** "df 91%" pode ser comparado com a próxima leitura; "disco bem
cheio" não pode. **O que você fez**, como o comando ou a letra da ação no runbook. **O que você
decidiu e por quê**, principalmente a decisão de não agir, porque o motivo é a primeira coisa
esquecida. **A quem você perguntou, e o que responderam**, já que uma resposta dada por telefone
não existe em nenhum outro lugar.

Este é o registro escrito enquanto se rodava o runbook da seção anterior, um `note` depois de cada
conferência:

```
ana@db:~$ cat incidents/$(date +%F).log
16:42:37  Alert: disk under PostgreSQL filling on db. Opened runbook disk-filling.
16:42:37  df: 54% used. Not 100%, writes still working.
16:42:38  pg_wal 657M, base 467M. Looking at slots.
16:42:38  slot standby1: inactive, retaining 649 MB. Asked its owner whether a replica still uses it.
16:42:38  log: no errors, checkpoints started by WAL volume.
16:42:38  table filler in db ana, 313 MB, created tonight. Not ours to delete: ticket for its owner.
16:42:39  standby1: owner confirms no replica uses it. Dropping it.
16:42:40  dropped standby1, ran CHECKPOINT.
16:42:40  verify: no slots. pg_wal 673M, recycled for reuse rather than removed, as expected. df 54%. Watching 15 min.
16:42:40  Closed. Follow-up: max_slot_wal_keep_size, and a check on slots in monitoring.
```

Na máquina de gravação o runbook inteiro rodou em uns três segundos, porque ninguém precisou
esperar uma resposta. Numa noite de verdade, os intervalos entre essas linhas são a história: vinte
minutos entre "Asked its owner" e "owner confirms" são vinte minutos de disco enchendo, e uma
revisão precisa ver isso. A última linha é a que as pessoas deixam de fora, e é o motivo pelo qual
o próximo incidente desse tipo talvez não aconteça; a próxima seção diz o que é feito dela.

## Quando uma linha não basta

O `script` grava uma sessão de terminal inteira, cada comando e tudo o que ele imprimiu, num
arquivo:

```sh
script -a ~/incidents/"$(date +%F)".typescript
```

Digite `exit` para parar. Ele não foi rodado aqui. Ele é completo onde o `note` é seletivo, e isso
corta para os dois lados: guarda a saída exata de cada comando para a revisão, e nada nele diz qual
dos duzentos comandos importou. Os dois juntos são o par útil — a gravação para o que aconteceu, as
notas para o que você achou que aquilo queria dizer.
