---
title: When the setup fails
version: 1
---

**Most setups fail on a step that was skipped or done twice**, and each failure says so in its own
words. These are the ones a first run meets. Each was taken on the recording machine by skipping or
breaking that step on purpose, so the messages are the ones you will see.

## The download is damaged

```
ana@lab:~$ sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
spark-4.1.3-bin-hadoop3.tgz: FAILED
sha512sum: WARNING: 1 computed checksum did NOT match
```

`FAILED` means the file on your disk is not the file the Apache Software Foundation published:
usually a download cut short. Delete the `.tgz` and run the `curl -O` line again. If the second
download fails the same way, the mirror may have moved on to a newer release.
`downloads.apache.org` keeps only the current versions; every past one stays at
`https://archive.apache.org/dist/spark/spark-4.1.3/`, under the same file names.

## The command is not found

```
ana@lab:~/big$ spark-submit generate.py
bash: line 1: spark-submit: command not found
```

The shell does not know where Spark is, because `~/.sparkrc` was not read in this terminal. A
terminal opened before the line was added to `~/.bashrc` is the usual cause. `. ~/.sparkrc` fixes
this one, and every new terminal reads it by itself.

## The cluster is not running

A job submitted while the master is down tries three times, twenty seconds apart, and gives up.
The full output is fifty lines of Java stack trace; these are the lines that matter:

```
ana@lab:~/big$ spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'
WARNING: Using incubator modules: jdk.incubator.vector
04:25:15 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:25:35 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:25:55 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:26:15 WARN StandaloneSchedulerBackend: Application ID is not initialized yet.
04:26:15 ERROR StandaloneSchedulerBackend: Application has been killed. Reason: All masters are unresponsive! Giving up.
04:26:15 WARN StandaloneAppClient$ClientEndpoint: Drop UnregisterApplication(null) because has not yet connected to master
```

`Failed to connect to master` and `All masters are unresponsive` mean nothing is listening on port
7077. `start-master.sh` and `start-worker.sh spark://localhost:7077`, as in section 04.

## The master is up and no worker is

```
ana@lab:~/big$ timeout 40 spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'
WARNING: Using incubator modules: jdk.incubator.vector
04:26:49 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
04:27:04 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
```

This one never gives up. The master accepted the job and has nothing to give it, so the job waits
and says so every fifteen seconds until you stop it with Ctrl-C. Either the workers are not
running, or none of them has the memory the job asks for: a worker of 512 MB cannot host an
executor of 768 MB. `curl -s localhost:8080/json/ | jq '.workers'` shows what the master has.

## The machine is smaller than 8 GB

Two workers instead of three: set `SPARK_WORKER_INSTANCES=2` in `~/spark/conf/spark-env.sh`, then
stop and start the cluster. Everything in the course runs, a little slower, and where a lesson
counts tasks or workers you will count two. If the generator itself runs out of memory, ask it for
fewer events, `spark-submit generate.py 6000000`, and expect every number in the course to be about
a quarter of the one in the transcripts.

## Anything else

- **A port is already in use.** Something else on the machine owns 8080 or 7077. The master then
  picks the next free port for its page and says which in its log, the file `start-master.sh`
  named. Port 7077 has no fallback, so stop whatever holds it.
- **`No space left on device`.** The release and its unpacked copy are 1.2 GB together, the data is
  250 MB, and later lessons write copies of it in other formats. `df -h ~` says how much is left;
  `rm ~/spark-4.1.3-bin-hadoop3.tgz` gives back 573 MB once Spark is unpacked.
- **A worker dies when a job starts.** Its log, in `~/spark/logs`, ends with the reason, and on a
  small machine the reason is usually memory taken by the operating system before Spark could.
