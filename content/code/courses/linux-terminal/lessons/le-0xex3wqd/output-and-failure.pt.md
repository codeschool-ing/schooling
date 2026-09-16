---
title: O cron te manda e-mail, até alguém impedir
version: 1
---

**Qualquer coisa que um job do cron escreva na saída padrão ou na saída de erro é
mandada para você por e-mail.** Esse é o mecanismo inteiro de relatar erro, ele é
de 1975, e é melhor que o que a maioria das pessoas põe no lugar dele.

```
ana@vm:~$ grep "^Subject:" /var/mail/ana
Subject: Cron <ana@vm> report.sh (failed)
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
Subject: Anacron job 'daily-report' on vm
Subject: Anacron job 'weekly-report' on vm
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
Subject: Cron <ana@vm> report.sh (failed)
```

Seis mensagens, de quatro jobs. **A linha de assunto é o comando**, e `(failed)`
quer dizer que ele saiu com status diferente de zero. Um job que dá certo em
silêncio não manda nada.

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

O cron registra todo início e todo fim, pelo syslog:

```
root@vm:~# grep CRON /var/log/syslog | tail -4
2026-09-15T12:38:01.113104+00:00 vm CRON[19857]: (ana) CMD ([19862] echo "plain ran at $(date +%T)" >> /home/ana/work/cron/plain.log)
2026-09-15T12:38:01.116771+00:00 vm CRON[19858]: (ana) END ([19860] echo "dow Tue only fired at $(date +%T)" >> /home/ana/work/cron/or3.log)
2026-09-15T12:38:01.117034+00:00 vm CRON[19857]: (ana) END ([19862] echo "plain ran at $(date +%T)" >> /home/ana/work/cron/plain.log)
2026-09-15T12:38:01.117359+00:00 vm CRON[19859]: (ana) END ([19861] echo "dom 13 OR dow Tue fired at $(date +%T)" >> /home/ana/work/cron/or.log)
```

**`CMD` é o cron iniciando o job e `END` é o job terminando**, com o usuário
entre parênteses e o comando como o cron o interpretou — repare no `%T` ali, sem
escape no log porque o cron já fez a substituição dele.

| onde olhar | em que |
|---|---|
| `grep CRON /var/log/syslog` | Debian, Ubuntu |
| `journalctl -u cron` ou `-u crond` | qualquer coisa com systemd |
| `/var/log/cron` | Red Hat, SUSE |

**O que o log não te diz é se o job funcionou** — o `END` aparece para um job que
saiu com 1 do mesmo jeito que para um que saiu com 0. O log responde *ele
começou*; o e-mail responde *ele funcionou*; e você precisa dos dois quando um
job que rodou toda noite por um ano para.

Mudanças num crontab também são registradas, que é a trilha de auditoria:

```
root@vm:~# grep -E "crontab\[" /var/log/syslog | tail -3
2026-09-15T12:36:37.464006+00:00 vm crontab[19813]: (root) LIST (ana)
2026-09-15T12:36:37.471514+00:00 vm crontab[19816]: (root) REPLACE (ana)
2026-09-15T12:38:25.419561+00:00 vm crontab[19902]: (ana) LIST (ana)
```

`REPLACE (ana)` é alguém instalando um crontab novo para a `ana` — o root, naquela
linha, e o `(root)` na frente diz quem. **Aquela entrada muitas vezes é a resposta
para "quando foi que este job mudou?"**

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
