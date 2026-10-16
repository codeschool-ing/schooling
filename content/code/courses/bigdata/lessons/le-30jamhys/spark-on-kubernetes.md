---
title: Spark on Kubernetes
version: 1
---

**This section was not run for this course.** The machine it was recorded on runs inside a sandbox
whose kernel refuses to start containers inside containers: Minikube, below, created its node, and
every pod the node tried to start failed with `failed to update /proc/self/oom_score_adj: Permission
denied`. On a virtual machine of your own, as lesson 1 recommends, nothing stands in the way, and the
commands below are the standard ones from the Spark, Minikube and Kubernetes documentation. What they
print is described, not quoted.

**Minikube** runs a one-node Kubernetes cluster inside a Docker container. Docker, Minikube and
`kubectl`, Kubernetes' command-line client, in the VM, with the standalone cluster stopped first so the
two do not compete for the same cores:

```sh
stop-worker.sh
stop-master.sh
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
curl -LO https://storage.googleapis.com/minikube/releases/v1.39.0/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
curl -LO https://dl.k8s.io/release/v1.37.1/bin/linux/amd64/kubectl
sudo install kubectl /usr/local/bin/kubectl
minikube start --cpus 4 --memory 6g
kubectl get nodes
```

`usermod` puts you in the group allowed to use Docker, and `newgrp` makes that true in the current
terminal without logging out. `minikube start` downloads Kubernetes, several hundred megabytes, the first time, and
`kubectl get nodes` should then list one node, `minikube`, as `Ready`.

**An image with Spark and Python.** The Spark release ships the Dockerfiles and a script that builds
them. Pointing Docker at Minikube's own daemon first means the image is built where the cluster can
use it, with nothing to push:

```sh
eval $(minikube docker-env)
cd ~/spark
./bin/docker-image-tool.sh -r lab -t 4.1.3 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile build
cd ~/big
```

That builds two images, `lab/spark:4.1.3` and `lab/spark-py:4.1.3`, the second with Python and
PySpark on top of the first.

**Permission for the driver.** The driver creates and deletes executor pods, so it runs as a
*service account* allowed to:

```sh
kubectl create serviceaccount spark
kubectl create rolebinding spark-edit --clusterrole=edit --serviceaccount=default:spark
```

**The data.** A pod cannot see `~/big`. For this lab the simplest bridge is to mount the directory
into the Minikube node, in a terminal of its own that stays open, and then into each pod as a
`hostPath` volume:

```sh
minikube mount $HOME/big/data:/data
```

**The program** reads the clicks from `/data` and counts them by kind. Save it inside the mounted
directory, as `~/big/data/kinds_k8s.py`, so that the driver's pod can read it too:

```schooling-example
{
  "language": "python",
  "file": "kinds_k8s.py",
  "parts": [
    {
      "code": "\"\"\"Lesson 4's count of events by kind, as a Spark job running in Kubernetes pods.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"kinds on kubernetes\").getOrCreate()\n"
    },
    {
      "code": "clicks = spark.read.parquet(\"/data/silver/clicks\")\n",
      "note": "**`/data` is the lab's `~/big/data`**, mounted into the Minikube node and from there into the driver's and every executor's pod."
    },
    {
      "code": "for row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n",
      "note": "**In cluster mode this goes to the driver pod's log**, which `kubectl logs` shows."
    }
  ]
}
```

**The job**, in cluster mode, its driver and two executors all pods:

```sh
spark-submit --master k8s://$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
  --deploy-mode cluster --name kinds \
  --conf spark.kubernetes.container.image=lab/spark-py:4.1.3 \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
  --conf spark.executor.instances=2 --conf spark.executor.memory=768m \
  --conf spark.kubernetes.driver.volumes.hostPath.data.mount.path=/data \
  --conf spark.kubernetes.driver.volumes.hostPath.data.options.path=/data \
  --conf spark.kubernetes.executor.volumes.hostPath.data.mount.path=/data \
  --conf spark.kubernetes.executor.volumes.hostPath.data.options.path=/data \
  local:///data/kinds_k8s.py
```

`local://` means a path inside the pod, which `/data/kinds_k8s.py` is, through the mount. While it
runs, `kubectl get pods` lists a driver pod
and two executor pods; when it ends, the executors are gone and the driver pod stays, `Completed`, with
its output in `kubectl logs <driver pod>`.

**Quotas are lesson 2's promise for Kubernetes.** A namespace for the analysts with a ceiling:

```sh
kubectl create namespace analysts
kubectl create quota analysts --namespace analysts --hard=requests.cpu=2,requests.memory=3Gi
```

A job submitted to that namespace, `--conf spark.kubernetes.namespace=analysts`, gets executors until
the next one would cross the quota; the rest are refused by the API server, and the driver keeps
asking. It is a YARN queue's maximum capacity, enforced by the cluster rather than by Spark.
