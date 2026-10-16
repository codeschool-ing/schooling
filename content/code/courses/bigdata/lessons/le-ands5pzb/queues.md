---
title: Two queues, one cluster
version: 1
---

**A queue's share is a promise about the moment two loads want the cluster at once.** This script
starts the nightly streaming job, then the analysts' Spark job twenty seconds later, and reads the
scheduler's REST answer every ten seconds while they run. Save it as `~/big/queues.sh`:

```schooling-example
{
  "language": "sh",
  "file": "queues.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# The nightly streaming job and the analysts' Spark job, started together,\n# with each queue's use of its share printed every ten seconds.\nhdfs dfs -rm -r -f -skipTrash /out/kinds-q > /dev/null 2>&1\n\n"
    },
    {
      "code": "hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar \\\n  -D mapreduce.job.queuename=nightly -files mapper.py,reducer.py \\\n  -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' \\\n  -input /raw/clicks-2025.csv -output /out/kinds-q > nightly.log 2>&1 &\n\n",
      "note": "**The nightly job**, lesson 4's streaming count, in the background."
    },
    {
      "code": "sleep 20\nHADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop spark-submit --master yarn --deploy-mode cluster \\\n  --queue analysts --driver-memory 512m --executor-memory 512m --num-executors 1 \\\n  --conf spark.driver.memoryOverhead=256m --conf spark.executor.memoryOverhead=256m \\\n  kinds_yarn.py > analysts.log 2>&1 &\n\n",
      "note": "**Twenty seconds later, the analysts' job**, section 05's, also in the background."
    },
    {
      "code": "for i in 1 2 3 4 5 6 7 8 9 10 11 12; do\n  sleep 10\n  curl -s localhost:8088/ws/v1/cluster/scheduler | jq -r '[.scheduler.schedulerInfo.queues.queue[]\n    | \"\\(.queueName): \\(.usedCapacity | floor)% of its share, \\(.numApplications) running\"] | join(\"   \")'\ndone\nwait\n",
      "note": "**The scheduler's view, every ten seconds**: for each queue, the share of its capacity in use and how many applications it is running."
    }
  ]
}
```

```
ana@lab:~/big$ sh queues.sh
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 59% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 59% of its share, 1 running   analysts: 41% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 41% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
```

**The nightly queue filled its share and stopped there**, at 95%: as many 512 MB containers as fit
in its 70%, with ten map tasks waiting for them. **The analysts' job found its 30% free when it
arrived** and took 83% of it, a driver and an executor of 768 MB each. `usedCapacity` is a percentage
of each queue's own share, so 100 would mean a queue using all it is promised. Without the queues, the
streaming job's map tasks would have taken every container as they came, and the analysts' job would
have waited behind them.

**The cap has a cost, and it shows when the analysts are not there**: the nightly queue then leaves
30% of the cluster idle rather than borrow it. Production clusters usually let a queue grow past its
share into idle capacity, `maximum-capacity` above `capacity`, and turn on *preemption*, so that when
the owner of the borrowed share comes back the scheduler kills enough of the borrower's containers to
return it. A killed map task is simply run again later, which is why MapReduce and Spark tolerate
preemption well, and an hour-long task that is killed at minute fifty-nine is why it has limits.

When YARN is no longer needed, stop it and start the standalone cluster again:

```sh
sh yarn.sh stop
start-master.sh
start-worker.sh spark://localhost:7077
```
