---
title: Um Job roda até ter sucesso vezes suficientes
version: 1
---

**Um Deployment trata um pod que sai como um pod a reiniciar. Um Job o trata como trabalho feito**, se
ele saiu com sucesso, e o conta. Essa é a diferença inteira, e ela serve para tudo o que tem fim: um
relatório, uma migração, um lote de imagens para redimensionar.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: report
spec:
  completions: 3
  parallelism: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: report
        image: busybox:1.37
        command: ["sh", "-c", "echo counting orders on $(hostname); sleep 3; echo done"]
```

`completions: 3` é quantos pods bem-sucedidos o Job precisa, e `parallelism: 2` quantos podem rodar ao
mesmo tempo. `restartPolicy: Never` significa que um pod que falha não é reiniciado no lugar; o Job
cria um pod novo, o que mantém separados os logs de cada tentativa.

```
ana@laptop:~/shop$ kubectl apply -f report.yaml
job.batch/report created
ana@laptop:~/shop$ kubectl wait --for=condition=Complete job/report --timeout=120s
job.batch/report condition met
ana@laptop:~/shop$ kubectl get job report
NAME     STATUS     COMPLETIONS   DURATION   AGE
report   Complete   3/3           13s        13s
ana@laptop:~/shop$ kubectl get pods -l job-name=report
NAME           READY   STATUS      RESTARTS   AGE
report-hqlfv   0/1     Completed   0          6s
report-t95ww   0/1     Completed   0          13s
report-wdkrt   0/1     Completed   0          13s
ana@laptop:~/shop$ kubectl logs job/report
Found 3 pods, using pod/report-t95ww
counting orders on report-t95ww
done
```

**Dois pods subiram juntos, treze segundos antes da listagem, e o terceiro seis segundos antes dela**,
depois que um dos dois primeiros terminou: nunca mais de dois ao mesmo tempo, três no total. Cada pod
terminou `Completed`, e o Job está `Complete`, `3/3`, depois de 13 segundos. O
`kubectl logs job/report` lê um deles e diz qual.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas vagas, porque parallelism é 2. Na primeira vaga um pod roda e termina, depois um terceiro pod sobe e termina. Na segunda vaga um pod roda e termina. Um contador embaixo marca 1 de 3, 2 de 3, 3 de 3, e o Job fica Complete depois de 13 segundos.\"><defs><marker id=\"job-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 1</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vaga 2</text><rect x=\"100\" y=\"30\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 1</text><text x=\"220.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><rect x=\"360\" y=\"30\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 3</text><text x=\"480.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><rect x=\"100\" y=\"90\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 2</text><text x=\"230.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><text x=\"100\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parallelism: 2 · completions: 3</text><text x=\"600\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Job Complete, 3/3, em 13 s</text><path d=\"M100 190 L600 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#job-ah-wire)\"></path><text x=\"600\" y=\"206\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Nunca mais de dois pods ao mesmo tempo, três sucessos no total. O terceiro pod espera uma vaga livre.", "same": ["pod 1", "pod 2", "pod 3"]}
```

## Um Job que não consegue ter sucesso

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: broken
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: broken
        image: busybox:1.37
        command: ["sh", "-c", "echo the database is not there; exit 1"]
```

```
ana@laptop:~/shop$ kubectl apply -f broken.yaml
job.batch/broken created
ana@laptop:~/shop$ kubectl get job broken
NAME     STATUS   COMPLETIONS   DURATION   AGE
broken   Failed   0/1           33s        33s
ana@laptop:~/shop$ kubectl get pods -l job-name=broken
NAME           READY   STATUS   RESTARTS   AGE
broken-65lml   0/1     Error    0          33s
broken-kjbzq   0/1     Error    0          3s
broken-r5vf7   0/1     Error    0          23s
ana@laptop:~/shop$ kubectl get job broken -o jsonpath="{.status.conditions[?(@.type==\"Failed\")].reason}"; echo
BackoffLimitExceeded
```

**Três pods, cada um em `Error`, e então o Job desistiu**: uma tentativa mais `backoffLimit: 2` novas
tentativas. As idades mostram como ele esperou, 33, 23 e 3 segundos: a segunda tentativa dez segundos
depois da primeira, a terceira vinte segundos depois dessa, o mesmo atraso que dobra que um container
em falha recebe. O motivo da condição, `BackoffLimitExceeded`, é o que um pipeline ou um alerta deve
olhar. Os três pods que falharam ficam guardados, então os logs deles estão lá para ler; um Job
terminado e os pods dele ficam até alguém apagá-los, ou até um `ttlSecondsAfterFinished` definido no
Job removê-los.
