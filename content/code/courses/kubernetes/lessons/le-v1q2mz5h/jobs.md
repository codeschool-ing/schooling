---
title: A Job runs until it has succeeded enough times
version: 1
---

**A Deployment treats a pod that exits as a pod to restart. A Job treats it as work done**, if it
exited with success, and counts it. That is the whole difference, and it suits everything that has
an end: a report, a migration, a batch of images to resize.

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

`completions: 3` is how many successful pods the Job needs, and `parallelism: 2` how many may run at
the same time. `restartPolicy: Never` means a failed pod is not restarted in place; the Job makes a
new pod instead, which keeps each attempt's logs apart.

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

**Two pods started together, thirteen seconds before the listing, and the third six seconds before
it**, once one of the first two had finished: never more than two at a time, three in all. Each pod
ended `Completed`, and the Job is `Complete`, `3/3`, after 13 seconds. `kubectl logs job/report`
reads one of them and says which.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two slots, because parallelism is 2. In the first slot one pod runs and completes, then a third pod starts and completes. In the second slot one pod runs and completes. A counter below reads 1 of 3, 2 of 3, 3 of 3, and the Job is Complete after 13 seconds.\"><defs><marker id=\"job-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 1</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 2</text><rect x=\"100\" y=\"30\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 1</text><text x=\"220.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><rect x=\"360\" y=\"30\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 3</text><text x=\"480.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><rect x=\"100\" y=\"90\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pod 2</text><text x=\"230.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Completed</text><text x=\"100\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parallelism: 2 · completions: 3</text><text x=\"600\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Job Complete, 3/3, in 13 s</text><path d=\"M100 190 L600 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#job-ah-wire)\"></path><text x=\"600\" y=\"206\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Never more than two pods at once, three successes in all. The third pod waits for a free slot."}
```

## A Job that cannot succeed

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

**Three pods, each `Error`, and then the Job gave up**: one attempt plus `backoffLimit: 2` retries.
The ages say how it waited, 33, 23 and 3 seconds: the second attempt ten seconds after the first, the
third twenty seconds after that, the same doubling delay a crashing container gets. The condition's
reason, `BackoffLimitExceeded`, is what a pipeline or an alert should look at. The three failed pods
are kept, so their logs are there to read; a finished Job and its pods stay until somebody deletes
them, or until a `ttlSecondsAfterFinished` set on the Job removes them.
