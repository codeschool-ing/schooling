---
title: Três especificações
version: 1
---

**"Docker" é o nome de uma empresa, de um conjunto de ferramentas e, de um jeito frouxo, da ideia
inteira de containers, e a ideia já não pertence a nenhum deles.** O que faz uma imagem construída
no notebook da Ana rodar sem mudança num cluster Kubernetes que nunca teve Docker instalado é um
conjunto de três especificações públicas, mantidas pela **Open Container Initiative** (OCI).

## Como se chegou aqui

O Docker foi lançado em 2013 e tornou os containers fáceis o bastante para todo mundo usar. O
formato de imagem e o programa que iniciava containers eram do próprio Docker, então em 2015 o
Docker e outros fundaram a OCI sob a Linux Foundation, e o Docker entregou a ela o código que inicia
containers, que virou o **runc**. A versão 1.0 das especificações de imagem e de runtime saiu em
2017, e a de distribuição veio em 2021.

## O que cada uma define

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma imagem viaja da esquerda para a direita. Uma ferramenta de build, como docker build, BuildKit ou Podman, grava a imagem no formato da especificação de imagem. Um registry, como Docker Hub, GHCR ou ECR, guarda e entrega a imagem como diz a especificação de distribuição. Num host, um runtime como runc ou crun a inicia a partir de um bundle, como diz a especificação de runtime.\"><defs><marker id=\"l3specs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">build</text><text x=\"110\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker build · BuildKit · Podman</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">guardar e entregar</text><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Docker Hub · GHCR · ECR</text><rect x=\"510\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">rodar</text><text x=\"610\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">runc · crun</text><path d=\"M212 77 L256 77\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l3specs-ah-amber)\"></path><path d=\"M462 77 L506 77\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l3specs-ah-amber)\"></path><text x=\"234\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">push</text><text x=\"484\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pull</text><rect x=\"15\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"110\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">spec de imagem</text><text x=\"110\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manifesto, config, camadas</text><path d=\"M110 146 L110 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"265\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">spec de distribuição</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a API HTTP de um registry</text><path d=\"M360 146 L360 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"515\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">spec de runtime</text><text x=\"610\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um rootfs mais o config.json</text><path d=\"M610 146 L610 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "Cada seta é um formato que alguém combinou, então cada caixa pode ser trocada por outra ferramenta que fale o mesmo formato.", "same": ["build"]}
```

- **A especificação de imagem** diz o que uma imagem é em disco e na rede: um manifesto que lista as
  peças, uma configuração com o comando e o ambiente padrão, e camadas que são arquivos tar
  comprimidos comuns. Qualquer ferramenta que grave esse formato produz uma imagem que todas as
  outras conseguem rodar. A próxima etapa abre uma.
- **A especificação de runtime** diz como iniciar um container a partir de um diretório: um sistema
  de arquivos raiz mais um arquivo chamado `config.json` que descreve o processo, os namespaces e os
  limites dele. O runc é a implementação de referência, e a última etapa desta aula o usa à mão.
- **A especificação de distribuição** diz como um registry guarda imagens e as entrega por HTTP:
  qual URL devolve um manifesto, qual devolve uma camada. O Docker Hub, o registry do GitHub e o de
  cada provedor de nuvem falam essa língua, e é por isso que o `docker push` funciona contra todos
  eles. A aula 15 sobe um registry e conversa com ele.

A própria máquina da Ana mostra que runtime o Docker usa, e que versão da especificação de runtime
esse runtime implementa:

```
ana@vm:~$ docker info --format "{{.DefaultRuntime}}"
runc
ana@vm:~$ runc --version
runc version 1.5.1
commit: v1.5.1-0-g8f2685a4
spec: 1.3.0
go: go1.27.1
libseccomp: 2.5.5
```

`runc`, implementando a versão 1.3.0 da especificação de runtime. Quando a Ana digita `docker run`,
o último passo, depois que a imagem foi encontrada e o sistema de arquivos preparado, é o runc
criando o processo. A aula 6 segue a cadeia inteira, do comando `docker` até ele.

## Por que a especificação importa para você

**Um formato padrão quer dizer que a imagem é o produto, e a ferramenta que a fez é um detalhe.**
Três coisas decorrem disso, e cada uma já aconteceu:

- **As ferramentas podem ser trocadas.** Podman, Buildah, BuildKit e kaniko constroem imagens;
  containerd, CRI-O e Podman as rodam. A aula 28 roda uma das alternativas contra a mesma imagem.
- **Um orquestrador pode largar o Docker sem largar as suas imagens.** O Kubernetes removeu o
  suporte embutido ao Docker Engine na versão 1.24, em 2022, e fala direto com o containerd ou com o
  CRI-O. As imagens feitas com `docker build` continuaram rodando, porque sempre foram imagens OCI.
- **O registry é intercambiável.** Uma imagem enviada ao Docker Hub pode ser copiada para o registry
  de um provedor de nuvem byte a byte, e o digest dela continua o mesmo. A próxima etapa mostra o que
  é um digest.
