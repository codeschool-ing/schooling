---
title: Varredura de vulnerabilidades, e como ler um achado
version: 1
---

**O Artifact Analysis varre uma imagem quando ela é enviada e relata as vulnerabilidades conhecidas nos
pacotes dentro dela.** Ele lê o banco de pacotes do sistema operacional e os pacotes de linguagem que
reconhece, compara as versões com alertas publicados e anexa uma ocorrência por vulnerabilidade ao
digest da imagem. Ele não executa a imagem, e não acha nada que já não seja um alerta publicado. Nada no
seu computador o imita, então esta seção não foi executada; ela é ensinada pela documentação do Google.

## Ligando, e quanto custa

A varredura é uma API, `containerscanning.googleapis.com`. Com ela ligada, cada imagem enviada a um
repositório do projeto é varrida no envio, e depois **varrida de novo por 30 dias** conforme novos
alertas são publicados: uma imagem limpa na segunda pode ter um achado crítico na quinta, sem ninguém
mexer nela. Depois de 30 dias, uma imagem que não foi baixada deixa de ser atualizada.

A página de preços, lida em 30 de outubro de 2026, cobra **0,26 USD por varredura** na varredura
automática. Os 440 envios por mês da loja custariam 440 × 0,26 = 114,40 USD, umas cem vezes o que custam
os builds da lição 1. Duas formas mantêm isso baixo:

- **varrer só os repositórios que vão para deploy**: a varredura pode ser desligada por repositório, e
  um repositório de imagens descartáveis de branch não precisa dela;
- **enviar menos**: um pull request cujo build envia uma imagem a cada commit paga uma varredura a cada
  commit. Enviar só a partir de `main` paga uma vez por merge.

## Lendo o que ela achou

Os achados de uma imagem, como o `gcloud` os lista:

```sh
gcloud artifacts docker images list southamerica-east1-docker.pkg.dev/planner-dev/shop/api \
  --show-occurrences --occurrence-filter='kind="VULNERABILITY"'
gcloud artifacts docker images describe \
  southamerica-east1-docker.pkg.dev/planner-dev/shop/api@sha256:7f5d… \
  --show-package-vulnerability
```

Cada ocorrência nomeia o CVE, o pacote e a versão instalada, a versão que corrige se houver uma, e duas
severidades: **a do próprio alerta** (da nota CVSS) e **a severidade efetiva da distribuição**, que diz
como ele afeta o build do pacote naquela distribuição. As duas discordam com frequência, e a efetiva é a
que serve para ordenar: um CVE crítico numa funcionalidade de biblioteca que o Debian não compila é
baixo para o Debian.

**Em que agir primeiro** é o achado alto ou crítico, com versão corrigida, numa imagem que roda. Os dois
primeiros dizem que há algo a fazer; o terceiro diz que fazer importa. Para a loja isso quase sempre é a
imagem base: `python:3.12.16-slim` traz os pacotes do Debian, e a correção é uma versão de patch mais
nova da imagem, reconstruída e com novo deploy, não uma mudança no `app.py`. Um achado sem correção é
registrado, acompanhado e julgado pelo uso que se faz do pacote; não é motivo para parar todo deploy.

## A varredura é um relatório, não uma barreira

**Nada num achado impede que uma imagem seja baixada ou vá para deploy.** A varredura escreve um
relatório; não recusa nada. Transformar um relatório numa recusa exige algo que o leia no momento do
deploy, e esse é o assunto da lição 4: uma política que só admite imagens com um atestado, e um passo de
build que só assina uma imagem cuja varredura passou.
