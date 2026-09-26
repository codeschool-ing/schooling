---
title: What the host sees
version: 1
---

A web server in a container, and the same question asked of it and of vm1 from the host's side:

```
ana@host:~$ sudo podman run -d --name web -p 8080:80 docker.io/library/nginx:alpine
bc637711447c880b4e4c4b7bd2bcaebb7e5c98ea73faed40b1cb6298b5075321
ana@host:~$ curl -s localhost:8080 | grep "<title>"
<title>Welcome to nginx!</title>
ana@host:~$ ps -o pid,user,rss,comm -C nginx
    PID USER       RSS COMMAND
  44733 root      6240 nginx
  44751 sshd      3368 nginx
  44752 sshd      3040 nginx
  44753 sshd      3040 nginx
  44754 sshd      3024 nginx
ana@host:~$ ps -o pid,user,rss,comm -C qemu-system-x86_64
    PID USER       RSS COMMAND
  44562 libvirt+ 1518104 qemu-system-x86
ana@host:~$ sudo podman images
REPOSITORY                TAG         IMAGE ID      CREATED      SIZE
docker.io/library/nginx   alpine      3dd08163706a  3 days ago   64.3 MB
docker.io/library/ubuntu  24.04       6232b3879100  2 weeks ago  80.7 MB
```

`podman run -d` started nginx in a container and `-p 8080:80` sent the host's port 8080 to it, the port
forwarding of lesson 11. The interesting part is `ps`. The host sees **the container's processes one by
one**, as its own: a master and four workers, one per host processor, using 18712 KiB between them.
Of vm1 it sees **one process** of 1518104 KiB, and nothing of what runs inside.

And look at the `USER` column. nginx's workers run inside the container as user number 101, and on the
host number 101 happens to be called **`sshd`**. The container's users are the host's users, by number;
nothing translated them. That is the thinness of a container's wall seen from the outside, and it is why
containers that run as `root` inside are treated with care: without further settings, that is the host's
`root` in a restricted view.
