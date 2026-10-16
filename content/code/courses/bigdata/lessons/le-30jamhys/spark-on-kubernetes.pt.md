---
title: Spark no Kubernetes
version: 1
---

**Esta seção não foi rodada para este curso.** A máquina em que ele foi gravado roda dentro de um
sandbox cujo kernel se recusa a iniciar contêineres dentro de contêineres: o Minikube, abaixo, criou o
seu nó, e todo pod que o nó tentou iniciar falhou com `failed to update /proc/self/oom_score_adj:
Permission denied`. Numa máquina virtual sua, como a aula 1 recomenda, nada atrapalha, e os comandos
abaixo são os de sempre da documentação do Spark, do Minikube e do Kubernetes. O que eles imprimem é
descrito, não citado.

O **Minikube** roda um cluster Kubernetes de um nó dentro de um contêiner Docker. Docker, Minikube e
`kubectl`, o cliente de linha de comando do Kubernetes, na VM, com o cluster standalone parado antes
para que os dois não disputem os mesmos cores:

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

O `usermod` põe você no grupo que pode usar o Docker, e o `newgrp` torna isso verdade no terminal
atual sem sair da sessão. O `minikube start` baixa o Kubernetes, várias centenas de megabytes, na
primeira vez, e o `kubectl get nodes` deve então listar um nó, `minikube`, como `Ready`.

**Uma imagem com Spark e Python.** A versão do Spark traz os Dockerfiles e um script que os monta.
Apontar o Docker para o daemon do próprio Minikube antes faz a imagem ser montada onde o cluster pode
usá-la, sem nada a publicar:

```sh
eval $(minikube docker-env)
cd ~/spark
./bin/docker-image-tool.sh -r lab -t 4.1.3 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile build
cd ~/big
```

Isso monta duas imagens, `lab/spark:4.1.3` e `lab/spark-py:4.1.3`, a segunda com Python e PySpark por
cima da primeira.

**Permissão para o driver.** O driver cria e apaga pods de executor, então roda como uma *service
account* que tem permissão para isso:

```sh
kubectl create serviceaccount spark
kubectl create rolebinding spark-edit --clusterrole=edit --serviceaccount=default:spark
```

**Os dados.** Um pod não enxerga o `~/big`. Para este laboratório a ponte mais simples é montar o
diretório no nó do Minikube, num terminal próprio que fica aberto, e depois em cada pod como um volume
`hostPath`:

```sh
minikube mount $HOME/big/data:/data
```

**O programa** lê os cliques de `/data` e os conta por tipo. Salve-o dentro do diretório montado,
como `~/big/data/kinds_k8s.py`, para que o pod do driver também consiga lê-lo:

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
      "note": "**`/data` é o `~/big/data` do laboratório**, montado no nó do Minikube e de lá no pod do driver e de cada executor."
    },
    {
      "code": "for row in clicks.groupBy(\"kind\").count().orderBy(\"kind\").collect():\n    print(row.kind, row[\"count\"])\n",
      "note": "**No modo cluster isto vai para o log do pod do driver**, que o `kubectl logs` mostra."
    }
  ]
}
```

**O job**, no modo cluster, com o driver e dois executores, todos pods:

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

`local://` quer dizer um caminho dentro do pod, que o `/data/kinds_k8s.py` é, pela montagem. Enquanto
ele roda, o `kubectl get pods` lista um pod de driver e dois de executor; quando termina, os executores
somem e o pod do driver fica, `Completed`, com a sua saída em `kubectl logs <pod do driver>`.

**Cotas são a promessa da aula 2 para o Kubernetes.** Um namespace para os analistas, com um teto:

```sh
kubectl create namespace analysts
kubectl create quota analysts --namespace analysts --hard=requests.cpu=2,requests.memory=3Gi
```

Um job submetido a esse namespace, com `--conf spark.kubernetes.namespace=analysts`, recebe executores
até o próximo ultrapassar a cota; os demais são recusados pelo API server, e o driver continua pedindo.
É a capacidade máxima de uma fila do YARN, imposta pelo cluster e não pelo Spark.
