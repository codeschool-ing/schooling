---
title: Shared VPC: uma rede, vários projetos
version: 1
---

**O Shared VPC deixa um projeto ser dono de uma rede e outros projetos porem máquinas nela.** O dono é o
**projeto host**; os outros são **projetos de serviço**. A rede, as sub-redes, as rotas e as regras de firewall
vivem no host e são operadas pela equipe de rede. As máquinas, os bancos e os clusters vivem nos projetos de
serviço e são operados pelas equipes donas deles, cada um cobrado no próprio projeto. É assim que uma empresa
tem uma rede sem ter um projeto só.

O desenho do planner da lição 2 foi feito para isso. O `planner-network`, na pasta `shared`, é o host, e o
`planner-prod` e o `planner-staging` são projetos de serviço presos a ele:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-shared\" aria-label=\"O projeto host planner-network guarda a rede planner, com duas sub-redes: planner-prod-sao-paulo e planner-staging-sao-paulo, e as regras de firewall. A equipe de rede a opera. Embaixo, dois projetos de serviço, planner-prod e planner-staging, cada um com as próprias máquinas, que ficam nas sub-redes do host: máquinas de produção na sub-rede de prod, máquinas de staging na de staging. O grupo de desenvolvedores tem Network User só na sub-rede de staging. Cada projeto de serviço paga pelas próprias máquinas e pelo tráfego delas.\"><defs><marker id=\"l18-shared-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"16.0\" width=\"680.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"40.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">projeto host planner-network</text><text x=\"680.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">operado pela equipe de rede</text><rect x=\"60.0\" y=\"52.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-prod-sao-paulo</text><rect x=\"380.0\" y=\"52.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-staging-sao-paulo</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rede planner: sub-redes, rotas, regras de firewall</text><rect x=\"60.0\" y=\"180.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">projeto de serviço planner-prod</text><text x=\"200.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">máquinas de produção</text><text x=\"200.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cobradas aqui</text><path d=\"M200.0 178.0 L200.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-shared-af-ah-phosphor)\"></path><rect x=\"380.0\" y=\"180.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">projeto de serviço planner-staging</text><text x=\"520.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">máquinas de staging</text><text x=\"520.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cobradas aqui</text><path d=\"M520.0 178.0 L520.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-shared-af-ah-phosphor)\"></path><text x=\"530.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">planner-devs: Network User</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma rede, operada num lugar; máquinas e contas ficam com as equipes</text></svg>", "caption": "O host é dono da rede; os projetos de serviço, do que roda nela.", "same": ["planner-devs: Network User"]}
```

## Quem faz o quê

O Shared VPC divide o trabalho de uma rede entre quatro papéis, e isso é a maior parte do valor dele:

| papel | dado em | deixa quem o tem |
|---|---|---|
| `roles/compute.xpnAdmin`, Shared VPC Admin | a organização ou uma pasta | tornar um projeto host, e prender projetos de serviço a ele |
| `roles/compute.networkAdmin` | o projeto host | criar e mudar redes, sub-redes e rotas |
| `roles/compute.securityAdmin` | o projeto host | criar e mudar regras de firewall |
| `roles/compute.networkUser`, Network User | o projeto host, ou **uma sub-rede** dele | criar recursos num projeto de serviço que usem essa sub-rede |

A última linha é a que importa no dia a dia. **Uma equipe com Network User numa sub-rede pode pôr máquinas ali
e em nenhum outro lugar**, enquanto a sub-rede, a faixa dela e o firewall na frente dela continuam da equipe de
rede. Dar o papel no projeto host inteiro entrega toda sub-rede à equipe, que é o atalho que o planner não
toma. (`xpn` no nome do papel é o antigo nome interno do recurso, e nunca mudou.)

Um projeto de serviço fica preso a **um host de cada vez**, e um host não pode ser ele mesmo um projeto de
serviço. Os dois têm de estar na mesma organização.

## Escrevendo

Em `~/gcp/shared-vpc`, com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/shared-vpc && cd ~/gcp/shared-vpc
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `shared.tf`. Ele torna o `planner-network` um host, prende os dois projetos de serviço, e dá
ao grupo de desenvolvedores a sub-rede de staging e nada mais:

```hcl
resource "google_compute_shared_vpc_host_project" "network" {
  project = "planner-network"
}

resource "google_compute_shared_vpc_service_project" "prod" {
  host_project    = google_compute_shared_vpc_host_project.network.project
  service_project = "planner-prod"
}

resource "google_compute_shared_vpc_service_project" "staging" {
  host_project    = google_compute_shared_vpc_host_project.network.project
  service_project = "planner-staging"
}

resource "google_compute_subnetwork_iam_member" "devs_use_staging" {
  project    = "planner-network"
  region     = "southamerica-east1"
  subnetwork = "planner-staging-sao-paulo"
  role       = "roles/compute.networkUser"
  member     = "group:planner-devs@example.com"
}
```

```
ana@laptop:~/gcp/shared-vpc$ terraform plan -input=false -no-color | grep -E "^Plan|# google|role|member"
  # google_compute_shared_vpc_host_project.network will be created
  # google_compute_shared_vpc_service_project.prod will be created
  # google_compute_shared_vpc_service_project.staging will be created
  # google_compute_subnetwork_iam_member.devs_use_staging will be created
  + resource "google_compute_subnetwork_iam_member" "devs_use_staging" {
      + member     = "group:planner-devs@example.com"
      + role       = "roles/compute.networkUser"
Plan: 4 to add, 0 to change, 0 to destroy.
```

Quatro recursos, planejados e não criados. Aplicá-los exige o papel de Shared VPC Admin na organização, que
ninguém neste laboratório tem. **A cobrança segue a máquina, não a rede**: uma máquina que o `planner-staging`
cria na sub-rede compartilhada é cobrada no `planner-staging`, e o tráfego que ela manda também, e é isso que
mantém verdadeira a consulta por projeto da lição 14 depois que a rede saiu dos projetos.
