---
title: O cron te manda e-mail, até alguém impedir
version: 2
---

**Qualquer coisa que um job do cron escreva na saída padrão ou na saída de erro é
mandada para você por e-mail.** Esse é o mecanismo inteiro de relatar erro, ele é
de 1975, e é melhor que o que a maioria das pessoas põe no lugar dele.

```
ana@vm:~$ grep "^Subject:" /var/mail/ana | sort | uniq -c
      6 Subject: Cron <ana@vm> echo "ran at $(date +
      6 Subject: Cron <ana@vm> report.sh
```

**Dois jobs, uma mensagem por minuto cada, enquanto estavam quebrados.** A linha
de assunto é o comando, e o corpo é o que ele imprimiu.

**O cron manda por e-mail a saída, não a falha.** Um job que falha sem imprimir
nada não manda nada — um `false` num crontab sai com 1 a cada minuto e a caixa
de correio nunca fica sabendo — e um job que dá certo fazendo barulho manda uma
mensagem toda vez que roda. É por isso que a correção da seção 06 mandou a saída
do `report.sh` para um arquivo: agora ele funciona, e mandaria `report ran` por
e-mail a cada minuto.

## A linha que esconde tudo

```sh
0 3 * * * /home/ana/bin/backup.sh >/dev/null 2>&1
```

**Você vai ver isso em todo runbook e normalmente está errado.** Ela joga fora a
saída padrão *e* a de erro, então:

- um job que falha toda noite por seis meses não conta para ninguém;
- o erro que teria nomeado o problema sumiu;
- e a única evidência que sobra é que os backups não estão lá.

Ela é escrita porque o job é tagarela e o e-mail é ruído, que é um problema real
com uma resposta melhor:

```sh
# keep the output, put it where you can read it
0 3 * * * /home/ana/bin/backup.sh >> /var/log/backup.log 2>&1

# or: say nothing when it works, mail when it does not
0 3 * * * /home/ana/bin/backup.sh > /tmp/backup.out 2>&1 || cat /tmp/backup.out
```

**A segunda é a forma a aprender.** O `||` roda só numa saída diferente de zero,
e o `cat` põe a saída na saída padrão, onde o cron a envia. Silêncio quer dizer
sucesso; e-mail quer dizer leia.

Para isso funcionar o job tem que **sair com status diferente de zero quando
falha**, que é o argumento inteiro da aula 9 a favor do `set -euo pipefail` e de
conferir o status de saída das coisas que você chama.

## O `MAILTO`

```sh
MAILTO=ops@example.com          # send it somewhere else
MAILTO=""                       # send it nowhere — the same as >/dev/null, once
MAILTO=ana                      # the default: the crontab's owner
```

Ele é uma linha no crontab e se aplica a **todo job abaixo dele**, então um
`MAILTO=""` no topo do arquivo silencia o arquivo.

Duas coisas sobre ele que importam mais do que parecem:

**O e-mail tem que ir para algum lugar.** Uma máquina sem agente de transporte de
correio instalado — que é a maioria dos contêineres e muitas imagens de nuvem —
não tem onde pôr, e a mensagem é descartada. O cron diz isso no log do sistema em
vez de dizer a você.

**O `MAILTO` não é monitoramento.** Um e-mail que chega às 03:04 e é lido na
quinta é um registro, não um alerta. A seção 16 é sobre a diferença.

## Como saber que rodou

O cron registra todo job que inicia, pelo syslog:

```
root@vm:~# grep CRON /var/log/syslog | tail -4
2026-10-07T14:35:01.962380+00:00 vm CRON[4813]: (root) CMD (command -v debian-sa1 > /dev/null && debian-sa1 1 1)
2026-10-07T14:35:02.033012+00:00 vm CRON[4814]: (ana) CMD (echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log)
2026-10-07T14:35:02.046340+00:00 vm CRON[4815]: (ana) CMD (/home/ana/work/cron/heartbeat.sh)
2026-10-07T14:35:02.080983+00:00 vm CRON[4817]: (ana) CMD (report.sh >> /home/ana/work/cron/report.log 2>&1)
```

**`CMD` é o cron iniciando o job**, com o usuário entre parênteses e o comando
como o cron o interpretou — repare no `%` ali, sem escape no log porque o cron já
fez a substituição dele.

| onde olhar | em que |
|---|---|
| `grep CRON /var/log/syslog` | Debian, Ubuntu |
| `journalctl -u cron` ou `-u crond` | qualquer coisa com systemd |
| `/var/log/cron` | Red Hat, SUSE |

**O que o log não te diz é se o job funcionou.** No Ubuntu ele registra o início
e mais nada — nem quando o job terminou, nem como. O log responde *ele começou*;
a saída, por e-mail ou num arquivo, responde *ele funcionou*; e você precisa das
duas quando um job que rodou toda noite por um ano para.

Mudanças num crontab também são registradas, que é a trilha de auditoria:

```
root@vm:~# grep -E "crontab\[" /var/log/syslog | tail -3
2026-10-07T14:31:57.411126+00:00 vm crontab[4736]: (ana) REPLACE (ana)
2026-10-07T14:33:09.341222+00:00 vm crontab[4795]: (ana) REPLACE (ana)
2026-10-07T14:35:39.573063+00:00 vm crontab[4825]: (ana) LIST (ana)
```

`REPLACE (ana)` é alguém instalando um crontab novo para a conta `ana`, e o nome
entre parênteses na frente diz quem fez isso: `(ana)` nestas linhas, porque a
conta mudou o próprio crontab, e `(root)` quando um administrador roda
`crontab -u ana`. **Aquela entrada muitas vezes é a resposta para "quando foi que
este job mudou?"**

## A falha que ninguém pega

Um job que roda, sai com 0, e não faz nada.

```sh
0 3 * * * cd /srv/app && ./backup.sh >> /var/log/backup.log 2>&1
```

Se o `/srv/app` sumiu, o `cd` falha, o `&&` para, e **a linha inteira sai com
status diferente de zero** — então esta aqui está bem, e o cron te manda e-mail.
Troque o `&&` por um `;` e não está: o `cd` falha, o script roda no diretório
errado, e o status de saída é o do script.

**`&&` entre um `cd` e o comando para o qual ele existe.** Toda vez.
