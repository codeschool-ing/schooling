---
title: From the docker command to the process
version: 1
---

**`docker` is a client. It does none of the work itself: it sends a request to a daemon, and the
daemon hands the job down a chain of three more programs before a container exists.** Knowing the
chain is what makes the errors of the next sections readable, because each link fails with its own
message.

Ana starts a container and lists the processes along the chain:

```
ana@vm:~$ docker run -d --name web alpine:3.22 sleep 600
514195294f2dc96588438596cd19809871e8f9825ccaf69f2331161cd4dc3493
ana@vm:~$ ps -o pid,ppid,args -C dockerd,containerd,containerd-shim-runc-v2,sleep | grep -v defunct
  PID  PPID COMMAND
 1973     1 dockerd
 1982  1973 /usr/bin/containerd --config /var/run/docker/containerd/containerd.toml
24622     1 /usr/bin/containerd-shim-runc-v2 -namespace moby -id 514195294f2dc96588438596cd19809871e8f9825ccaf69f2331161cd4dc3493 -address /var/run/docker/containerd/containerd.sock
24647 24622 sleep 600
```

Read it by the `PPID` column, which names each process's parent:

- **`dockerd`**, the Docker daemon, is the long-running server. It holds the images, the networks,
  the volumes and the record of every container, and it answers the `docker` command.
- **`containerd`**, started by `dockerd` here, manages containers' lifecycles: it unpacks images
  into snapshots, which lesson 4 opened, and starts and stops containers when told to.
- **`containerd-shim-runc-v2`**, one per container, stays beside the container for its whole life.
  It keeps the container's input and output open and collects its exit code, so that `dockerd` and
  `containerd` can be restarted, or upgraded, without killing the containers they started.
- **`sleep 600`** is the container's own process, a child of its shim.

**One program is missing from the list: runc.** The shim called it to create the container, runc
set up the namespaces and cgroups from the bundle and started `sleep`, and then runc exited. Its
job is the moment of creation, exactly as lesson 3 showed by hand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A chain from left to right. The docker command sends HTTP requests over the socket /var/run/docker.sock to dockerd. dockerd asks containerd. containerd starts one containerd-shim-runc-v2 per container. The shim calls runc, which creates the container and exits, drawn dashed. The container&#x27;s process, sleep 600, stays as a child of the shim.\"><defs><marker id=\"l6chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">docker</text><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the client</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><text x=\"210\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the daemon</text><rect x=\"290\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">containerd</text><text x=\"350\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lifecycles, snapshots</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shim</text><text x=\"490\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one per container</text><path d=\"M132 68 L148 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><path d=\"M272 68 L288 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><path d=\"M412 68 L428 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"140\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP over</text><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker.sock</text><rect x=\"580\" y=\"40\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"645\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">runc</text><text x=\"645\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">creates, then exits</text><path d=\"M552 68 L576 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6chain-ah-wire)\"></path><rect x=\"430\" y=\"170\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">sleep 600</text><text x=\"510\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the container's process</text><path d=\"M490 98 L490 166\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"484\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parent of</text><path d=\"M645 98 L645 140 L594 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"652\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">started it</text></svg>", "caption": "Four programs stay running, one per machine or one per container. runc does its work in the moment of creation and is gone by the time anyone lists processes."}
```

## The client talks HTTP

The `docker` command reaches `dockerd` through a Unix socket, a file that two programs on the same
machine use to talk:

```
ana@vm:~$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Oct  6 12:50 /var/run/docker.sock
ana@vm:~$ curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json | jq ".[] | {Names, Image, State}"
{
  "Names": [
    "/web"
  ],
  "Image": "alpine:3.22",
  "State": "running"
}
```

What travels over it is an ordinary HTTP API. `curl` can speak it with no `docker` command
involved: `GET /containers/json` is the request behind `docker ps`, and the JSON that came back is
the container Ana just started. **Every Docker tool, from the `docker` command to Compose to an
editor's plugin, is a client of this one API.** It is also why the socket's permissions, `root`
and the `docker` group with `rw`, are the most important line in this lesson; the next section
explains why.
