---
title: Zonas privadas, sobreposições e encaminhamento
version: 1
---

**Uma zona privada responde só às redes que ela lista, e para elas ela ganha da internet.** Essa segunda metade
é o que torna zonas privadas úteis além de nomes internos: uma zona privada para um domínio público sobrepõe a
resposta pública, para aquelas redes e ninguém mais. É assim que a rede de produção da lição 17 manda toda
chamada a `*.googleapis.com` para a faixa privada.

## A sobreposição que a lição 17 prometeu

Salve isto como `googleapis.tf` em `~/gcp/dns-zones`, ao lado das zonas da primeira seção:

```hcl
resource "google_dns_managed_zone" "googleapis" {
  project    = "planner-network"
  name       = "googleapis"
  dns_name   = "googleapis.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }
}

resource "google_dns_record_set" "private_a" {
  project      = "planner-network"
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "private.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_dns_record_set" "everything_else" {
  project      = "planner-network"
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}
```

Os quatro endereços são os que o `getent` devolveu na lição 17. O curinga diz que **qualquer outro nome em
`googleapis.com` é `private.googleapis.com`**, então `storage.googleapis.com`, perguntado a partir da rede
planner, volta como um dos quatro endereços privados, enquanto a mesma pergunta feita em qualquer outro lugar
recebe a resposta pública do Google. A real, do laptop:

```
ana@laptop:~/gcp/dns-zones$ getent hosts storage.googleapis.com | head -3
74.125.201.207  storage.googleapis.com
192.178.209.207 storage.googleapis.com
74.125.69.207   storage.googleapis.com
```

**Endereços públicos**, porque o laptop não está na rede planner e nenhuma zona privada se aplica a ele. De uma
máquina nessa rede, depois de um apply, o mesmo comando imprimiria um de `199.36.153.8` a `.11`; isso não
rodou aqui.

## Encaminhando para o escritório

O escritório tem o próprio servidor DNS, em `192.168.0.53`, que conhece os nomes das máquinas do escritório sob
`office.planner.internal`. Uma **zona de encaminhamento** é uma zona privada que responde perguntando a outro: o
Cloud DNS manda as perguntas por esse nome ao servidor do escritório, pela VPN da lição 21, e devolve o que ele
disser. Acrescente ao `googleapis.tf`:

```hcl
resource "google_dns_managed_zone" "office" {
  project    = "planner-network"
  name       = "office"
  dns_name   = "office.planner.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/planner-network/global/networks/planner"
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address = "192.168.0.53"
    }
  }
}
```

```
ana@laptop:~/gcp/dns-zones$ terraform plan -input=false -no-color | grep -E "^Plan|# google|dns_name|ipv4_address"
  # google_dns_managed_zone.googleapis will be created
      + dns_name         = "googleapis.com."
  # google_dns_managed_zone.internal will be created
      + dns_name         = "planner.internal."
  # google_dns_managed_zone.office will be created
      + dns_name         = "office.planner.internal."
              + ipv4_address    = "192.168.0.53"
  # google_dns_managed_zone.public will be created
      + dns_name         = "planner.example.com."
  # google_dns_record_set.everything_else will be created
  # google_dns_record_set.private_a will be created
Plan: 6 to add, 0 to change, 0 to destroy.
```

Seis recursos: as duas zonas da primeira seção, a sobreposição e os seus dois conjuntos de registros, e a zona
de encaminhamento. A outra direção, o escritório perguntando ao Cloud DNS sobre `planner.internal`, exige uma
**política de servidor DNS** com encaminhamento de entrada na rede planner, que dá ao Cloud DNS um endereço na
sub-rede de cada região para o servidor do escritório encaminhar.

## Quem responde o quê

Uma máquina na rede planner pergunta ao resolvedor do servidor de metadados, e ele responde nesta ordem:

1. uma zona privada, de encaminhamento ou de peering visível para a rede, o nome **mais específico** primeiro:
   `office.planner.internal.` antes de `planner.internal.`;
2. os nomes internos que o Compute Engine dá a toda máquina, `NAME.ZONE.c.PROJECT.internal`;
3. o DNS público da internet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l19-order\" aria-label=\"Uma máquina na rede planner pergunta um nome ao resolvedor do servidor de metadados em 169.254.169.254. O resolvedor tenta três lugares em ordem e para no primeiro que tem o nome. Primeiro, as zonas privadas que a rede pode ver, a mais específica primeiro: office.planner.internal é encaminhada ao servidor do escritório em 192.168.0.53, planner.internal é respondida pelo Cloud DNS, e googleapis.com é a sobreposição que manda toda API para a faixa privada. Segundo, os nomes internos que o Compute Engine dá às máquinas. Terceiro, o DNS público da internet. Uma nota diz que uma zona privada toma o domínio inteiro: um nome que falta nela é respondido como inexistente, e a internet nunca é perguntada.\"><defs><marker id=\"l19-order-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"100.0\" width=\"170.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma máquina pergunta</text><text x=\"105.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">169.254.169.254</text><rect x=\"260.0\" y=\"20.0\" width=\"440.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"276.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. zonas privadas, a mais específica primeiro</text><text x=\"276.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">office.planner.internal.</text><text x=\"684.0\" y=\"64.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">encaminhada a 192.168.0.53</text><text x=\"276.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.internal.</text><text x=\"684.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">respondida pelo Cloud DNS</text><text x=\"276.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">googleapis.com.</text><text x=\"684.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sobreposição: a faixa privada</text><rect x=\"260.0\" y=\"156.0\" width=\"440.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. nomes internos das máquinas</text><text x=\"684.0\" y=\"173.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">NAME.ZONE.c.PROJECT.internal</text><rect x=\"260.0\" y=\"206.0\" width=\"440.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. DNS público</text><path d=\"M192.0 120.0 L256.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-order-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o primeiro lugar que tem o domínio responde, mesmo que o nome não exista</text></svg>", "caption": "Uma zona privada é perguntada primeiro, e toma o domínio inteiro."}
```

**A primeira correspondência é final.** Se a zona privada de `googleapis.com` não tem registro para um nome nem
curinga, a resposta é *nome inexistente*, não a resposta pública: uma zona privada para um domínio toma o
domínio inteiro. É por isso que a sobreposição precisa do curinga, e por isso que uma zona privada para um
domínio que a empresa não possui é uma decisão a ler com cuidado.
