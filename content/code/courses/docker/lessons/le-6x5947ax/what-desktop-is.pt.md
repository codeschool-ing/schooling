---
title: O que é o Docker Desktop
version: 1
---

**O Docker Desktop é uma máquina virtual Linux com o Docker dentro, mais as ferramentas para
comandá-la a partir do seu próprio sistema operacional.** A aula 2 resolveu por que a VM precisa
estar lá: um container Linux precisa de um kernel Linux, e o Windows e o macOS não têm um. O trabalho
do Desktop é iniciar esse kernel sem alarde, mantê-lo rodando e fazer parecer que o `docker` é
nativo.

A leitura errada comum é achar que o Desktop *é* o Docker e que os containers rodam "no Windows" ou
"no Mac". Eles rodam na VM. O comando `docker` que você digita fica no seu sistema e manda cada pedido
para dentro da VM, onde o motor faz o trabalho. Tudo o que este curso ensina sobre o motor é sobre o
que está lá dentro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um notebook rodando Windows ou macOS. Nele, o comando docker e a janela do Docker Desktop. Dentro do notebook, uma máquina virtual Linux gerenciada pelo Desktop, com um kernel Linux, o Docker Engine e os containers. O comando docker manda os pedidos através da fronteira para o motor na VM.\"><defs><marker id=\"l5desktop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5desktop-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o seu notebook: Windows ou macOS</text><rect x=\"30\" y=\"60\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">docker</text><text x=\"130\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o comando que você digita</text><rect x=\"30\" y=\"140\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">janela do Docker Desktop</text><text x=\"130\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ajustes, listas, ligar/desligar</text><rect x=\"290\" y=\"50\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"306\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">VM Linux, gerenciada pelo Desktop</text><rect x=\"310\" y=\"86\" width=\"360\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Docker Engine: dockerd, containerd, runc</text><rect x=\"310\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"366\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"434\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"558\" y=\"140\" width=\"112\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"614\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">container</text><rect x=\"310\" y=\"206\" width=\"360\" height=\"38\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">kernel Linux</text><path d=\"M232 86 L306 106\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l5desktop-ah-amber)\"></path><path d=\"M232 166 L306 116\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5desktop-ah-wire)\"></path><text x=\"260\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos</text></svg>", "caption": "O comando roda no seu sistema; os containers rodam na VM. Todo pedido atravessa essa fronteira, e todo arquivo compartilhado entre os dois também.", "same": ["Docker Engine: dockerd, containerd, runc", "container"]}
```

## O que vem na caixa

- **Uma VM Linux pequena**, gerenciada pelo Desktop: você nunca entra nela, e o Desktop a atualiza.
- **O Docker Engine** dentro da VM: `dockerd`, containerd e runc, as mesmas peças que a aula 6 desmonta
  num servidor Linux.
- **As ferramentas de linha de comando no seu sistema**: o `docker`, com `docker compose` e `docker
  buildx` como plugins.
- **Uma janela gráfica** que lista containers, imagens e volumes, com uma tela de ajustes. Tudo o que
  ela faz também pode ser feito pela linha de comando, que é como este curso faz.
- **Extras opcionais**: um cluster Kubernetes de um nó que você pode ligar, extensões e um login nos
  serviços do próprio Docker.

## Qual VM, em qual sistema

| o seu sistema | onde roda o kernel Linux |
| --- | --- |
| Windows 10 ou 11 | **WSL 2**, a camada Linux que a Microsoft distribui com o Windows (recomendado), ou uma VM Hyper-V |
| macOS, Apple silicon ou Intel | uma VM iniciada pelo framework de virtualização da Apple |
| Linux | também uma VM, usando KVM: o Desktop no Linux não usa o kernel do host diretamente |

A última linha surpreende. **O Docker Desktop para Linux também roda uma VM**, então os containers
dele ficam separados de qualquer Docker Engine instalado na mesma máquina, com imagens e containers
separados. Numa máquina Linux, a maioria das pessoas instala só o Docker Engine, que é a aula 6.

## A questão do processador num Mac

**Num Mac com Apple silicon a VM é `arm64`**, então as imagens rodam nativamente quando são
publicadas para `arm64`, o que vale para toda imagem oficial. Uma imagem publicada só para `amd64`
ainda inicia, por emulação, com o Rosetta da Apple ou com o QEMU, conforme um ajuste, e roda
visivelmente mais devagar. A aula 2 mostrou o erro que a mesma imagem dá numa máquina Linux sem
emulação configurada; no Mac ela roda, e o sintoma passa a ser a lentidão. Quando uma equipe mistura
Macs e servidores Linux, o build multiplataforma da aula 13 é como uma tag atende os dois.

## A licença

O Docker Desktop é gratuito para uso pessoal, educação, projetos de código aberto não comerciais e
pequenas empresas. **Pelos termos do Docker na época em que esta aula foi escrita, uma empresa com 250
funcionários ou mais, ou com mais de 10 milhões de dólares de receita anual, precisa de uma assinatura
paga para usá-lo.** Esses termos já mudaram antes, então confira os atuais no site do Docker antes de
uma equipe padronizar nele. O Docker Engine no Linux, a aula 6, é código aberto e não tem essa
condição, e também não têm as alternativas que a aula 28 examina, várias das quais também rodam uma
VM Linux num Mac ou numa máquina Windows, do mesmo jeito que o Desktop.
