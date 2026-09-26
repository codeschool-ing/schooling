---
title: One kernel or two
version: 1
---

The same question, asked of the host, of a virtual machine, and of a container started with `podman`:

```
ana@host:~$ uname -r
6.18.44-fc-v37
ana@vm1:~$ uname -r
6.8.0-139-generic
ana@host:~$ sudo podman run --rm docker.io/library/ubuntu:24.04 uname -r
6.18.44-fc-v37
```

The virtual machine runs its own kernel, `6.8.0-139-generic`, lesson 3. The container runs **the host's kernel**,
`6.18.44-fc-v37`, because it has none of its own: a container is not a computer, it is a group of the host's
own processes with a restricted view of the host.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two stacks. A virtual machine: hardware, the host&#x27;s kernel 6.18.44-fc-v37, QEMU with imitated hardware, the guest&#x27;s own kernel 6.8.0-139-generic, and the application on top. A container: hardware, the same host kernel 6.18.44-fc-v37, a thin layer of namespaces that gives the container its own view of processes, names and files, and the application on top. The container has no kernel of its own.\"><defs><marker id=\"ct-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">a virtual machine</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a container</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the application</text><rect x=\"20\" y=\"74\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guest kernel 6.8.0-139-generic</text><rect x=\"20\" y=\"118\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU: imitated hardware</text><rect x=\"20\" y=\"162\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host kernel 6.18.44-fc-v37</text><rect x=\"20\" y=\"206\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hardware</text><rect x=\"380\" y=\"74\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the application</text><rect x=\"380\" y=\"118\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">namespaces: its own view of processes, names, files</text><rect x=\"380\" y=\"162\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host kernel 6.18.44-fc-v37</text><rect x=\"380\" y=\"206\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hardware</text></svg>", "caption": "A virtual machine brings a whole computer, kernel included. A container brings only the application and its files, and borrows the host’s kernel, which is why it starts in a moment and why it can only be the same kind of system as the host."}
```

Everything else in this lesson follows from that one line:

- **A container can only be the host's kind of system.** Linux containers need a Linux kernel; a Windows
  application in a container needs a Windows host. Docker Desktop on Windows and on a Mac runs a small
  Linux virtual machine to have a Linux kernel to share.
- **Everything shares one kernel**, so a fault in it, or a way out of a container, reaches the host and
  every other container on it. A virtual machine's walls are the hypervisor's, which is a much smaller
  thing to get right.
- **A container cannot change the kernel**: no modules of its own, no kernel of a different version, no
  practising what happens when a system boots.
