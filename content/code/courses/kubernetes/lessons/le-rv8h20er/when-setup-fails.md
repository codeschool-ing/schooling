---
title: When the setup fails
version: 1
---

**A setup that fails almost never fails because of Kubernetes.** It fails one layer down: an image the
nodes cannot see, a Docker that refuses you, a download that came back wrong. Each failure below
happened while this course was being recorded, and each has a fix of a line or two. Lesson 5 adds four
more, all from `kind` itself, produced on purpose.

## An image the nodes do not have

The most common one in this course, because the shop is built on your machine and not pulled from
anywhere. Here a new tag, `shop:dev`, is made after the cluster, and the cluster is asked to run it:

```
ana@laptop:~/shop$ docker tag shop:1.0 shop:dev
ana@laptop:~/shop$ kubectl create deployment dev --image=shop:dev
deployment.apps/dev created
ana@laptop:~/shop$ kubectl get pods -l app=dev
NAME                   READY   STATUS             RESTARTS   AGE
dev-56757b7b5d-t85x7   0/1     ImagePullBackOff   0          25s
ana@laptop:~/shop$ kubectl describe pods -l app=dev | grep -m 1 "Failed to pull"
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{shop}: Failed to pull image "shop:dev": failed to pull and unpack image "docker.io/library/shop:dev": failed to resolve reference "docker.io/library/shop:dev": failed to do request: Head "https://registry-1.docker.io/v2/library/shop/manifests/dev": tls: failed to verify certificate: x509: certificate signed by unknown authority
ana@laptop:~/shop$ kind load docker-image shop:dev --name shop
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker", loading...
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-control-plane", loading...
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker2", loading...
ana@laptop:~/shop$ kubectl delete pods -l app=dev
pod "dev-56757b7b5d-t85x7" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods -l app=dev
NAME                   READY   STATUS    RESTARTS   AGE
dev-56757b7b5d-vhjmr   1/1     Running   0          1s
```

`ImagePullBackOff` is the kubelet saying it tried to pull and is now waiting longer between tries. The
`describe` line says why: the image is not on the node, so the node asked Docker Hub for
`docker.io/library/shop:dev`. **The end of that line depends on the machine.** The recording machine's
nodes cannot reach Docker Hub at all, so it ends in a certificate error; on yours the nodes reach it and
are told there is no such image. Both mean the same thing: nobody copied the image
into the cluster. `kind load docker-image` does that, and deleting the pod makes the Deployment start a
new one at once instead of waiting out the back-off.

The same thing happens after you rebuild an image with `./build.sh`: the cluster keeps the copy it was
given. Run `./up.sh` again, or `kind load docker-image` for the tag you changed.

## Docker refuses you

`docker` talks to a daemon that runs as root, through a socket only root and the `docker` group may
use. Bruno, a user on the same machine who is not in the group:

```
ana@laptop:~/shop$ sudo -u bruno docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@laptop:~/shop$ sudo -u bruno kind get clusters
ERROR: failed to list clusters: command "docker ps -a --filter label=io.x-k8s.kind.cluster --format '{{.Label "io.x-k8s.kind.cluster"}}'" failed with error: exit status 1

Command Output: permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

`kind` runs `docker` underneath, so it fails with the same sentence at the end of its own. The fix is
the `usermod -aG docker $USER` from the section on Docker, **and then logging out and in again**,
because a shell keeps the groups it started with; `id` lists yours, and `docker` must be among them.

## A download that is refused or wrong

While this course was being recorded, Docker Hub once answered a pull with `429 Too Many Requests`: it
limits how many images one address may pull without an account. Waiting fixes it, and so does
`docker login` with a free Docker account, which raises the limit. A checksum that prints
`FAILED` instead of `OK` means the file is not the one the project published; delete it and download it
again rather than installing it.

## When nothing else works

`kind delete cluster --name shop` and `./up.sh` give you a new cluster in under a minute, and that is
the first thing to try for anything strange in a lesson: every lesson starts from it anyway. If Docker
itself is in a state nobody can explain, delete the VM with `multipass delete --purge k8s` and run the
commands of this lesson again. It feels like giving up, and it is what people who run clusters do with
a machine whose state nobody can explain any more. It is also why this course builds everything from
files you can see.
