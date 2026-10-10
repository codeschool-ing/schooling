---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over one line of output that
looked like a catastrophe and was a small thing. These are the failures that come up while
following this lesson, each with what it prints and what fixes it. **Every one of them was produced
on purpose**, on the machine the transcripts come from.

## `permission denied` from Docker

Right after installing Docker:

```
ana@laptop:~/setup$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

The Docker daemon listens on a socket that only `root` and the `docker` group may use. The
installation added you to the group, and **group membership is read when you log in**, so the
terminal you installed from does not have it yet. Log out and back in; in the VM, `exit` and
`multipass shell gitops` again. `id` then lists `docker` among your groups. Running everything with
`sudo` instead works and leaves files in your home directory owned by root, which fails later in
more confusing ways.

## A cluster that already exists

Running the creation a second time, or after an earlier attempt that half worked:

```
ana@laptop:~/setup$ kind create cluster --name gitops --config cluster.yaml 2>&1 | grep ERROR
ERROR: failed to create cluster: node(s) already exist for a cluster with the name "gitops"
```

kind refuses rather than overwrite. If the existing cluster works, keep it. If it does not,
`kind delete cluster --name gitops` removes it completely and the creation can run again.

## A port that is taken

The cluster file asks for ports 8080 and 8081 on your machine. If something else already listens
on one of them, here a small web server somebody left running on 8080, the node cannot start:

```
ana@laptop:~/setup$ kind create cluster --name gitops --config cluster.yaml 2>&1 | grep 'already in use'
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint gitops-control-plane (25207e6238bdb17d0edf869e3eefc74d3391545e607f54156d9834c29b5e4a2f): failed to bind host port 127.0.0.1:8080/tcp: address already in use
```

kind prints a page of output for a failed creation, and the `grep` keeps the one line that
matters: `address already in use` names the port. Find what holds it with `ss -ltnp | grep 8080`, and stop
it; or change `hostPort` in `cluster.yaml` to a free port and use that number wherever the course
says 8080. kind cleans up after a failed creation, so there is nothing to delete before trying
again.

## A pod that cannot pull its image

The most common failure of the whole setup is a node that does not know where `localhost:5001`
is, because the loop that writes `hosts.toml` was skipped or ran before the cluster existed. The
deployment is created and its pods never start:

```
ana@laptop:~/setup$ kubectl create deployment probe --image=localhost:5001/bulletin:1.0
deployment.apps/probe created
ana@laptop:~/setup$ kubectl get pods
NAME                     READY   STATUS             RESTARTS   AGE
probe-7c47477fcc-zgsbb   0/1     ImagePullBackOff   0          25s
ana@laptop:~/setup$ kubectl describe pods -l app=probe | tail -n 6
  Normal   Scheduled  25s                default-scheduler  Successfully assigned default/probe-7c47477fcc-zgsbb to gitops-control-plane
  Normal   BackOff    25s                kubelet            spec.containers{bulletin}: Back-off pulling image "localhost:5001/bulletin:1.0"
  Warning  Failed     25s                kubelet            spec.containers{bulletin}: Error: ImagePullBackOff
  Normal   Pulling    10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Pulling image "localhost:5001/bulletin:1.0"
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Failed to pull image "localhost:5001/bulletin:1.0": failed to pull and unpack image "localhost:5001/bulletin:1.0": failed to resolve reference "localhost:5001/bulletin:1.0": failed to do request: Head "https://localhost:5001/v2/bulletin/manifests/1.0": dial tcp 127.0.0.1:5001: connect: connection refused
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Error: ErrImagePull
```

`ImagePullBackOff` is the summary and the event under it is the reason: the node tried
`localhost:5001` **on itself**, found nothing listening, and gave up. Run the loop from
"Teaching the node where the registry is" again; the pods retry on their own and start within a
minute.

The same status with a different reason means a different fix:

```
ana@laptop:~/setup$ kubectl create deployment probe --image=localhost:5001/bulletin:1.1
deployment.apps/probe created
ana@laptop:~/setup$ kubectl get pods
NAME                     READY   STATUS             RESTARTS   AGE
probe-57f8b4b4fd-w2j8f   0/1     ImagePullBackOff   0          20s
ana@laptop:~/setup$ kubectl describe pods -l app=probe | tail -n 6
  Normal   Scheduled  20s               default-scheduler  Successfully assigned default/probe-57f8b4b4fd-w2j8f to gitops-control-plane
  Normal   BackOff    19s               kubelet            spec.containers{bulletin}: Back-off pulling image "localhost:5001/bulletin:1.1"
  Warning  Failed     19s               kubelet            spec.containers{bulletin}: Error: ImagePullBackOff
  Normal   Pulling    7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Pulling image "localhost:5001/bulletin:1.1"
  Warning  Failed     7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Failed to pull image "localhost:5001/bulletin:1.1": rpc error: code = NotFound desc = failed to pull and unpack image "localhost:5001/bulletin:1.1": failed to resolve reference "localhost:5001/bulletin:1.1": localhost:5001/bulletin:1.1: not found
  Warning  Failed     7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Error: ErrImagePull
```

`not found` means the node did reach the registry, and the registry has no such tag. Here the
manifest asks for `1.1`, which was never pushed. Compare the name and tag in the manifest with what
the registry holds: `curl -s localhost:5001/v2/bulletin/tags/list` lists them.

## Nothing answers on 8080

If `curl localhost:8080` says `Connection refused` while the pods are `Running`, the cluster was
created from a file without the `extraPortMappings`, and port 8080 on your machine leads nowhere.
Mappings can only be set when a cluster is created, so the fix is
`kind delete cluster --name gitops` and creating it again from the file in this lesson, followed by
the `hosts.toml` loop.
