---
title: Private Google Access
version: 1
---

**O Private Google Access deixa uma máquina sem endereço externo alcançar as APIs do Google.** Cloud Storage,
Pub/Sub, BigQuery e o resto são servidos em endereços públicos, e uma máquina só com um endereço interno não
alcança um endereço público sozinha. Com o Private Google Access ligado na sub-rede dela, alcança: os pacotes
saem pela rota do gateway padrão de internet e nunca saem da rede do Google, e nada na internet é alcançável por
esse caminho. É **uma configuração por sub-rede**, `private_ip_google_access` no Terraform, e não muda nada para
máquinas que têm endereço externo.

## Duas faixas do Google

O Google publica dois conjuntos de endereços para alcançar as APIs dele de forma privada, cada um atrás de um
nome que resolve para eles. Pergunte ao resolvedor do próprio laptop:

```
ana@laptop:~/gcp$ getent hosts private.googleapis.com restricted.googleapis.com | sort
199.36.153.10   private.googleapis.com
199.36.153.11   private.googleapis.com
199.36.153.4    restricted.googleapis.com
199.36.153.5    restricted.googleapis.com
199.36.153.6    restricted.googleapis.com
199.36.153.7    restricted.googleapis.com
199.36.153.8    private.googleapis.com
199.36.153.9    private.googleapis.com
```

**Respostas reais**, do DNS público: quatro endereços cada, as faixas `/30` `199.36.153.8/30` e
`199.36.153.4/30`.

| nome | faixa | o que alcança |
|---|---|---|
| `private.googleapis.com` | `199.36.153.8/30` | a maior parte das APIs do Google |
| `restricted.googleapis.com` | `199.36.153.4/30` | só as APIs que o VPC Service Controls consegue proteger, para que um perímetro em volta dos dados de um projeto não possa ser contornado |

Nenhum dos dois é usado por padrão. Uma máquina que pede `storage.googleapis.com` recebe os endereços públicos
comuns, que o Private Google Access também alcança, e isso basta para a maioria das redes. Uma empresa que quer
toda chamada de API indo para uma das duas faixas cria uma **zona DNS privada** para `googleapis.com` que
responde com elas, lição 19, e uma rota para a faixa, a `private-googleapis` da seção anterior. Essa é a
produção do planner: sem rota padrão, uma rota só para `199.36.153.8/30`, e o DNS mandando `*.googleapis.com`
para lá.

## Ligando

A sub-rede de São Paulo da lição 15, com o Private Google Access ligado. Em `~/gcp/pga`, com o arquivo do
provider da lição 2:

```sh
mkdir -p ~/gcp/pga && cd ~/gcp/pga
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve como `subnet.tf`:

```hcl
resource "google_compute_subnetwork" "sao_paulo" {
  project                  = "planner-dev"
  name                     = "planner-sao-paulo"
  network                  = "planner"
  region                   = "southamerica-east1"
  ip_cidr_range            = "10.10.0.0/20"
  private_ip_google_access = true
}
```

```
ana@laptop:~/gcp/pga$ terraform plan -input=false -no-color | grep -E "^Plan|private_ip_google_access"
      + private_ip_google_access         = true
Plan: 1 to add, 0 to change, 0 to destroy.
```

Uma linha do arquivo. O que ela não faz importa tanto quanto: **ela não abre regra de firewall e não precisa de
nenhuma de entrada**, já que a máquina inicia a conexão e a regra implícita da lição 16 permite a saída; e **ela
não dá permissão**. Uma máquina que alcança o Cloud Storage ainda precisa que a conta de serviço dela tenha um
papel no bucket, lição 8, e alcançar a API sem um é uma recusa do IAM, não da rede.
