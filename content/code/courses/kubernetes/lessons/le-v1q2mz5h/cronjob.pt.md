---
title: Um CronJob cria Jobs num horário
version: 1
---

O horário são os cinco campos do `cron`, e este dispara a cada minuto para o laboratório não precisar
esperar a noite:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly
spec:
  schedule: "* * * * *"
  timeZone: America/Sao_Paulo
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: nightly
            image: busybox:1.37
            command: ["sh", "-c", "date; echo backing up"]
```

**Vale definir `timeZone` em todo CronJob.** Sem ele o horário é lido no fuso do controller manager,
que na maioria dos clusters é UTC; com ele, `0 2 * * *` significa duas da manhã em São Paulo, pense o
que pensarem as máquinas do cluster. `concurrencyPolicy: Forbid` pula uma execução se a anterior ainda
estiver rodando, que é o que um backup quer, e `successfulJobsHistoryLimit: 2` guarda os dois últimos
Jobs terminados para inspeção e apaga os mais antigos.

Depois de dois minutos e vinte segundos:

```
ana@laptop:~/shop$ kubectl apply -f nightly.yaml
cronjob.batch/nightly created
ana@laptop:~/shop$ kubectl get cronjob nightly
NAME      SCHEDULE    TIMEZONE            SUSPEND   ACTIVE   LAST SCHEDULE   AGE
nightly   * * * * *   America/Sao_Paulo   False     0        32s             2m20s
ana@laptop:~/shop$ kubectl get jobs
NAME               STATUS     COMPLETIONS   DURATION   AGE
broken             Failed     0/1           2m53s      2m53s
nightly-29855109   Complete   1/1           3s         92s
nightly-29855110   Complete   1/1           3s         32s
report             Complete   3/3           13s        3m6s
ana@laptop:~/shop$ kubectl logs job/$(kubectl get jobs -o name | grep nightly | tail -n 1 | cut -d/ -f2)
Tue Oct  6 17:10:00 UTC 2026
backing up
```

Duas execuções, com um minuto entre elas, cada uma um Job próprio que terminou em três segundos, ao
lado dos Jobs da seção anterior. **O número no nome do Job de um CronJob é o horário agendado**, em
minutos desde 1970: 29855110 minutos são 17:10 UTC de 6 de outubro de 2026, e foi esse o horário que a
segunda execução imprimiu. O container o imprimiu em UTC porque uma imagem busybox não tem dados de
fuso; o horário foi avaliado em São Paulo, e 17:10 UTC são 14:10 lá.

Um CronJob é a versão do cluster de um crontab, com duas diferenças que importam na prática. **A
execução é um pod, escalonado como qualquer outro**, então pode cair em qualquer nó e não deve supor um
disco local da última execução. E uma execução que era devida enquanto o controlador estava fora do ar é iniciada quando ele volta,
a menos que `startingDeadlineSeconds` diga que já é tarde demais.
