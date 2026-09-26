---
title: How long each takes to start
version: 1
---

A container that runs one command and exits, against vm1 switched off and started until it answers ssh:

```
ana@host:~$ time sudo podman run --rm docker.io/library/ubuntu:24.04 true

real    0m0.401s
user    0m0.098s
sys     0m0.064s
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ time (virsh start vm1 >/dev/null && until ssh -o ConnectTimeout=2 vm1 true 2>/dev/null; do sleep 1; done)

real    1m0.267s
user    0m0.189s
sys     0m0.097s
```

**0.401 seconds** for the container, **60.267** for the virtual machine, about 150 times as long.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 130\" role=\"img\" aria-label=\"Two bars for how long each took. A container ran a command and exited in 0.401 seconds. vm1 took 60.267 seconds from being started to answering ssh, about 150 times as long, on this computer&#x27;s imitated processor.\"><defs><marker id=\"sd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a container, start to finish</text><rect x=\"240\" y=\"22\" width=\"3\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"253\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.401</text><text x=\"294\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vm1, from start to answering ssh</text><rect x=\"240\" y=\"72\" width=\"320.0\" height=\"22\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"570.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60.267</text><text x=\"618.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds</text></svg>", "caption": "A container starts a process; a virtual machine starts a computer, firmware, kernel and all. The gap narrows with KVM, and never closes."}
```

Part of that gap is this computer's imitated processor, lesson 2, and with KVM the virtual machine would
be much quicker. But not 0.401 seconds: a virtual machine starts a computer, firmware, kernel, services
and all, and a container starts a process. That is why containers are what services are shipped in
when many copies have to come and go by the minute.
