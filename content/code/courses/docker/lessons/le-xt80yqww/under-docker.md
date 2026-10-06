---
title: What is under Docker
version: 1
---

**Lesson 3 named the three specifications every container tool follows: the image format, the
distribution API and the runtime.** This lesson looks at the tools on the other side of them, starting
with the ones Docker itself is built from, which are on Ana's machine already.

## containerd and runc, found running

```
ana@vm:~$ docker run -d --name web shelf:1.0.0
eb4c47bfb55587ddfcf4637f88c9907b1dd60419a50683be72725385966fec5e
ana@vm:~$ ps -o pid,args -C containerd,containerd-shim-runc-v2 | cut -c1-100
  PID COMMAND
  428 /usr/bin/containerd --config /var/run/docker/containerd/containerd.toml
28711 /usr/bin/containerd-shim-runc-v2 -namespace moby -id eb4c47bfb55587ddfcf4637f88c9907b1dd60419a
ana@vm:~$ export CTR="sudo ctr --address /var/run/docker/containerd/containerd.sock"
ana@vm:~$ $CTR namespaces list
time="2026-10-06T18:44:17-03:00" level=warning msg="DEPRECATION: The support for cgroup v1 is deprecated since containerd v2.2 and will be removed by no later than May 2029. Upgrade the host to use cgroup v2."
NAME         LABELS 
moby                
moby_history        
ana@vm:~$ $CTR -n moby containers list | cut -c1-90
time="2026-10-06T18:44:17-03:00" level=warning msg="DEPRECATION: The support for cgroup v1 is deprecated since containerd v2.2 and will be removed by no later than May 2029. Upgrade the host to use cgroup v2."
CONTAINER                                                           IMAGE                 
eb4c47bfb55587ddfcf4637f88c9907b1dd60419a50683be72725385966fec5e    docker.io/library/shel
ana@vm:~$ $CTR -n moby tasks list
time="2026-10-06T18:44:17-03:00" level=warning msg="DEPRECATION: The support for cgroup v1 is deprecated since containerd v2.2 and will be removed by no later than May 2029. Upgrade the host to use cgroup v2."
TASK                                                                PID      STATUS    
eb4c47bfb55587ddfcf4637f88c9907b1dd60419a50683be72725385966fec5e    28736    RUNNING
ana@vm:~$ sudo runc --root /run/docker/runtime-runc/moby list | cut -c1-90
ID                                                                 PID         STATUS     
eb4c47bfb55587ddfcf4637f88c9907b1dd60419a50683be72725385966fec5e   28736       running    
ana@vm:~$ $CTR -n moby images list -q | grep -E "shelf|distroless"
time="2026-10-06T18:44:17-03:00" level=warning msg="DEPRECATION: The support for cgroup v1 is deprecated since containerd v2.2 and will be removed by no later than May 2029. Upgrade the host to use cgroup v2."
docker.io/library/shelf:1.0.0
gcr.io/distroless/static-debian12:nonroot
```

Read it top to bottom:

- **`containerd` runs the containers; `dockerd` asks it to.** In the lab, the daemon started its own
  containerd, with a configuration under `/var/run/docker/`, which is why `ctr` needs `--address`; on a
  packaged install it is a system service on the default socket. The `DEPRECATION` line is containerd
  noting that the lab's kernel uses cgroup v1, lesson 4's older version.
- **A namespace called `moby`** holds Docker's containers and, with the containerd image store, its
  images: `shelf:1.0.0` and the distroless base are both there, under their full names.
- **One shim per container**, `containerd-shim-runc-v2`, keeps the container's process company, so that
  containerd itself can restart without killing it.
- **`runc` created the container and left.** `runc list` still knows it, by the same id and the same
  process number, 28736, that `ctr tasks list` shows. `runc` is the runtime the OCI runtime
  specification describes, and lesson 3 ran it by hand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The layers under docker run, as found on Ana&#x27;s machine. The docker command talks to dockerd. dockerd talks to containerd, process 428, which keeps images and containers in its namespace moby. For each container containerd starts a shim, containerd-shim-runc-v2, process 28711, which calls runc to create the container; runc exits once it is running. The container&#x27;s process, shelf, is 28736, the same number ctr tasks and runc list showed. Kubernetes talks to containerd directly, skipping dockerd.\"><defs><marker id=\"l28stack-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l28stack-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"15\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">docker</text><text x=\"66\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the command</text><path d=\"M117 94 L132 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"132\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><text x=\"183\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the API, builds</text><text x=\"183\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and networks</text><path d=\"M234 94 L249 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"249\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">containerd</text><text x=\"300\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 428</text><text x=\"300\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace moby</text><path d=\"M351 94 L366 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"366\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shim</text><text x=\"417\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 28711</text><text x=\"417\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one per container</text><path d=\"M468 94 L483 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"483\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"534\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">runc</text><text x=\"534\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">creates it,</text><text x=\"534\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then exits</text><path d=\"M585 94 L600 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"600\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"651\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shelf</text><text x=\"651\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 28736</text><rect x=\"249\" y=\"170\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"359\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Kubernetes, through CRI</text><path d=\"M290 170 L290 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l28stack-ah-amber)\"></path><text x=\"130\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Docker's own part</text><text x=\"595\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">shared by Docker and Kubernetes</text><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one docker run, top to bottom</text></svg>", "caption": "Docker is the top of a stack of standard parts. Below dockerd, the same parts run Kubernetes."}
```

**`ctr` is a debugging tool, not a replacement for `docker`**: it has no builds, no Compose and little
convenience. `nerdctl` is a Docker-compatible command for containerd, for people who want containerd
without dockerd. And **Kubernetes talks to containerd directly**, through its Container Runtime
Interface. It stopped going through Docker in 2022, and nothing changed for images: an image Docker
builds runs on a containerd-based cluster as it is, because both sides follow lesson 3's
specifications.
