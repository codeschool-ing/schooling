---
title: A cadeia, elo por elo
version: 1
---

**Um Application Load Balancer não é um recurso, mas cinco, numa cadeia**, e cada elo tem um trabalho. Um
pedido desce por ela, do endereço que o cliente digitou até a máquina que responde:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-chain\" aria-label=\"A cadeia de um Application Load Balancer externo global, da esquerda para a direita, do jeito que um pedido viaja. A regra de encaminhamento guarda o endereço e a porta 443. O proxy HTTPS de destino guarda o certificado e termina o TLS. O mapa de URL manda /api/* para o serviço de backend api e o resto para o serviço de backend web. Cada serviço de backend tem uma verificação de saúde, em /healthz porta 8080, e balanceia entre os seus backends, as máquinas que respondem. Embaixo da cadeia, uma seta no sentido contrário diz que os recursos são criados da direita para a esquerda, já que cada elo nomeia o seguinte.\"><defs><marker id=\"l20-chain-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-chain-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-chain-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">regra de encaminhamento</text><text x=\"80.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">endereço, porta 443</text><rect x=\"160.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">proxy HTTPS</text><text x=\"220.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">certificado, TLS</text><rect x=\"300.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mapa de URL</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">host e caminho</text><path d=\"M142.0 100.0 L158.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-amber)\"></path><path d=\"M282.0 100.0 L298.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-amber)\"></path><rect x=\"460.0\" y=\"30.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backend api</text><text x=\"520.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/api/*</text><path d=\"M422.0 100.0 L456.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"610.0\" y=\"30.0\" width=\"90.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">máquinas</text><text x=\"655.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">próximo curso</text><path d=\"M582.0 60.0 L606.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"460.0\" y=\"130.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backend web</text><text x=\"520.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">todo o resto</text><path d=\"M422.0 100.0 L456.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"610.0\" y=\"130.0\" width=\"90.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">máquinas</text><text x=\"655.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">próximo curso</text><path d=\"M582.0 160.0 L606.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><text x=\"520.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">saúde em /healthz</text><path d=\"M700.0 218.0 L20.0 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">criados neste sentido: cada elo nomeia o seguinte</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um pedido viaja da esquerda para a direita</text></svg>", "caption": "Cinco elos: onde chega, TLS, a rota, o balanceamento, as máquinas.", "same": ["backend api", "backend web"]}
```

| elo | recurso | o trabalho dele |
|---|---|---|
| **regra de encaminhamento** | `google_compute_global_forwarding_rule` | um endereço IP e uma porta: onde os pedidos chegam |
| **proxy de destino** | `google_compute_target_https_proxy` | termina a conexão TLS, guardando o certificado |
| **mapa de URL** | `google_compute_url_map` | lê o host e o caminho e escolhe um serviço de backend |
| **serviço de backend** | `google_compute_backend_service` | como balancear entre os backends, e que verificação de saúde diz que eles estão vivos |
| **backends** | grupos de instâncias ou grupos de endpoints de rede | as máquinas ou contêineres que respondem, o assunto do próximo curso |

O endereço, a verificação de saúde e o certificado ficam pendurados nessa cadeia como recursos próprios.

## O site do planner, escrito

Tudo menos os backends, que precisam de máquinas: um endereço, uma verificação de saúde em `/healthz` porta
8080, dois serviços de backend, um mapa de URL que manda `/api/*` para um e todo o resto para o outro, um
certificado gerenciado pelo Google, o proxy e a regra de encaminhamento. Em `~/gcp/lb`, com o arquivo do
provider da lição 2:

```sh
mkdir -p ~/gcp/lb && cd ~/gcp/lb
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `lb.tf`:

```hcl
resource "google_compute_global_address" "web" {
  project = "planner-prod"
  name    = "planner-web"
}

resource "google_compute_health_check" "web" {
  project = "planner-prod"
  name    = "planner-web"

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}

resource "google_compute_backend_service" "web" {
  project               = "planner-prod"
  name                  = "planner-web"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  health_checks         = [google_compute_health_check.web.id]
}

resource "google_compute_backend_service" "api" {
  project               = "planner-prod"
  name                  = "planner-api"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  health_checks         = [google_compute_health_check.web.id]
}

resource "google_compute_url_map" "web" {
  project         = "planner-prod"
  name            = "planner-web"
  default_service = google_compute_backend_service.web.id

  host_rule {
    hosts        = ["planner.example.com"]
    path_matcher = "planner"
  }

  path_matcher {
    name            = "planner"
    default_service = google_compute_backend_service.web.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api.id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "web" {
  project = "planner-prod"
  name    = "planner-web"

  managed {
    domains = ["planner.example.com."]
  }
}

resource "google_compute_target_https_proxy" "web" {
  project          = "planner-prod"
  name             = "planner-web"
  url_map          = google_compute_url_map.web.id
  ssl_certificates = [google_compute_managed_ssl_certificate.web.id]
}

resource "google_compute_global_forwarding_rule" "web" {
  project               = "planner-prod"
  name                  = "planner-web"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.web.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.web.id
}
```

```
ana@laptop:~/gcp/lb$ terraform plan -input=false -no-color 2>&1 | grep -E "^Plan|^Error|# google"
  # google_compute_backend_service.api will be created
  # google_compute_backend_service.web will be created
  # google_compute_global_address.web will be created
  # google_compute_global_forwarding_rule.web will be created
  # google_compute_health_check.web will be created
  # google_compute_managed_ssl_certificate.web will be created
  # google_compute_target_https_proxy.web will be created
  # google_compute_url_map.web will be created
Plan: 8 to add, 0 to change, 0 to destroy.
```

Oito recursos. **A ordem em que eles têm de ser criados é a cadeia lida de trás para frente**, já que cada elo
nomeia o seguinte, e o Terraform a deduz das referências no arquivo. Peça a ele o grafo de dependências:

```
ana@laptop:~/gcp/lb$ terraform graph | grep -- '->' | grep -v provider | sed 's/\[root\] //g; s/ (expand)//g; s/"//g'
  google_compute_backend_service.api -> google_compute_health_check.web;
  google_compute_backend_service.web -> google_compute_health_check.web;
  google_compute_global_forwarding_rule.web -> google_compute_global_address.web;
  google_compute_global_forwarding_rule.web -> google_compute_target_https_proxy.web;
  google_compute_target_https_proxy.web -> google_compute_managed_ssl_certificate.web;
  google_compute_target_https_proxy.web -> google_compute_url_map.web;
  google_compute_url_map.web -> google_compute_backend_service.api;
  google_compute_url_map.web -> google_compute_backend_service.web;
```

Cada linha é *precisa de*: a regra de encaminhamento precisa do endereço e do proxy; o proxy precisa do
certificado e do mapa de URL; o mapa precisa dos dois serviços de backend; cada serviço de backend precisa da
verificação de saúde. Lida de baixo, é a ordem de criação, e lida de cima, o caminho de um pedido.

Três coisas no arquivo dizem mais do que mostram:

- **`EXTERNAL_MANAGED`** nos serviços de backend e na regra de encaminhamento escolhe o Application Load
  Balancer externo global atual. O antigo `EXTERNAL` é o *clássico*, que ainda funciona e tem menos recursos de
  roteamento; os dois não se misturam numa cadeia.
- **O certificado gerenciado é emitido pelo Google, mas só depois que o DNS aponta para o endereço.** O Google
  prova que o planner controla `planner.example.com` alcançando o balanceador por esse nome, então a ordem numa
  conta real é: criar o endereço, criar o registro `A` da lição 19 com ele, e aí o certificado sai do estado
  `PROVISIONING`, o que pode levar uma hora.
- **A verificação de saúde é uma promessa que os backends têm de cumprir**: um HTTP 200 em `/healthz` porta
  8080, a partir de `35.191.0.0/16` e `130.211.0.0/22`. Um backend que falha nela não recebe tráfego, e um
  firewall que esquece essas faixas derruba todo backend de uma vez.
