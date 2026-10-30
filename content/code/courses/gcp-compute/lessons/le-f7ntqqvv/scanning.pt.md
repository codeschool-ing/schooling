---
title: Varredura, e o que uma varredura diz e não diz
version: 1
---

Uma imagem é a base sobre a qual foi construída mais o seu código, e a base é quase tudo: a imagem
`web` da loja é um sistema Debian com Python dentro, carregando centenas de pacotes que ninguém da
equipe escolheu um a um. **A varredura de vulnerabilidades lê a lista de pacotes de uma imagem e a
compara com os alertas publicados**, para que uma falha conhecida num deles vire um achado com nome
em vez de uma surpresa.

## O que o Artifact Registry oferece

A varredura no Google Cloud é do **Artifact Analysis**, que trabalha com o Artifact Registry de dois
jeitos, os dois documentados pelo Google e **nenhum rodado neste laboratório**, que não tem registry
do Google para varrer:

- **varredura automática**: ligada por projeto, varre cada imagem quando ela recebe push, e continua
  reavaliando as imagens que receberam push ou pull recentemente conforme surgem alertas novos;
- **varredura sob demanda**: um comando que varre uma imagem que você indica, inclusive uma na sua
  própria máquina, e devolve os achados sem guardá-los no registry.

A forma sob demanda, como o Google documenta, é um comando contra uma imagem:

```sh
gcloud artifacts docker images scan \
  southamerica-east1-docker.pkg.dev/planner-dev/shop/web:1.4.1 --remote
```

Cada achado diz o pacote, a versão instalada, o alerta, a gravidade e, quando há, a versão que
corrige. As duas formas são cobradas por imagem varrida, a preços que estão na página do próprio
Artifact Analysis.

## Lendo achados sem pânico

Uma imagem base de uma distribuição de uso geral traz achados quase sempre, e a maioria deles está
em pacotes que a aplicação nunca carrega. **As perguntas a fazer a um achado são três**: o pacote é
usado em tempo de execução, existe versão corrigida, e a falha é alcançável pelo jeito como o
serviço está exposto. Uma falha crítica numa biblioteca de compressão que o servidor web usa é
urgente; a mesma gravidade numa ferramenta de páginas de manual que nunca roda é ruído.

A redução mais barata é a que vem antes de qualquer varredura: **uma base menor**.
`python:3.12.13-slim`, a base de toda imagem deste curso, já deixa de fora os compiladores e a
documentação da imagem completa; imagens distroless e baseadas em Alpine vão além, ao preço de
ferramentas que você talvez queira na hora de depurar. Menos pacotes quer dizer menos achados, e os
que sobram têm mais chance de importar.

## Onde a varredura para

**Uma varredura diz o que se sabe de errado com os pacotes, não que a imagem é segura.** Ela não lê
o seu código, não conhece uma falha que ainda não foi publicada e não vê configuração: um segredo
gravado numa camada passa em toda varredura de vulnerabilidades. Isso pede outras verificações, um
detector de segredos no build e uma revisão do que o `Dockerfile` copia, e o pipeline de build é o
lugar delas, antes do push e não depois.

A varredura também se liga ao resto da plataforma. O **Binary Authorization**, um recurso do GKE e
do Cloud Run, pode se recusar a rodar uma imagem sem um atestado, por exemplo um que registra que
ela passou pela varredura; é assim que "nós varremos tudo" vira "nada sem varredura roda". Montar
isso está além deste curso; o `gcp-operations` dedica a ele a lição 4, e volta a este registry, às
tags imutáveis e à varredura dele na lição 2.
