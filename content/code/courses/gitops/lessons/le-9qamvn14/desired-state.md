---
title: The desired state, written down
version: 1
---

**A GitOps system starts with a description of what should be running, in files, in Git.** Not a
script that makes it happen: a description of the result. This section writes that description
for `bulletin` in staging, applies it once by hand, and keeps it in a repository.

## One file

Make a directory for the repository with `mkdir -p ~/fleet/staging && cd ~/fleet`, and save this as
`~/fleet/staging/bulletin.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
  namespace: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - name: bulletin
        image: localhost:5001/bulletin:1.0
        env:
        - name: MESSAGE
          value: Staging is open for testing.
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bulletin
  namespace: staging
spec:
  type: NodePort
  selector:
    app: bulletin
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

Three objects, in the order they have to exist: the namespace, two copies of the application, and
a service that the cluster's port 30080 leads to. The `kubernetes` course explains each kind. What
matters here is that **nothing in the file says how to get from the cluster as it is to the
cluster as described**. It does not say "create", or "if it exists, update". It says what should be
true.

## Applied once, by hand

```
ana@laptop:~/fleet$ kubectl apply -f staging/
namespace/staging created
deployment.apps/bulletin created
service/bulletin created
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-59bd8fffb5-296kl   1/1     Running   0          1s
bulletin-59bd8fffb5-x2g4w   1/1     Running   0          1s
ana@laptop:~/fleet$ curl -s localhost:8080
```

`curl localhost:8080` reached one of the two pods through the port mapping of the cluster file,
and the page says what the manifest said: version `1.0` and the staging message.

## Into Git

The file is already the desired state. Putting it in Git makes it **versioned**: every change gets
an author, a date, a message and a way back. A remote repository makes it **shared**, so that
something other than your terminal can read it. Lesson 2 runs a Git server for that; until then, a
bare repository on the same disk plays the part of the remote. If Git has never been set up on
this machine, give it your name and address first, and make `main` the first branch of every new
repository, which is what this course calls it:

```sh
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main
```

Then the repository, its remote and the first commit:

```
ana@laptop:~$ git init --quiet --bare ~/fleet.git
ana@laptop:~/fleet$ git init --quiet
ana@laptop:~/fleet$ git add staging/bulletin.yaml
ana@laptop:~/fleet$ git commit --quiet -m "staging: bulletin 1.0"
ana@laptop:~/fleet$ git remote add origin ~/fleet.git
ana@laptop:~/fleet$ git push --quiet -u origin main
ana@laptop:~/fleet$ git log --oneline
ab88607 staging: bulletin 1.0
```

`git init --bare` makes a repository with no working files, which is what a server keeps. `~/fleet`
pushes to it exactly as it would push to a server, and anything that clones `~/fleet.git` gets
the same history. The hash `ab88607` will be the same on your machine only if your name, address
and the commit's date are the same as Ana's, so expect yours to differ.

There is now one description of staging, and it lives in a place that keeps every version of it.
What is missing is the part that makes the cluster follow it, and the next section writes one.
