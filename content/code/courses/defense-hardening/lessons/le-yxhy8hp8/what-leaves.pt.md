---
title: Os jeitos de os dados saírem
version: 1
---

**Prevenção de perda de dados trata dos dados, não da máquina.** Todas as outras aulas deste curso
protegem um computador de alguém de fora. A DLP parte do fato oposto: a maioria das pessoas que
consegue levar a lista de clientes da Jatobá para fora do escritório tem permissão para lê-la, e na
maioria das vezes em que ela sai, ninguém quis fazer mal. Um contador manda uma planilha para o
próprio e-mail para terminar em casa. Um estagiário sobe um arquivo num site de conversão. Um notebook
com uma pasta que sincroniza com uma conta pessoal na nuvem vai para a assistência técnica.

A imagem comum é a de uma ferramenta que para ladrões. Uma ferramenta de DLP para sobretudo
**enganos**, e o caso deliberado é o mais difícil: alguém decidido a levar um arquivo pode fotografar
a tela. Isso não torna a DLP inútil; torna-a um controle cujos números são honestos sobre o que pega.

## Três estados

A DLP usa uma distinção que vale guardar, porque cada estado é protegido num lugar diferente:

| estado | onde os dados estão | onde são vigiados |
|---|---|---|
| **em repouso** | num arquivo, num banco de dados, num backup | numa varredura dos discos: onde estão os dados pessoais, e deveriam estar ali |
| **em trânsito** | cruzando uma rede: e-mail, um upload, uma sincronização | na borda da rede, ou no endpoint antes de serem cifrados |
| **em uso** | abertos num programa: copiados, impressos, colados, postos num pendrive | só no endpoint, por um agente que vê a ação |

## Os canais

De uma estação como o `desk`, os dados saem por uma lista curta de portas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-channels\" aria-label=\"A estação desk no meio, com cinco jeitos de os dados saírem dela. O e-mail passa pelo gateway de e-mail do escritório, que consegue ler anexos. Uploads pela web cruzam a rede cifrados. Uma pasta sincronizada envia em segundo plano, também cifrado. Um pendrive e uma impressora são ações na própria máquina. Só o endpoint vê os cinco enquanto o arquivo ainda está legível.\"><defs><marker id=\"l09-channels-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">aqui o arquivo é legível</text><rect x=\"25.0\" y=\"28.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">e-mail</text><text x=\"110.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gateway lê anexos</text><rect x=\"525.0\" y=\"28.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"610.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">upload pela web</text><text x=\"610.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cifrado na rede</text><rect x=\"525.0\" y=\"228.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"610.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pasta sincronizada</text><text x=\"610.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cifrado na rede</text><rect x=\"25.0\" y=\"228.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pendrive</text><text x=\"110.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na própria máquina</text><rect x=\"275.0\" y=\"246.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">impressora</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">na própria máquina</text><path d=\"M270.0 125.0 L195.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M450.0 125.0 L525.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M450.0 175.0 L525.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M270.0 175.0 L195.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M360.0 190.0 L360.0 246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path></svg>", "caption": "Cinco portas. Um equipamento de rede lê uma delas; o endpoint fica na frente das cinco."}
```

Cada porta tem um controle diferente. O e-mail passa por um gateway que o escritório roda, que
consegue ler anexos. Uploads pela web passam pela rede, mas quase todos são cifrados, então um
equipamento de rede não lê nada a menos que decifre o tráfego, o que é a inspeção de TLS, uma decisão
com custos e questões de privacidade próprias. Mídias removíveis e impressão acontecem na própria
máquina, e a aula 5 trata de fechar a primeira. Clientes de sincronização parecem tráfego web cifrado
comum vistos de fora, e só são visíveis no endpoint.

**Então é no endpoint que a maior parte da DLP tem de morar.** É o único lugar onde o arquivo ainda é
legível no momento em que está prestes a sair, seja qual for a porta. Esta aula constrói as duas
metades no `desk`: uma conferência de conteúdo que sabe como são os dados pessoais, e uma regra de
rede que sabe para onde os dados podem ir.

Suba o laboratório com as máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up desk web trap
```

O `desk` é a estação de trabalho, o `web` é o portal do próprio escritório, e o `trap` faz o papel do
mundo lá fora: um lugar para onde um arquivo poderia ser enviado e que não é do escritório.
