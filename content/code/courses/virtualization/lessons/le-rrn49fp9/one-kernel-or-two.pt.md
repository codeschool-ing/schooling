---
title: Um kernel ou dois
version: 1
---

A mesma pergunta, feita ao host, a uma máquina virtual, e a um contêiner ligado com o `podman`:

```
ana@host:~$ uname -r
6.18.44-fc-v37
ana@vm1:~$ uname -r
6.8.0-139-generic
ana@host:~$ sudo podman run --rm docker.io/library/ubuntu:24.04 uname -r
6.18.44-fc-v37
```

A máquina virtual roda o próprio kernel, `6.8.0-139-generic`, aula 3. O contêiner roda **o kernel do host**,
`6.18.44-fc-v37`, porque não tem nenhum: um contêiner não é um computador, é um grupo de processos do próprio
host com uma visão restrita do host.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Duas pilhas. Uma máquina virtual: hardware, o kernel do host 6.18.44-fc-v37, o QEMU com hardware imitado, o próprio kernel do convidado 6.8.0-139-generic, e a aplicação em cima. Um contêiner: hardware, o mesmo kernel do host 6.18.44-fc-v37, uma camada fina de namespaces que dá ao contêiner uma visão própria de processos, nomes e arquivos, e a aplicação em cima. O contêiner não tem kernel próprio.\"><defs><marker id=\"ct-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">uma máquina virtual</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">um contêiner</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a aplicação</text><rect x=\"20\" y=\"74\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kernel do convidado 6.8.0-139-generic</text><rect x=\"20\" y=\"118\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU: hardware imitado</text><rect x=\"20\" y=\"162\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kernel do host 6.18.44-fc-v37</text><rect x=\"20\" y=\"206\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hardware</text><rect x=\"380\" y=\"74\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a aplicação</text><rect x=\"380\" y=\"118\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">namespaces: visão própria de processos, nomes, arquivos</text><rect x=\"380\" y=\"162\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kernel do host 6.18.44-fc-v37</text><rect x=\"380\" y=\"206\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hardware</text></svg>", "caption": "Uma máquina virtual traz um computador inteiro, kernel incluído. Um contêiner traz só a aplicação e os arquivos dela, e pega emprestado o kernel do host, e é por isso que liga num instante e por isso que só pode ser o mesmo tipo de sistema que o host.", "same": ["hardware"]}
```

Todo o resto desta aula decorre dessa uma linha:

- **Um contêiner só pode ser o mesmo tipo de sistema que o host.** Contêineres Linux precisam de um kernel
  Linux; uma aplicação Windows num contêiner precisa de um host Windows. O Docker Desktop no Windows e no
  Mac roda uma pequena máquina virtual Linux para ter um kernel Linux para dividir.
- **Tudo divide um kernel**, então um defeito nele, ou uma saída de um contêiner, chega ao host e a todo
  outro contêiner nele. As paredes de uma máquina virtual são as do hypervisor, que é uma coisa bem menor
  de acertar.
- **Um contêiner não pode mudar o kernel**: nada de módulos próprios, nada de kernel de outra versão, nada
  de praticar o que acontece quando um sistema dá boot.
