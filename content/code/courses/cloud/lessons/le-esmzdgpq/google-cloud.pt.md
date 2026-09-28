---
title: "Google Cloud: projetos, uma rede só, dados e Kubernetes"
version: 1
---

O Google chegou à venda de infraestrutura pela outra ponta. O seu primeiro produto de nuvem, o App
Engine, em 2008, era uma plataforma no sentido da lição 1: você enviava uma aplicação e o Google a
rodava, sem máquina nenhuma à vista. As máquinas virtuais vieram depois, com o Compute Engine. Duas
coisas que o Google construiu para si muito antes de vendê-las ainda são aquilo pelo que ele é
conhecido: **lidar com volumes muito grandes de dados, e rodar contêineres em muitas máquinas ao
mesmo tempo.**

## O projeto é a caixa

No Google Cloud, todo recurso pertence a um **projeto**. Você cria um projeto, liga-o a uma conta de
faturamento que paga por ele, e constrói lá dentro. Um projeto tem um id que você escolhe uma vez,
como `shop-prod-2291`, e esse id não pode ser mudado depois, então vale escolher bem.

Projetos podem ser agrupados em pastas sob uma **organização**, que está ligada ao domínio da
empresa. Desligar um projeto para tudo o que está dentro dele de uma vez, e o projeto fica guardado
por trinta dias, para o caso de ter sido um engano, antes de ser apagado de vez.

Ponha as caixas dos três provedores lado a lado e a diferença está em quantos níveis existem, não na
ideia:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três colunas de caixas aninhadas. AWS: uma organização, tracejada porque é opcional, contém uma conta, que contém os recursos. Azure: um tenant contém uma assinatura, que contém um grupo de recursos, que contém os recursos. Google Cloud: uma organização contém uma pasta, tracejada porque é opcional, que contém um projeto, que contém os recursos. A caixa mais interna de cada coluna está destacada.\"><defs><marker id=\"unt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">AWS</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">organização</text><rect x=\"34\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conta</text><rect x=\"44\" y=\"104\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma VM</text><rect x=\"44\" y=\"130\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um disco</text><rect x=\"44\" y=\"156\" width=\"152\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um bucket</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Azure</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">tenant (Entra ID)</text><rect x=\"274\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"284\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">assinatura</text><rect x=\"288\" y=\"108\" width=\"144\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">grupo de recursos</text><rect x=\"298\" y=\"138\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma VM</text><rect x=\"298\" y=\"164\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um disco</text><rect x=\"298\" y=\"190\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um bucket</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Google Cloud</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"232\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">organização</text><rect x=\"514\" y=\"74\" width=\"172\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"524\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">pasta</text><rect x=\"528\" y=\"108\" width=\"144\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">projeto</text><rect x=\"538\" y=\"138\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma VM</text><rect x=\"538\" y=\"164\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um disco</text><rect x=\"538\" y=\"190\" width=\"124\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um bucket</text></svg>", "caption": "Destacada, a caixa em que todo recurso tem de estar: uma conta, um grupo de recursos, um projeto. As tracejadas são opcionais. A cobrança fica na conta, na assinatura, e numa conta de faturamento ligada a cada projeto.", "same": ["AWS", "Azure", "Google Cloud", "tenant (Entra ID)"]}
```

## Uma rede para o mundo inteiro

Esta é a diferença que muda projetos. Na AWS uma VPC pertence a uma região, e o mesmo vale para uma
rede virtual do Azure: uma máquina em São Paulo e uma em Frankfurt estão em duas redes, e ligá-las é
trabalho extra que a lição 6 nomeia. **No Google Cloud uma rede VPC é global.** As sub-redes são
regionais, mas uma rede só contém todas elas, então uma máquina em São Paulo (`southamerica-east1`)
e uma na Bélgica (`europe-west1`) estão na mesma rede privada, sem nenhuma ligação entre duas redes
para construir. As regras de firewall continuam decidindo o que pode passar.

Isso não encurta a distância: um pacote de São Paulo à Bélgica ainda atravessa um oceano, e a lição 9
mede quanto isso custa. O que some é o encanamento.

## Dados e Kubernetes

O **BigQuery** é o produto em que essa fama com dados se apoia. É um data warehouse que roda SQL sobre
tabelas muito grandes sem servidor nenhum para dimensionar: você carrega os dados, roda uma consulta,
e paga pelos dados que a consulta lê ou por capacidade reservada antes. É a ideia de serverless da
lição 8, aplicada à análise de dados.

**O Kubernetes saiu do Google.** Foi projetado por engenheiros do Google a partir do que tinham
aprendido operando o Borg, o sistema interno da empresa para distribuir contêineres pelas máquinas, e
lançado como código aberto em 2014. A versão gerenciada do Google, o GKE, foi uma das primeiras, e
mantém a fama de acompanhar o projeto de perto. As três hyperscalers vendem Kubernetes gerenciado
hoje, e a DigitalOcean e a Akamai também; o curso `kubernetes` é onde ele é ensinado.

As regiões do Google Cloud seguem um padrão: um continente e uma direção, depois um número. A região
de São Paulo é `southamerica-east1`. O produto de funções se chamava Cloud Functions até 2024 e hoje
é o **Cloud Run functions**, parte do Cloud Run, o serviço para rodar contêineres sem administrar
servidores; tutoriais mais velhos usam o nome antigo.

O curso `gcp-foundations` parte deste com o console, o comando `gcloud` e as políticas da
organização. O que levar daqui: **o projeto é a caixa, a rede é global, e os argumentos mais fortes
do Google são dados e Kubernetes.**
