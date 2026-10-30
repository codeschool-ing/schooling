---
title: HA VPN, dois túneis e um router
version: 1
---

**O Cloud VPN une uma rede VPC a outra rede pela internet, por túneis IPsec criptografados.** A outra ponta
costuma ser um escritório ou um datacenter, às vezes outra nuvem. É a entrada barata: nenhum circuito para
pedir, nenhum colocation, funcionando uma hora depois de decidir, pela conexão de internet que o escritório já
tem.

Há dois tipos, e só um vale a pena construir hoje:

| | HA VPN | Classic VPN |
|---|---|---|
| gateway | **duas interfaces, dois endereços externos**, numa região | uma interface |
| roteamento | **só dinâmico, por BGP**, com um Cloud Router | estático ou dinâmico |
| disponibilidade que o Google oferece | **99,99%**, com dois túneis montados como o Google descreve | 99,9% |

Um gateway HA VPN tem duas interfaces para que uma possa falhar, ou passar por manutenção do Google, enquanto a
outra leva o tráfego. O desenho que ganha os 99,99% tem **um túnel de cada interface**, para dois endereços no
roteador do escritório, ou para dois roteadores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l21-ha-vpn\" aria-label=\"O HA VPN do planner. À esquerda, em southamerica-east1, um gateway HA VPN com duas interfaces, 0 e 1, e um Cloud Router com ASN 64514. À direita, o roteador do escritório com dois endereços públicos, 198.51.100.10 e 198.51.100.11, e ASN 65010. Dois túneis criptografados atravessam a internet, um de cada interface para um endereço. Dentro de cada túnel roda uma sessão BGP em endereços link-local, 169.254.0.1 a .2 e 169.254.1.1 a .2. Pelo BGP, o Cloud Router anuncia as sub-redes do planner, 10.10.0.0/16 e 10.11.0.0/16, e aprende o 192.168.0.0/16 do escritório.\"><rect x=\"20.0\" y=\"30.0\" width=\"220.0\" height=\"190.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">southamerica-east1</text><rect x=\"40.0\" y=\"64.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gateway HA VPN</text><text x=\"70.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">if 0</text><text x=\"190.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">if 1</text><rect x=\"40.0\" y=\"150.0\" width=\"180.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Router</text><text x=\"130.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">ASN 64514</text><rect x=\"480.0\" y=\"64.0\" width=\"220.0\" height=\"138.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roteador do escritório</text><text x=\"590.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">198.51.100.10</text><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">198.51.100.11</text><text x=\"590.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">ASN 65010</text><text x=\"590.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><path d=\"M242.0 90.0 L478.0 104.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M242.0 120.0 L478.0 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">túnel 0: BGP 169.254.0.1 – .2</text><text x=\"360.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">túnel 1: BGP 169.254.1.1 – .2</text><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">anunciado: 10.10.0.0/16, 10.11.0.0/16 · aprendido: 192.168.0.0/16</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer túnel carrega tudo; isso é o 99,99%</text></svg>", "caption": "Duas interfaces, dois túneis, BGP em cada: nenhuma rota escrita à mão.", "same": ["Cloud Router"]}
```

## BGP, e por que as rotas não são escritas à mão

O HA VPN não aceita rotas estáticas. Um **Cloud Router** fala BGP com o roteador do escritório por cada túnel:
ele conta ao escritório as faixas das sub-redes do planner, e aprende as do escritório, `192.168.0.0/16`, que
aparecem na rede do planner como as **rotas dinâmicas** da lição 17. Uma sub-rede nova de qualquer lado é
anunciada sem ninguém escrever uma rota, e quando um túnel cai as rotas dele são retiradas e o tráfego passa
para o outro. O **modo de roteamento global** da rede, lição 15, é o que deixa uma rota aprendida pelo router em
São Paulo ser usada também por máquinas em Santiago.

Cada sessão BGP precisa de duas coisas que o arquivo abaixo explicita: um **ASN** para cada lado, das faixas
reservadas para uso privado, e um par de endereços dentro do túnel em **`169.254.0.0/16`**, a faixa link-local,
um `/30` por túnel.

## O enlace do planner com o escritório, escrito

Em `~/gcp/vpn`, com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/vpn && cd ~/gcp/vpn
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `vpn.tf`. O roteador do escritório tem dois endereços públicos, escritos aqui de
`198.51.100.0/24`, uma faixa de documentação; `count = 2` faz dois de cada recurso que vem em par:

```hcl
variable "shared_secret" {
  type      = string
  sensitive = true
}

