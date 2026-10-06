---
title: Do comando docker ao processo
version: 1
---

**O `docker` é um cliente. Ele não faz trabalho nenhum sozinho: manda um pedido a um daemon, e o
daemon passa a tarefa por uma cadeia de mais três programas antes de um container existir.**
Conhecer a cadeia é o que torna legíveis os erros das próximas etapas, porque cada elo falha com a
própria mensagem.

A Ana inicia um container e lista os processos ao longo da cadeia:

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

Leia pela coluna `PPID`, que nomeia o pai de cada processo:

- **`dockerd`**, o daemon do Docker, é o servidor que fica rodando. Ele guarda as imagens, as redes,
  os volumes e o registro de cada container, e responde ao comando `docker`.
- **`containerd`**, iniciado aqui pelo `dockerd`, cuida do ciclo de vida dos containers: desempacota
  imagens em snapshots, que a aula 4 abriu, e inicia e para containers quando mandam.
- **`containerd-shim-runc-v2`**, um por container, fica ao lado do container a vida toda. Ele mantém
  abertas a entrada e a saída do container e recolhe o código de saída dele, para que o `dockerd` e o
  `containerd` possam ser reiniciados, ou atualizados, sem matar os containers que iniciaram.
- **`sleep 600`** é o processo do próprio container, filho do shim.

**Falta um programa na lista: o runc.** O shim o chamou para criar o container, o runc montou os
namespaces e os cgroups a partir do bundle e iniciou o `sleep`, e então terminou. O trabalho dele é o
momento da criação, exatamente como a aula 3 mostrou à mão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma cadeia da esquerda para a direita. O comando docker manda pedidos HTTP pelo socket /var/run/docker.sock ao dockerd. O dockerd pede ao containerd. O containerd inicia um containerd-shim-runc-v2 por container. O shim chama o runc, que cria o container e termina, desenhado tracejado. O processo do container, sleep 600, fica como filho do shim.\"><defs><marker id=\"l6chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">docker</text><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cliente</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><text x=\"210\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o daemon</text><rect x=\"290\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">containerd</text><text x=\"350\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ciclo de vida, snapshots</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shim</text><text x=\"490\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um por container</text><path d=\"M132 68 L148 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><path d=\"M272 68 L288 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><path d=\"M412 68 L428 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"140\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP pelo</text><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker.sock</text><rect x=\"580\" y=\"40\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"645\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">runc</text><text x=\"645\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cria, e termina</text><path d=\"M552 68 L576 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6chain-ah-wire)\"></path><rect x=\"430\" y=\"170\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">sleep 600</text><text x=\"510\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o processo do container</text><path d=\"M490 98 L490 166\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"484\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pai de</text><path d=\"M645 98 L645 140 L594 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6chain-ah-wire)\"></path><text x=\"652\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">iniciou</text></svg>", "caption": "Quatro programas continuam rodando, um por máquina ou um por container. O runc faz o trabalho dele no momento da criação e já sumiu quando alguém lista os processos."}
```

## O cliente fala HTTP

O comando `docker` chega ao `dockerd` por um socket Unix, um arquivo que dois programas da mesma
máquina usam para conversar:

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

O que passa por ele é uma API HTTP comum. O `curl` consegue falar com ela sem comando `docker`
nenhum: `GET /containers/json` é o pedido por trás do `docker ps`, e o JSON que voltou é o container
que a Ana acabou de iniciar. **Toda ferramenta do Docker, do comando `docker` ao Compose e ao plugin
de um editor, é cliente desta única API.** É também por isso que as permissões do socket, `root` e o
grupo `docker` com `rw`, são a linha mais importante desta aula; a próxima etapa explica por quê.
