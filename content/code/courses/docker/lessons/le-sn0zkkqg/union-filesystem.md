---
title: Layers stacked into one filesystem
version: 1
---

**A container's filesystem is several directories stacked so that they read as one**: the image's
layers at the bottom, read-only, and one empty directory on top that receives every write. Linux
does the stacking with **overlayfs**, a union filesystem built into the kernel. It is why lesson 1's
two containers could share one image without either seeing the other's file, and why starting a
container copies nothing.

## The stack, as the kernel sees it

The container `web` from the first section is still running. Ana makes two changes inside it,
creating a file and deleting one that came with the image, and then asks the host how the
container's root filesystem is mounted:

```
ana@vm:~$ docker exec web sh -c "echo hello > /tmp/new.txt; rm /etc/motd"
ana@vm:~$ findmnt -no OPTIONS /var/lib/docker/rootfs/overlayfs/$(docker inspect -f "{{.Id}}" web) | tr "," "\n"
rw
relatime
lowerdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/211/fs:/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/110/fs
upperdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/212/fs
workdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/212/work
```

Three directories, each with a number, all under the containerd snapshotter that the lab's Docker
uses to store images:

- **`lowerdir`** is a list, read from left to right as top to bottom: snapshot 211, then snapshot
  110. Both are read-only.
- **`upperdir`** is snapshot 212, the container's own layer, where every change lands.
- **`workdir`** is scratch space overlayfs needs for its own bookkeeping.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Four horizontal bands. At the bottom, snapshot 110, Alpine&#x27;s image layer, read-only, which contains etc/motd among its 519 entries. Above it, snapshot 211, the layer Docker writes per container, with etc/hostname, etc/hosts, etc/resolv.conf and .dockerenv, also read-only. Above that, snapshot 212, the container&#x27;s writable upper layer, holding tmp/new.txt and a whiteout for etc/motd. At the top, the merged view the container sees: tmp/new.txt is there and etc/motd is not.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">merged</text><text x=\"36\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what the container sees</text><text x=\"260\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tmp/new.txt</text><text x=\"372\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etc/hostname</text><text x=\"484\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/…</text><text x=\"596\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/motd</text><path d=\"M594 48 L658 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"95\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 212</text><text x=\"36\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">upperdir · writable</text><text x=\"260\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tmp/new.txt</text><text x=\"372\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">etc/motd  (whiteout)</text><rect x=\"20\" y=\"170\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 211</text><text x=\"36\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lowerdir · read-only</text><text x=\"260\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/hostname</text><text x=\"372\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/hosts</text><text x=\"484\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/resolv.conf</text><text x=\"596\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.dockerenv</text><rect x=\"20\" y=\"245\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">snapshot 110 · alpine</text><text x=\"36\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lowerdir · read-only</text><text x=\"260\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bin/…</text><text x=\"372\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">etc/motd</text><text x=\"484\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… 519 entries</text></svg>", "caption": "Overlayfs reads from the top down and stops at the first layer that has the path. The whiteout in the upper layer answers for etc/motd first, so the copy in Alpine's layer is hidden and never touched."}
```

## Where the changes went

The upper layer holds exactly what Ana changed, and nothing else:

```
ana@vm:~$ SNAP=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots
ana@vm:~$ sudo find $SNAP/212/fs -mindepth 1 -printf '%P\n'
etc
etc/motd
tmp
tmp/new.txt
ana@vm:~$ sudo ls -l $SNAP/212/fs/etc
total 0
c--------- 2 root root 0, 0 Oct  6 13:20 motd
```

`tmp/new.txt` is the new file, written whole into the upper layer. **`etc/motd` is the deleted
one**, and it is not a file at all: the `c` at the start of the line marks a character device
numbered `0, 0`. That is overlayfs's **whiteout**. The image's own `/etc/motd` is still in
snapshot 110, untouched, because nothing ever writes to a lower layer; the whiteout on top tells
overlayfs to hide it, so inside the container the file is gone.

Changing an existing file works the same way, at a cost: the first write copies the whole file up
into the upper layer, and the copy is what changes from then on. A container that appends a line
to a 2 GB file the image shipped makes a 2 GB copy first. Lesson 8 is where data that changes
should live instead.

## The layer in the middle

Snapshot 110 is Alpine's layer, the same tar archive that lesson 3 opened. Snapshot 211 sits between
it and the container's own layer, and it is small:

```
ana@vm:~$ sudo find $SNAP/211/fs -type f -printf '%P\n'
etc/hosts
etc/resolv.conf
etc/hostname
dev/console
.dockerenv
```

**Docker writes this layer for each container**: the host name it was given, the DNS settings and
the hosts file it should use, and `.dockerenv`, an empty file whose presence is a common way for a
program to tell it is in a Docker container. It is kept out of the image so that the same image
can start containers with different names and networks.

## The image did not change

A new container from the same image shows the original files:

```
ana@vm:~$ docker run --rm alpine:3.22 ls /tmp /etc/motd
/etc/motd

/tmp:
```

`/etc/motd` is there and `/tmp` is empty. The image is the bottom of the stack for every
container, and **no container ever writes to it**. That is what makes a container's changes
disposable: remove the container, and its upper layer is deleted with it, which is lesson 7's
whole subject.
