---
title: O `crontab`, e a flag que apaga tudo
version: 1
---

Todo usuário pode ter um crontab. Ele é um arquivo, ele não fica no seu diretório
pessoal, e você nunca o edita onde ele mora.

| | |
|---|---|
| `crontab -l` | lista o seu |
| `crontab -e` | edita o seu, no `$EDITOR` — a cadeia da aula 12 |
| `crontab -r` | **apaga** o seu. Sem confirmação |
| `crontab arquivo` | substitui o seu pelo conteúdo do arquivo |
| `crontab -u ana -l` | o de outra pessoa, como root |

```
ana@vm:~/work/cron$ crontab -l
* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

Três jobs, a cada minuto. Dois deles estão quebrados de jeitos sobre os quais
tratam as próximas três seções, e esta seção é sobre os dois comandos, não sobre
as linhas.

## O `crontab -e` e o editor que você não escolheu

O `crontab -e` abre **um editor numa cópia temporária**, e a instala quando o
editor sai — o formato do `sudoedit` da aula 12, aplicado a um arquivo que você
não tem permissão de escrever diretamente.

```
ana@vm:~/work/cron$ EDITOR=/bin/true crontab -e
No modification made
```

Esse é o mecanismo inteiro numa linha: o `/bin/true` é um editor que sai
imediatamente e não muda nada, então o `crontab` compara a cópia com o original e
não instala nada. O que quer dizer:

**Se você cometer um erro de sintaxe, o `crontab -e` pega antes de instalar**, e
se oferece para te devolver ao editor. Um crontab escrito direto no diretório de
spool não recebe essa conferência.

E o editor é o da aula 12 seção 13 — `$VISUAL`, depois `$EDITOR`, depois o
recurso alternativo da distribuição. `EDITOR=nano crontab -e` é a grafia que vale
saber numa máquina que não é sua.

## O `-r` fica ao lado do `-e`

```sh
crontab -r          # deletes your entire crontab, immediately, with no prompt
```

**Não há confirmação e não há como desfazer.** O `-r` e o `-e` estão a uma tecla
de distância, e o erro é comum o bastante para algumas distribuições trazerem o
`crontab -i`, que pergunta antes — e muitas não trazem.

O hábito que não custa nada, e o que ele compra:

```
ana@vm:~/work/cron$ crontab -l > ~/crontab.backup; wc -l ~/crontab.backup
4 /home/ana/crontab.backup
ana@vm:~/work/cron$ crontab -r
ana@vm:~/work/cron$ crontab -l; echo "exit $?"
no crontab for ana
exit 1
ana@vm:~/work/cron$ crontab ~/crontab.backup && crontab -l | tail -2
* * * * * echo "CRON_TZ=[$CRON_TZ]  ran at $(date -u +\%H:\%M) UTC" >> /home/ana/work/cron/tzenv2.log
30 8 * * * echo "08:30 New York?" >> /home/ana/work/cron/tz830.log
```

**O `crontab -r` não imprimiu absolutamente nada** — sem prompt, sem resumo, sem
"tem certeza". A linha seguinte é como você descobre, e a linha depois dela são
os trinta segundos que o backup custou.

Melhor que o hábito: **mantenha o crontab num arquivo em controle de versão** e
instale com `crontab jobs.cron`. Aí o `-r` te custa trinta segundos em vez de uma
agenda de que ninguém lembra.

E repare no `exit 1` daquele transcript: **o `crontab -l` falha quando não há
crontab**, em vez de não imprimir nada e dar certo, o que é uma coisa que um
script pode conferir.

## Onde ele fica de verdade

```
/var/spool/cron/crontabs/ana        # Debian and Ubuntu
/var/spool/cron/ana                 # Red Hat and SUSE
```

O diretório é modo `1730` e pertence a `root:crontab`, então você não consegue
ler o de mais ninguém e não consegue escrever o seu à mão — que é por que o
`crontab -e` existe em vez de ser uma conveniência.

**Não edite o arquivo do spool diretamente nem como root.** O cron percebe um
crontab alterado pela data de modificação do diretório, e um editor que escreve
no lugar pode deixar o arquivo mudado e o diretório intocado.

## Duas coisas que não são óbvias

**O crontab não tem `SHELL` e não tem caminho a não ser que você diga.** A seção
06 é o assunto inteiro e é o jeito mais comum de um job que funciona no seu
terminal não fazer nada às três da manhã.

**Um arquivo de crontab precisa de uma quebra de linha final**, e um arquivo
gerado muitas vezes não tem:

```
ana@vm:~/work/cron$ od -c nonl.cron | tail -2
0000040   c   h   o       g   o   o   d   b   y   e
0000053
ana@vm:~/work/cron$ crontab nonl.cron; echo "exit $?"
new crontab file is missing newline before EOF, can't install.
exit 1
```

**Ele recusa, em voz alta, e não instala nada** — o crontab antigo continua lá,
intocado. Esse é o caso bom e vale saber qual caso é: um script de deploy que
canaliza um here-document para o `crontab -` e ignora o status de saída vai
informar sucesso e não mudar coisa nenhuma.