resource "google_compute_ha_vpn_gateway" "office" {
  project = "planner-network"
  name    = "planner-office"
  network = "planner"
  region  = "southamerica-east1"
}

resource "google_compute_external_vpn_gateway" "office" {
  project         = "planner-network"
  name            = "office-router"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = "198.51.100.10"
  }
  interface {
    id         = 1
    ip_address = "198.51.100.11"
  }
}

resource "google_compute_router" "office" {
  project = "planner-network"
  name    = "planner-office"
  network = "planner"
  region  = "southamerica-east1"

  bgp {
    asn = 64514
  }
}

resource "google_compute_vpn_tunnel" "office" {
  count                           = 2
  project                         = "planner-network"
  name                            = "planner-office-${count.index}"
  region                          = "southamerica-east1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.office.id
  vpn_gateway_interface           = count.index
  peer_external_gateway           = google_compute_external_vpn_gateway.office.id
  peer_external_gateway_interface = count.index
  router                          = google_compute_router.office.id
  shared_secret                   = var.shared_secret
  ike_version                     = 2
}

resource "google_compute_router_interface" "office" {
  count      = 2
  project    = "planner-network"
  name       = "office-${count.index}"
  router     = google_compute_router.office.name
  region     = "southamerica-east1"
  ip_range   = "169.254.${count.index}.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.office[count.index].name
}

resource "google_compute_router_peer" "office" {
  count           = 2
  project         = "planner-network"
  name            = "office-${count.index}"
  router          = google_compute_router.office.name
  region          = "southamerica-east1"
  interface       = google_compute_router_interface.office[count.index].name
  peer_ip_address = "169.254.${count.index}.2"
  peer_asn        = 65010
}
```

```
ana@laptop:~/gcp/vpn$ terraform plan -input=false -no-color 2>&1 | tail -5
   1: variable "shared_secret" {

The root module input variable "shared_secret" is not set, and has no default
value. Use a -var or -var-file command line argument to provide a value for
this variable.
```

**O arquivo não tem segredo nenhum, e o Terraform se recusa a adivinhar um.** A chave pré-compartilhada em que as
duas pontas de um túnel têm de concordar é uma variável, marcada como sensível, e vem de fora do arquivo: uma
variável de ambiente aqui, um gerenciador de segredos num pipeline. Dê a ela uma que claramente não é chave:

```
ana@laptop:~/gcp/vpn$ TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color | grep -E "^Plan|# google|shared_secret|ip_range|peer_asn|asn "
  # google_compute_external_vpn_gateway.office will be created
  # google_compute_ha_vpn_gateway.office will be created
  # google_compute_router.office will be created
          + asn                = 64514
  # google_compute_router_interface.office[0] will be created
      + ip_range            = "169.254.0.1/30"
  # google_compute_router_interface.office[1] will be created
      + ip_range            = "169.254.1.1/30"
  # google_compute_router_peer.office[0] will be created
      + peer_asn                           = 65010
  # google_compute_router_peer.office[1] will be created
      + peer_asn                           = 65010
  # google_compute_vpn_tunnel.office[0] will be created
      + shared_secret                   = (sensitive value)
      + shared_secret_hash              = (known after apply)
      + shared_secret_wo                = (write-only attribute)
  # google_compute_vpn_tunnel.office[1] will be created
      + shared_secret                   = (sensitive value)
      + shared_secret_hash              = (known after apply)
      + shared_secret_wo                = (write-only attribute)
Plan: 9 to add, 0 to change, 0 to destroy.
```

Nove recursos. O segredo aparece como *(sensitive value)*, e o ASN do router, 64514, e o do escritório, 65010,
são os dois privados. **Sensível não é secreto**: o Terraform esconde o valor na tela e mesmo assim o escreve no
arquivo de estado, e é por isso que o provider também oferece `shared_secret_wo`, um atributo só de escrita que
é mandado ao Google e nunca guardado, e por isso que um arquivo de estado é protegido como as chaves que ele
pode conter.

Um ASN fora das faixas privadas é recusado antes de qualquer pergunta. Mude o do router para 100 e planeje:

```
ana@laptop:~/gcp/vpn$ sed -i 's/asn = 64514/asn = 100/' vpn.tf
ana@laptop:~/gcp/vpn$ TF_VAR_shared_secret=placeholder-only terraform plan -input=false -no-color 2>&1 | grep -A1 "^Error"
Error: expected "bgp.0.asn" to be a RFC6996-compliant Local ASN:
must be either in the private ASN ranges: [64512..65534], [4200000000..4294967294];
```

O provider nomeia as faixas na recusa. Volte para 64514 antes de seguir.
