---
title: Ingress and the Application Load Balancer
version: 1
---

An Ingress describes HTTP routing: which host and which path go to which Service. Kubernetes leaves
the implementation to a controller, and **on GKE the built-in controller turns every Ingress into
an external Application Load Balancer**: a global, layer 7 load balancer, with one address for all
the routes, TLS terminated by Google, and the cluster's Services behind it as backends.

## The manifest

The shop's two public paths, with a reserved address and a certificate Google manages. Shown from
Google's documentation; not run:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: shop
  annotations:
    kubernetes.io/ingress.global-static-ip-name: shop-web
    networking.gke.io/managed-certificates: shop-cert
spec:
  defaultBackend:
    service:
      name: web
      port:
        number: 80
  rules:
    - http:
        paths:
          - path: /api/orders
            pathType: Prefix
            backend:
              service:
                name: orders
                port:
                  number: 80
```

From this one object GKE builds the whole chain in your project: a forwarding rule on the reserved
address, a target proxy holding the certificate, a URL map with the two routes, a backend service
for each Kubernetes Service, and a health check for each backend. **It takes several minutes**, and
an Ingress that has just been applied answers with errors from Google's front end until the health
checks have passed.

## The address, reserved first

`kubernetes.io/ingress.global-static-ip-name` names an address that must already exist. It is a
plain Compute Engine resource, so it is written in Terraform like any other. Create a folder `lb` in
`~/gcp` with this `address.tf`:

```hcl
# lb/address.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_compute_global_address" "shop_web" {
  name = "shop-web"
}
```

After `terraform init`, the plan:

```
ana@laptop:~/gcp/lb$ terraform plan -no-color | grep -E '^  #|address|name|^Plan'
  # google_compute_global_address.shop_web will be created
  + resource "google_compute_global_address" "shop_web" {
      + address            = (known after apply)
      + name               = "shop-web"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**The address itself is `(known after apply)`**: Google assigns it, and from then on it stays the
shop's for as long as the resource exists, whatever happens to the Ingress. That is the point of
reserving it outside the cluster. The DNS record for the shop's domain points at this address, and
deleting and recreating the Ingress, or replacing the whole cluster, no longer moves it.

It is **global** because the external Application Load Balancer is: one anycast address announced
from Google's edge everywhere, with traffic entering Google's network close to the customer and
travelling to `southamerica-east1` inside it. A regional address would not do for this Ingress.

## The certificate

`networking.gke.io/managed-certificates` names a `ManagedCertificate`, a small GKE object listing
the domains:

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: shop-cert
  namespace: shop
spec:
  domains:
    - shop.example.com
```

Google issues and renews the certificate itself, but only after the domain's DNS points at the
load balancer's address, because that is how the certificate authority checks the domain is
yours. A certificate stuck in `Provisioning` is almost always a DNS record not yet pointing at
`shop-web`, which is one more reason to reserve the address before anything else.
