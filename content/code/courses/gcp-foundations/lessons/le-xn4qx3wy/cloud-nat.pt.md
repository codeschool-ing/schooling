---
title: Cloud NAT: sair, e nunca entrar
version: 1
---

**Uma máquina sem endereço externo só alcança a internet pelo Cloud NAT**, e pelo Cloud NAT ela só pode
iniciar conexões, nunca aceitá-las. Essa assimetria é o ponto. Os servidores de aplicação do planner baixam
pacotes e chamam um provedor de pagamentos; ninguém na internet tem motivo para abrir uma conexão com eles, e
sem endereço externo e sem caminho de entrada, ninguém consegue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-ways-out\" aria-label=\"Uma máquina na sub-rede de São Paulo só com endereço interno, 10.10.0.5. Todo o tráfego de saída dela sai pela rota do gateway padrão de internet. Para a internet, passa pelo Cloud NAT, configurado num Cloud Router na região, que deixa a máquina iniciar conexões e devolve as respostas. Para as APIs do Google, como o Cloud Storage, o Private Google Access na sub-rede a deixa passar sem NAT. Uma conexão iniciada da internet para a máquina está desenhada riscada: não há caminho de entrada.\"><defs><marker id=\"l17-ways-out-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-ways-out-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"230.0\" height=\"190.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner-sao-paulo</text><text x=\"135.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Private Google Access: ligado</text><rect x=\"55.0\" y=\"110.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma máquina</text><text x=\"135.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.10.0.5</text><text x=\"135.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem endereço externo</text><rect x=\"320.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"395.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cloud NAT</text><text x=\"395.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">num Cloud Router</text><rect x=\"540.0\" y=\"40.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a internet</text><rect x=\"540.0\" y=\"150.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">APIs do Google</text><text x=\"620.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">storage.googleapis.com</text><path d=\"M252.0 112.0 L316.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-amber)\"></path><path d=\"M472.0 70.0 L536.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-amber)\"></path><text x=\"505.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">saída, e respostas</text><path d=\"M252.0 160.0 L536.0 180.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17-ways-out-af-ah-phosphor)\"></path><text x=\"380.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sem NAT</text><path d=\"M620 102 L620 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"620.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">entrada: nenhum caminho</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda saída sai pela rota do gateway padrão de internet</text></svg>", "caption": "NAT para a internet, Private Google Access para o Google; nada entra.", "same": ["Cloud NAT"]}
```

O Cloud NAT também não é uma máquina. Não há instância para dimensionar, atualizar ou tornar redundante: ele é
uma configuração num **Cloud Router** numa região, e a rede do Google traduz os endereços dos pacotes que saem
pela rota do **gateway padrão de internet**. Duas consequências saem dessa frase:

- **ele é regional**: um NAT em São Paulo serve as sub-redes de São Paulo, e Santiago precisa do seu;
- **ele precisa da rota padrão.** Uma rede que a apagou, como a seção anterior fez, não tem nada para o NAT
  traduzir. Essa é a produção do planner: sem rota padrão, sem NAT, e nada de fora além das próprias APIs do
  Google, o assunto da próxima seção. As redes de desenvolvimento e de staging mantêm os dois.

## Escrevendo um

Em `~/gcp/nat`, com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/nat && cd ~/gcp/nat
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `nat.tf`. A rota no fim é a da faixa privada de APIs do Google da seção anterior, escrita em
Terraform:

```hcl
resource "google_compute_router" "sao_paulo" {
  project = "planner-dev"
  name    = "planner-sao-paulo"
  network = "planner"
  region  = "southamerica-east1"
}

resource "google_compute_router_nat" "sao_paulo" {
  project                            = "planner-dev"
  name                               = "planner-sao-paulo"
  router                             = google_compute_router.sao_paulo.name
  region                             = "southamerica-east1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_route" "private_google" {
  project          = "planner-dev"
  name             = "private-googleapis"
  network          = "planner"
  dest_range       = "199.36.153.8/30"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}
```

```
ana@laptop:~/gcp/nat$ terraform plan -input=false -no-color | grep -E "^Plan|# google|min_ports|nat_ip_allocate|dest_range|next_hop_gateway|enable_endpoint|udp_idle|tcp_established"
  # google_compute_route.private_google will be created
      + dest_range                 = "199.36.153.8/30"
      + next_hop_gateway           = "default-internet-gateway"
  # google_compute_router.sao_paulo will be created
  # google_compute_router_nat.sao_paulo will be created
      + enable_endpoint_independent_mapping = (known after apply)
      + min_ports_per_vm                    = (known after apply)
      + nat_ip_allocate_option              = "AUTO_ONLY"
      + tcp_established_idle_timeout_sec    = 1200
      + udp_idle_timeout_sec                = 30
Plan: 3 to add, 0 to change, 0 to destroy.
```

Três recursos, planejados e não criados. **`AUTO_ONLY`** deixa o Google escolher os endereços externos do NAT e
acrescentar mais conforme precisar; a alternativa, `MANUAL_ONLY`, nomeia endereços reservados, que é o que uma
empresa faz quando um parceiro só aceita chamadas de uma lista fixa. Os tempos limite vieram dos padrões do
próprio provider, 30 segundos para um mapeamento UDP ocioso e 1200 para uma conexão TCP estabelecida; as portas
que cada máquina pode usar ficam para o Google preencher. **Registrar só erros** guarda o momento em que o NAT
fica sem portas para uma máquina, que é a falha que um NAT tem, e não cada conexão, que seria uma fatura à
parte.

## O que custa

A página de preços do Cloud NAT, lida em 30 de outubro de 2026, cobra um gateway de NAT público em três partes,
iguais em toda região:

| parte | preço |
|---|---|
| o gateway | 0,0014 USD por hora para cada máquina que o usa, até 32 máquinas; 0,044 por hora acima disso |
| dados processados | 0,045 USD por GiB, nos dois sentidos |
| cada endereço externo que ele usa | 0,005 USD por hora |

**A cobrança de processamento é a que cresce.** Dez máquinas o mês inteiro custam uns 10 dólares de gateway e
menos de 4 por um endereço; um terabyte de downloads de pacotes por ele custa uns 46 dólares de processamento,
além do que o próprio tráfego custar. Uma máquina que baixa uma imagem de contêiner grande toda vez que inicia
pode fazer do NAT a maior linha da fatura de um projeto pequeno, e é a primeira coisa a procurar quando a lista
da lição 13 leva aos SKUs de rede.
