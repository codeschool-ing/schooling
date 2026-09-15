---
title: O job que ainda está rodando quando o próximo começa
version: 1
---

```sh
*/5 * * * * /home/ana/bin/sync.sh
```

Cinco minutos é de sobra. Aí o outro lado fica lento, uma execução leva sete
minutos, e **o cron inicia a próxima assim mesmo** — porque o cron não faz ideia
de que a primeira ainda está indo.

Aos onze minutos são três. Numa hora são doze, cada uma mais lenta que a
anterior porque estão disputando o mesmo disco, e a máquina agora não está
fazendo mais nada. **Este é o jeito mais comum de um job agendado derrubar um
servidor**, e nunca acontece em teste, porque em teste o job é rápido.

## O `flock`, que é uma palavra

```
ana@vm:~/work/cron$ flock -n job.lock -c 'sleep 8; echo "long job finished"' & sleep 1; echo started
started
ana@vm:~/work/cron$ flock -n job.lock -c 'echo "second job ran"'; echo "exit $?"
exit 1
ana@vm:~/work/cron$ flock -w 20 job.lock -c 'echo "third job waited, then ran"'; echo "exit $?"
long job finished
third job waited, then ran
exit 0
```

Três execuções contra uma trava, e os três comportamentos estão naquelas seis
linhas.

**A primeira segura a trava por oito segundos.** A segunda a pede com `-n` — *não
espere* — e não a recebe: sem saída, `exit 1`, foi embora. A terceira pede com
`-w 20` — *espere até vinte segundos* — e dá para assistir: a saída do job longo
aparece primeiro, e então o terceiro job roda.

| | |
|---|---|
| `flock -n arquivo -c 'cmd'` | roda, ou desiste na hora |
| `flock -w 30 arquivo -c 'cmd'` | roda, ou desiste depois de trinta segundos |
| `flock arquivo -c 'cmd'` | espera o tempo que for |

Num crontab:

```sh
*/5 * * * * /usr/bin/flock -n /tmp/sync.lock /home/ana/bin/sync.sh
```

**O `-n` é o padrão certo para um job que se repete.** Uma execução pulada vai
acontecer de novo em cinco minutos; uma execução enfileirada ainda vai estar na
fila à meia-noite.

## O status de saída é a armadilha

O `flock -n` sai com **1** quando não conseguiu a trava — o que se parece
exatamente com um job que falhou. Numa máquina com monitoramento, uma tarde lenta
vira uma tarde de alertas sobre um job que está funcionando corretamente.

```sh
*/5 * * * * /usr/bin/flock -n /tmp/sync.lock /home/ana/bin/sync.sh || [ $? -eq 1 ]
```

Desajeitado. O `flock -E 0 -n` é a versão limpa: **o `-E` define o status de saída
usado quando a trava está ocupada**, então `-E 0` diz "pular não é uma falha".

```
ana@vm:~/work/cron$ flock -n job.lock -c 'sleep 6' & sleep 1; echo held
held
ana@vm:~/work/cron$ flock -E 0 -n job.lock -c 'echo ran'; echo "exit $?"
exit 0
```

**O `ran` nunca foi impresso e o status é 0.** A trava estava ocupada, o comando
não rodou, e nada é relatado como quebrado.

```sh
*/5 * * * * /usr/bin/flock -E 0 -n /tmp/sync.lock /home/ana/bin/sync.sh
```

Aí um status diferente de zero quer dizer que o job em si falhou, que é o que você
queria que o status quisesse dizer.

## Por que não um arquivo de PID

A coisa que todo mundo escreve em vez disso:

```sh
[ -f /tmp/sync.pid ] && exit 0
echo $$ > /tmp/sync.pid
trap 'rm -f /tmp/sync.pid' EXIT
```

**Está errado de dois jeitos e os dois mordem.** A conferência e a escrita são
duas operações, então dois jobs começando no mesmo segundo podem passar os dois
pela conferência. E um job morto com `SIGKILL` (aula 6) nunca roda o trap dele,
então o arquivo sobrevive a ele — e o job nunca mais roda até alguém apagá-lo à
mão.

O `flock` não tem nenhum dos dois problemas: a trava pertence ao descritor de
arquivo, e **o kernel a libera quando o processo morre**, seja como for.

## O systemd ganha isso de graça

```sh
systemctl start report.service     # while report.service is already running
```

Nada acontece. **Um `.service` que está ativo não é iniciado de novo** — a
ativação do timer é uma não-operação, e o journal registra. Não há arquivo de
trava para escrever, para vazar, ou para errar.

Esse é o argumento prático mais forte desta aula a favor de um timer em vez de uma
linha de crontab, e vale mais que a sintaxe do calendário.

## Mais duas coisas de que um job longo precisa

**Um tempo limite**, para que um job travado não esteja lá amanhã:

```sh
*/5 * * * * /usr/bin/flock -E 0 -n /tmp/sync.lock timeout 240 /home/ana/bin/sync.sh
```

O `timeout 240` o mata depois de quatro minutos. Num arquivo de unidade é
`TimeoutStartSec=4min`, e `RuntimeMaxSec=` para a execução inteira.

**E uma razão para ser idempotente.** Travar impede duas cópias ao mesmo tempo;
não impede o mesmo trabalho ser feito duas vezes, por uma retentativa, por uma
execução atrasada, ou por alguém rodando à mão enquanto ele está agendado. A
pergunta a responder antes de agendar qualquer coisa é *o que acontece se isto
rodar duas vezes?* — e a única resposta confortável é "nada".
