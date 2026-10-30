---
title: Uma rede, todas as regiões
version: 1
---

**Uma rede VPC no Google Cloud é global: uma rede, em todas as regiões ao mesmo tempo, sem faixa de endereços
própria.** As faixas pertencem às **sub-redes**, e uma sub-rede é regional: cobre todas as zonas de uma
região. Duas máquinas na mesma rede, uma em São Paulo e uma em Santiago, se alcançam pelos endereços internos
sem nada no meio para criar, configurar ou pagar por hora. O tráfego continua cobrado por travessia, pelos
preços da lição 1: a rede ser global muda o que tem de ser construído, não quanto custam os bytes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-global\" aria-label=\"A rede planner desenhada como uma caixa que abrange duas regiões. Dentro dela, a região southamerica-east1, São Paulo, tem a sub-rede planner-sao-paulo com a faixa 10.10.0.0/20, e a sub-rede se estende pelas três zonas a, b e c. A região southamerica-west1, Santiago, tem planner-santiago com a faixa 10.11.0.0/20, pelas suas zonas. Uma linha entre uma máquina em cada sub-rede diz endereços internos, nada a construir no meio, cobrado por travessia. Embaixo: a rede, as rotas e as regras de firewall são globais; uma sub-rede é regional; uma máquina é zonal.\"><defs><marker id=\"l15-global-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"16.0\" width=\"680.0\" height=\"226.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"40.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">rede planner: global</text><text x=\"190.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">southamerica-east1</text><text x=\"190.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><rect x=\"40.0\" y=\"84.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"190.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-sao-paulo</text><text x=\"190.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">10.10.0.0/20</text><rect x=\"40.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"86.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona a</text><rect x=\"144.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"190.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona b</text><rect x=\"248.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"294.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona c</text><text x=\"190.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sub-rede cobre as três</text><text x=\"530.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">southamerica-west1</text><text x=\"530.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Santiago</text><rect x=\"380.0\" y=\"84.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"530.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-santiago</text><text x=\"530.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">10.11.0.0/20</text><rect x=\"380.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"426.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona a</text><rect x=\"484.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"530.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona b</text><rect x=\"588.0\" y=\"150.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"634.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona c</text><text x=\"530.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a sub-rede cobre as três</text><path d=\"M342.0 110.0 L378.0 110.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-global-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">global: a rede, as rotas, as regras de firewall</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">regional: uma sub-rede, por todas as zonas da região · zonal: uma máquina</text></svg>", "caption": "Uma rede entre regiões; uma sub-rede entre as zonas de uma.", "same": ["Santiago", "São Paulo"]}
```

Cada tipo de coisa na rede tem o seu escopo, e o escopo faz parte do endereço:

| recurso | escopo | endereço de exemplo |
|---|---|---|
| **rede** | global | `projects/planner-dev/global/networks/planner` |
| **sub-rede** | uma região | `projects/planner-dev/regions/southamerica-east1/subnetworks/planner-sao-paulo` |
| **regra de firewall**, **rota** | globais, pertencentes a uma rede | lições 16 e 17 |
| **máquina** | uma zona, com a interface numa sub-rede da região dessa zona | o próximo curso |

**Uma sub-rede não é uma zona.** Uma máquina em `southamerica-east1-a` e outra em `southamerica-east1-c` podem
dividir uma sub-rede e a faixa dela; espalhar máquinas por zonas para resiliência nunca significa cortar mais
faixas.

## O que as ferramentas supõem

Uma rede pode ser feita em dois modos, o assunto da próxima seção: **automático**, em que o Google cria uma
sub-rede em cada região, e **personalizado**, em que nada existe até alguém escrever. Pergunte ao gcloud qual
ele supõe:

```
ana@laptop:~/gcp$ gcloud compute networks create --help | grep -A1 "subnet-mode=MODE$"
     --subnet-mode=MODE
        The subnet mode of the network. If not specified, defaults to AUTO.
```

O provider do Terraform supõe o mesmo. Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/network && cd ~/gcp/network
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve a rede mais curta que existe como `network.tf`:

```hcl
resource "google_compute_network" "planner" {
  project = "planner-dev"
  name    = "planner"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|auto_create|routing_mode|mtu"
  # google_compute_network.planner will be created
      + auto_create_subnetworks                   = true
      + mtu                                       = (known after apply)
      + routing_mode                              = (known after apply)
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Os dois usam o modo automático por padrão.** Uma rede escrita só com um nome ganha uma sub-rede em cada
região que o Google opera, agora e conforme novas abrem. A próxima seção diz por que o planner desliga isso.

## Perguntando ao Google

O comando que cria a rede que o planner quer, em modo personalizado com roteamento global, é curto, e chega ao
Google:

```
ana@laptop:~/gcp$ gcloud compute networks create planner --subnet-mode=custom --bgp-routing-mode=global
ERROR: (gcloud.compute.networks.create) Could not fetch resource:
 - Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.
```

Recusado, nas palavras do Compute Engine, pelo motivo de toda chamada ao Google neste curso ser recusada: o
laboratório não tem credencial. Todo o resto desta lição é planejado ou calculado no laptop.
