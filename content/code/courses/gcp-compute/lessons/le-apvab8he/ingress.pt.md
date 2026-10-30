---
title: Ingress e o Application Load Balancer
version: 1
---

Um Ingress descreve roteamento HTTP: qual host e qual caminho vão para qual Service. O Kubernetes
deixa a implementação para um controlador, e **no GKE o controlador embutido transforma todo
Ingress num Application Load Balancer externo**: um balanceador global de camada 7, com um endereço
para todas as rotas, TLS terminado pelo Google e os Services do cluster atrás dele como backends.

## O manifesto

Os dois caminhos públicos da loja, com um endereço reservado e um certificado gerenciado pelo
Google. Vem da documentação do Google; não foi executado:

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

A partir desse único objeto o GKE monta a cadeia inteira no seu projeto: uma regra de
encaminhamento no endereço reservado, um proxy de destino segurando o certificado, um mapa de URL
com as duas rotas, um backend service para cada Service do Kubernetes e uma verificação de saúde
para cada backend. **Leva vários minutos**, e um Ingress recém-aplicado responde com erros do
front-end do Google até as verificações de saúde passarem.

## O endereço, reservado antes

`kubernetes.io/ingress.global-static-ip-name` nomeia um endereço que já precisa existir. É um
recurso comum do Compute Engine, então é escrito em Terraform como qualquer outro. Crie uma pasta
`lb` em `~/gcp` com este `address.tf`:

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

Depois do `terraform init`, o plan:

```
ana@laptop:~/gcp/lb$ terraform plan -no-color | grep -E '^  #|address|name|^Plan'
  # google_compute_global_address.shop_web will be created
  + resource "google_compute_global_address" "shop_web" {
      + address            = (known after apply)
      + name               = "shop-web"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**O endereço em si é `(known after apply)`**: o Google o atribui, e daí em diante ele fica com a
loja enquanto o recurso existir, aconteça o que acontecer com o Ingress. É para isso que ele é
reservado fora do cluster. O registro DNS do domínio da loja aponta para esse endereço, e apagar e
recriar o Ingress, ou trocar o cluster inteiro, não o move mais.

Ele é **global** porque o Application Load Balancer externo é: um endereço anycast anunciado da
borda do Google em toda parte, com o tráfego entrando na rede do Google perto do cliente e seguindo
até `southamerica-east1` por dentro dela. Um endereço regional não serviria para este Ingress.

## O certificado

`networking.gke.io/managed-certificates` nomeia um `ManagedCertificate`, um pequeno objeto do GKE
que lista os domínios:

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

O Google emite e renova o certificado sozinho, mas só depois que o DNS do domínio aponta para o
endereço do balanceador, porque é assim que a autoridade certificadora confere que o domínio é seu.
Um certificado preso em `Provisioning` quase sempre é um registro DNS que ainda não aponta para
`shop-web`, mais um motivo para reservar o endereço antes de tudo.
