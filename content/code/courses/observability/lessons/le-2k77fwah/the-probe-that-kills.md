---
title: The probe that kills
version: 1
---

The most expensive health check is the one that is right about a problem and wrong about whose it
is. **A liveness probe that checks a dependency restarts every copy of a service when the dependency
fails**, and none of the restarts can help.

Three copies of a service whose liveness probe insists on reaching the database:

```schooling-example
{
  "language": "yaml",
  "file": "k8s/deep.yaml",
  "parts": [
    {
      "code": "# A stand-in database, and a service whose LIVENESS probe checks that it can\n# reach it: the mistake this part of the lesson is about.\napiVersion: apps/v1\nkind: Deployment\nmetadata: {name: db}\nspec:\n  replicas: 1\n  selector: {matchLabels: {app: db}}\n  template:\n    metadata: {labels: {app: db}}\n    spec:\n      containers:\n        - name: db\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, -m, http.server, \"5432\"]\n---\napiVersion: v1\nkind: Service\nmetadata: {name: db}\nspec:\n  selector: {app: db}\n  ports: [{port: 5432}]\n---\n",
      "note": "A stand-in for a database: a server listening on 5432, behind a Service called `db`."
    },
    {
      "code": "apiVersion: apps/v1\nkind: Deployment\nmetadata: {name: deep}\nspec:\n  replicas: 3\n  selector: {matchLabels: {app: deep}}\n  template:\n    metadata: {labels: {app: deep}}\n    spec:\n      containers:\n        - name: deep\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, -m, http.server, \"8000\"]\n"
    },
    {
      "code": "          livenessProbe:\n            exec:\n              command: [python, -c, \"import socket; socket.create_connection(('db', 5432), 1)\"]\n            periodSeconds: 3\n            failureThreshold: 3\n",
      "note": "**The mistake**: a liveness probe that succeeds only if `db` accepts a connection. It is written with the best intentions, *if I cannot reach my database, something is wrong with me*, and it is false."
    }
  ]
}
```

```
ana@obs:~/shop$ kubectl apply -f k8s/deep.yaml
deployment.apps/db created
service/db created
deployment.apps/deep created
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS   AGE
deep-556bf5bcdd-jw2kh   1/1     Running   0          1s
deep-556bf5bcdd-s5flf   1/1     Running   0          1s
deep-556bf5bcdd-vnsfv   1/1     Running   0          1s
```

All three ready and never restarted. Then the database goes away, scaled to nothing, and two and a
half minutes pass:

```
ana@obs:~/shop$ kubectl scale deployment db --replicas=0
deployment.apps/db scaled
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS     AGE
deep-556bf5bcdd-jw2kh   1/1     Running   3 (4s ago)   2m32s
deep-556bf5bcdd-s5flf   1/1     Running   3 (4s ago)   2m32s
deep-556bf5bcdd-vnsfv   1/1     Running   3 (4s ago)   2m32s
```

**Every copy restarted three times, at the same moment.** Each restart is a process killed in the
middle of whatever it was doing, requests included, and each new process failed the same probe
nine seconds later, because the database was still gone. Between restarts Kubernetes waits longer
each time, ten seconds, then twenty, then forty, up to five minutes, which is what `CrashLoopBackOff`
means when it appears.

The database comes back:

```
ana@obs:~/shop$ kubectl scale deployment db --replicas=1
deployment.apps/db scaled
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS      AGE
deep-556bf5bcdd-jw2kh   1/1     Running   3 (64s ago)   3m32s
deep-556bf5bcdd-s5flf   1/1     Running   3 (64s ago)   3m32s
deep-556bf5bcdd-vnsfv   1/1     Running   3 (64s ago)   3m32s
```

The restarts stop, and the count stays at three, the record of an outage this service did not have.
With real traffic the damage is worse than the count: requests were dropped at every restart, caches
were emptied, and when the database returned every copy was either starting or waiting out a
back-off, so the recovery took longer than the outage needed to.

The fix is a sentence: **liveness checks the process, readiness checks the dependencies.** Had this
check been a readiness probe, the three copies would have left the Service while the database was
gone and come back by themselves a few seconds after it returned, with nothing restarted and nothing
lost.
