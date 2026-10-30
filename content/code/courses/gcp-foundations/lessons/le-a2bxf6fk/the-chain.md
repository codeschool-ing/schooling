---
title: The chain, link by link
version: 1
---

**An Application Load Balancer is not one resource but five, in a chain**, and each link has one job. A
request travels down it from the address the customer typed to the machine that answers:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-chain\" aria-label=\"The chain of a global external Application Load Balancer, from left to right, the way a request travels. The forwarding rule holds the address and port 443. The target HTTPS proxy holds the certificate and ends TLS. The URL map sends /api/* to the api backend service and everything else to the web backend service. Each backend service has a health check, on /healthz port 8080, and balances across its backends, the machines that answer. Under the chain, an arrow pointing the other way says that resources are created from right to left, since each link names the next.\"><defs><marker id=\"l20-chain-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-chain-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-chain-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">forwarding rule</text><text x=\"80.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">address, port 443</text><rect x=\"160.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">HTTPS proxy</text><text x=\"220.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">certificate, TLS</text><rect x=\"300.0\" y=\"70.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">URL map</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">host and path</text><path d=\"M142.0 100.0 L158.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-amber)\"></path><path d=\"M282.0 100.0 L298.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-amber)\"></path><rect x=\"460.0\" y=\"30.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backend api</text><text x=\"520.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/api/*</text><path d=\"M422.0 100.0 L456.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"610.0\" y=\"30.0\" width=\"90.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">machines</text><text x=\"655.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">next course</text><path d=\"M582.0 60.0 L606.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"460.0\" y=\"130.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">backend web</text><text x=\"520.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">everything else</text><path d=\"M422.0 100.0 L456.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><rect x=\"610.0\" y=\"130.0\" width=\"90.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">machines</text><text x=\"655.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">next course</text><path d=\"M582.0 160.0 L606.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-phosphor)\"></path><text x=\"520.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">health check /healthz</text><path d=\"M700.0 218.0 L20.0 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-chain-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">created in this direction: each link names the next</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a request travels left to right</text></svg>", "caption": "Five links: where it arrives, TLS, the route, the balancing, the machines."}
```

| link | resource | its job |
|---|---|---|
| **forwarding rule** | `google_compute_global_forwarding_rule` | an IP address and a port: where requests arrive |
| **target proxy** | `google_compute_target_https_proxy` | ends the TLS connection, holding the certificate |
| **URL map** | `google_compute_url_map` | reads the host and the path and chooses a backend service |
| **backend service** | `google_compute_backend_service` | how to balance across its backends, and which health check says they are alive |
| **backends** | instance groups or network endpoint groups | the machines or containers that answer, the next course's subject |

The address, the health check and the certificate hang off that chain as resources of their own.

## The planner's website, written

Everything except the backends, which need machines: one address, a health check on `/healthz` port 8080,
two backend services, a URL map that sends `/api/*` to one and everything else to the other, a
Google-managed certificate, the proxy and the forwarding rule. In `~/gcp/lb`, with lesson 2's provider file:

```sh
mkdir -p ~/gcp/lb && cd ~/gcp/lb
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `lb.tf`:

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

Eight resources. **The order they must be created in is the chain read backwards**, since each link names the
one after it, and Terraform works it out from the references in the file. Ask it for the dependency graph:

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

Each line is *needs*: the forwarding rule needs the address and the proxy; the proxy needs the certificate
and the URL map; the URL map needs both backend services; each backend service needs the health check. Read
from the bottom, that is the order of creation, and read from the top, the path of a request.

Three things in the file say more than they show:

- **`EXTERNAL_MANAGED`** on the backend services and the forwarding rule chooses the current global external
  Application Load Balancer. The older `EXTERNAL` is the *classic* one, which still works and has fewer
  routing features; the two cannot be mixed in one chain.
- **The managed certificate is issued by Google, but only once DNS points at the address.** Google proves the
  planner controls `planner.example.com` by reaching the load balancer at that name, so the order in a real
  account is: create the address, create the `A` record of lesson 19 with it, and then the certificate leaves
  its `PROVISIONING` state, which can take an hour.
- **The health check is a promise the backends must keep**: an HTTP 200 on `/healthz` port 8080, from
  `35.191.0.0/16` and `130.211.0.0/22`. A backend that fails it receives no traffic, and a firewall that
  forgets those ranges fails every backend at once.
