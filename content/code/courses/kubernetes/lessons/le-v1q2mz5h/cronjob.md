---
title: A CronJob makes Jobs on a schedule
version: 1
---

The schedule is the five fields of `cron`, and this one fires every minute so that the lab does not
have to wait for night:

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

**`timeZone` is worth setting on every CronJob.** Without it the schedule is read in the time zone of
the controller manager, which on most clusters is UTC; with it, `0 2 * * *` means two in the morning
in São Paulo whatever the cluster's machines think. `concurrencyPolicy: Forbid` skips a run if the
previous one is still going, which a backup wants, and `successfulJobsHistoryLimit: 2` keeps the last
two finished Jobs for inspection and deletes the older ones.

After two minutes and twenty seconds:

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

Two runs, a minute apart, each a Job of its own that completed in three seconds, beside the Jobs from
the previous section. **The number in a CronJob's Job name is the scheduled time**, in minutes since
1970: 29855110 minutes is 17:10 UTC on 6 October 2026, and that is the time the second run printed. The
container printed it in UTC because a busybox image has no time-zone data; the schedule was evaluated
in São Paulo, and 17:10 UTC is 14:10 there.

A CronJob is the cluster's version of a crontab, with two differences that matter in practice. **The
run is a pod, scheduled like any other**, so it may land on any node and must not assume a local disk
from the last run. And a run that was due while the controller was down is started when it comes back, unless
`startingDeadlineSeconds` says it is too late by then.
