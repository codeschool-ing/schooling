---
title: Seis lugares onde um job do cron pode estar, e qual usar
version: 1
---

O seu crontab é um de seis. Um job que "não está no cron" normalmente está num
dos outros cinco.

| | de quem é | tem campo de usuário |
|---|---|---|
| `crontab -e` | seu | não |
| `/etc/crontab` | do root, à mão | **sim** |
| `/etc/cron.d/*` | do root, normalmente de um pacote | **sim** |
| `/etc/cron.hourly/`, `.daily/`, `.weekly/`, `.monthly/` | do root | não se aplica — são scripts |
| `/var/spool/cron/crontabs/*` | o spool por trás do `crontab -e` | não |
| timers do systemd | do root, ou seus | não se aplica |

## O `/etc/crontab`, que explica o resto

```
ana@vm:~$ cat /etc/crontab
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
# You can also override PATH, but by default, newer versions inherit it from the environment
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
47 6    * * 7   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
52 6    1 * *   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
```

**Aquelas quatro linhas são como o `/etc/cron.daily` funciona.** Não há mágica: um
job do cron roda o `run-parts`, e o `run-parts` roda todo executável do
diretório.

Leia também o `test -x /usr/sbin/anacron ||`. **Se o anacron estiver instalado, o
job diário não faz nada aqui**, porque o anacron vai rodar aqueles diretórios —
seção 09.

**O sexto campo é um nome de usuário.** O `/etc/crontab` e o `/etc/cron.d` têm um
e o seu próprio crontab não tem, que é o erro mais comum ao copiar uma linha de
um para o outro: cole uma linha do `/etc/cron.d` no `crontab -e` e o nome do
usuário é lido como o comando.

## O `/etc/cron.d`, onde os pacotes põem coisas

```
ana@vm:~$ cat /etc/cron.d/sysstat
# The first element of the path is a directory where the debian-sa1
# script is located
PATH=/usr/lib/sysstat:/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Activity reports every 10 minutes everyday
5-55/10 * * * * root command -v debian-sa1 > /dev/null && debian-sa1 1 1

# Additional run at 23:59 to rotate the statistics file
59 23 * * * root command -v debian-sa1 > /dev/null && debian-sa1 60 2
```

Aqueles são os dados do `sar` da aula 11 sendo coletados, a cada dez minutos, por
um arquivo que o pacote `sysstat` deixou aqui. **É aqui que se põe um job que
pertence a um serviço em vez de a uma pessoa** — um arquivo, um assunto,
removível apagando-o, e ele sobrevive a um `crontab -r`.

Duas regras que o diretório impõe, e as duas mordem:

**O nome do arquivo não pode conter um ponto.** O `run-parts` e o cron pulam
`backup.sh` e `myjob.cron`; chame de `backup`. É a mesma regra do
`/etc/cron.daily`, e um job que silenciosamente nunca roda normalmente é isso:

```
root@vm:~# ls /etc/cron.d
anacron  dotted.job  e2scrub_all  php  plainjob  sysstat
root@vm:~# cat /home/ana/work/cron/plain.log
plain ran at 12:38:01
root@vm:~# cat /home/ana/work/cron/dotted.log
cat: /home/ana/work/cron/dotted.log: No such file or directory
root@vm:~# run-parts --test /tmp/claude-0/rp
/tmp/claude-0/rp/alpha
```

Dois arquivos idênticos a não ser pelo nome. **O `plainjob` rodou. O `dotted.job`
não rodou nenhuma vez**, e nada em lugar nenhum reclamou. A última linha é o
`run-parts` fazendo o mesmo julgamento num diretório com um `alpha` e um
`beta.sh`: só o primeiro aparece.

**O arquivo precisa do `PATH` definido**, exatamente como o `sysstat` faz acima,
porque o ambiente não é o seu — seção 06.

## Os diretórios do `run-parts`

```
ana@vm:~$ run-parts --test /etc/cron.daily
/etc/cron.daily/0anacron
/etc/cron.daily/apt-compat
/etc/cron.daily/dpkg
/etc/cron.daily/sysstat
```

**O `--test` imprime o que rodaria e não roda nada**, que é o jeito de conferir
que o seu script está mesmo no conjunto antes de esperar um dia para descobrir.

Para acrescentar um job: ponha um script **executável** no diretório, com nenhum
ponto no nome. Essa é a interface inteira — sem campos de tempo, porque o
diretório é o tempo.

Eles rodam na ordem que o `run-parts` imprime, que é por que o `0anacron` se
chama `0anacron`.

## Qual usar

| | |
|---|---|
| um job seu, na sua conta | `crontab -e` |
| o job de um serviço, numa máquina que você configura | um arquivo no `/etc/cron.d` |
| algo que só precisa acontecer diariamente | um script no `/etc/cron.daily` |
| um job com dependências, ou que precisa do journal | um timer do systemd |
| nunca | o `/etc/crontab` editado à mão |

O último é uma preferência com uma razão: o `/etc/crontab` é o arquivo de um
pacote, e uma atualização de pacote pode te perguntar sobre as suas mudanças
nele. O `/etc/cron.d` foi feito para o que você está fazendo.
