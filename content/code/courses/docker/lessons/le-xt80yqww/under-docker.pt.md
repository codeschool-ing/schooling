---
title: O que há debaixo do Docker
version: 1
---

**A aula 3 nomeou as três especificações que toda ferramenta de containers segue: o formato da imagem,
a API de distribuição e o runtime.** Esta aula olha as ferramentas do outro lado delas, começando pelas
de que o próprio Docker é feito, que já estão na máquina da Ana.

## containerd e runc, encontrados rodando

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

Leia de cima para baixo:

- **O `containerd` roda os containers; o `dockerd` pede a ele.** No laboratório, o daemon iniciou o
  próprio containerd, com uma configuração em `/var/run/docker/`, e é por isso que o `ctr` precisa de
  `--address`; numa instalação por pacote ele é um serviço do sistema no socket padrão. A linha
  `DEPRECATION` é o containerd avisando que o kernel do laboratório usa cgroup v1, a versão mais antiga
  da aula 4.
- **Um namespace chamado `moby`** guarda os containers do Docker e, com o armazenamento de imagens do
  containerd, as imagens dele: o `shelf:1.0.0` e a base distroless estão os dois lá, com os nomes
  completos.
- **Um shim por container**, o `containerd-shim-runc-v2`, faz companhia ao processo do container, para
  o próprio containerd poder reiniciar sem matá-lo.
- **O `runc` criou o container e saiu.** O `runc list` ainda o conhece, pelo mesmo id e o mesmo número
  de processo, 28736, que o `ctr tasks list` mostra. O `runc` é o runtime que a especificação de runtime
  da OCI descreve, e a aula 3 o rodou à mão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As camadas debaixo do docker run, como encontradas na máquina da Ana. O comando docker fala com o dockerd. O dockerd fala com o containerd, processo 428, que guarda imagens e containers no namespace moby. Para cada container o containerd inicia um shim, o containerd-shim-runc-v2, processo 28711, que chama o runc para criar o container; o runc sai assim que ele está rodando. O processo do container, o shelf, é o 28736, o mesmo número que o ctr tasks e o runc list mostraram. O Kubernetes fala direto com o containerd, sem passar pelo dockerd.\"><defs><marker id=\"l28stack-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l28stack-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"15\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">docker</text><text x=\"66\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o comando</text><path d=\"M117 94 L132 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"132\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><text x=\"183\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a API, builds</text><text x=\"183\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e redes</text><path d=\"M234 94 L249 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"249\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">containerd</text><text x=\"300\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 428</text><text x=\"300\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace moby</text><path d=\"M351 94 L366 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"366\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shim</text><text x=\"417\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 28711</text><text x=\"417\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um por container</text><path d=\"M468 94 L483 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"483\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"534\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">runc</text><text x=\"534\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cria,</text><text x=\"534\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois sai</text><path d=\"M585 94 L600 94\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28stack-ah-wire)\"></path><rect x=\"600\" y=\"56\" width=\"102\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"651\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">shelf</text><text x=\"651\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pid 28736</text><rect x=\"249\" y=\"170\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"359\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Kubernetes, pelo CRI</text><path d=\"M290 170 L290 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l28stack-ah-amber)\"></path><text x=\"130\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a parte do próprio Docker</text><text x=\"595\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">compartilhado por Docker e Kubernetes</text><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um docker run, de cima para baixo</text></svg>", "caption": "O Docker é o topo de uma pilha de peças padrão. Abaixo do dockerd, as mesmas peças rodam o Kubernetes.", "same": ["pid 428", "namespace moby", "pid 28711", "pid 28736"]}
```

**O `ctr` é uma ferramenta de depuração, e não um substituto do `docker`**: não tem builds, nem Compose,
e pouca conveniência. O `nerdctl` é um comando compatível com o Docker para o containerd, para quem quer
o containerd sem o dockerd. E **o Kubernetes fala direto com o containerd**, pela Container Runtime
Interface. Ele deixou de passar pelo Docker em 2022, e nada mudou para as imagens: uma imagem que o
Docker constrói roda num cluster baseado em containerd como está, porque os dois lados seguem as
especificações da aula 3.
