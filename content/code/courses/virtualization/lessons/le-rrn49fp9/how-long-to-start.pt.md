---
title: Quanto cada um leva para ligar
version: 1
---

Um contêiner que roda um comando e sai, contra a vm1 desligada e ligada até responder ao ssh:

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

**0,401 segundos** para o contêiner, **60,267** para a máquina virtual, cerca
de 150 vezes mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 130\" role=\"img\" aria-label=\"Duas barras para quanto cada um levou. Um contêiner rodou um comando e saiu em 0,401 segundos. A vm1 levou 60,267 segundos entre ser ligada e responder ao ssh, cerca de 150 vezes mais, no processador imitado deste computador.\"><defs><marker id=\"sd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um contêiner, do início ao fim</text><rect x=\"240\" y=\"22\" width=\"3\" height=\"22\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"253\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,401</text><text x=\"294\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a vm1, da partida a responder ao ssh</text><rect x=\"240\" y=\"72\" width=\"320.0\" height=\"22\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"570.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60,267</text><text x=\"618.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos</text></svg>", "caption": "Um contêiner liga um processo; uma máquina virtual liga um computador, firmware, kernel e tudo. A diferença diminui com KVM, e nunca some."}
```

Parte dessa diferença é o processador imitado deste computador, aula 2, e com KVM a máquina virtual seria
bem mais rápida. Mas não 0,401 segundos: uma máquina virtual liga um computador, firmware, kernel,
serviços e tudo, e um contêiner liga um processo. É por isso que contêineres são como serviços são
entregues quando muitas cópias precisam ir e vir de minuto em minuto.
