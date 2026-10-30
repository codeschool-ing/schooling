---
title: Um pedido, três jeitos
version: 1
---

**O console, a linha de comando e a infraestrutura declarada são três portas para uma sala.** Atrás de cada uma
está a mesma API, a que a lição 24 chamou à mão, e o que chega a ela por qualquer uma é o mesmo pedido: um verbo,
o nome de um recurso, um corpo. Esta lição torna isso concreto criando três tópicos por três portas e lendo o que
cada uma mandou, e depois olha o que acontece quando duas portas são usadas no mesmo recurso.

Inicie o emulador vazio, como na lição 1, e crie um diretório para o Terraform com o Pub/Sub apontado para ele, do
mesmo jeito que a lição 25 fez:

```sh
mkdir -p ~/gcp/doors && cd ~/gcp/doors
cp ~/gcp/hierarchy/provider.tf .
sed -i 's|  access_token = "placeholder"|  access_token = "placeholder"\n\n  pubsub_custom_endpoint = "http://localhost:8085/v1/"|' provider.tf
terraform init -input=false
```

## Porta um: o gcloud

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics create orders --log-http 2>&1 | grep -E "^(uri|method):"
uri: http://localhost:8085/v1/projects/planner-dev/topics/orders?alt=json
method: PUT
```

## Porta dois: a própria API

```
ana@laptop:~/gcp/doors$ curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/topics/invoices
{
  "name": "projects/planner-dev/topics/invoices"
}
```

## Porta três: o Terraform

Salve isto como `topics.tf`:

```hcl
resource "google_pubsub_topic" "shipments" {
  name   = "shipments"
  labels = { team = "planner" }
}
```

O provider do Terraform registra os pedidos HTTP quando se pede com `TF_LOG=DEBUG`. O log é longo; o `grep` guarda
as linhas de pedido e as de status, e o `sed` tira o horário e o nome do provider do começo de cada uma:

```
ana@laptop:~/gcp/doors$ TF_LOG=DEBUG terraform apply -input=false -no-color -auto-approve 2>&1 | grep -E "(PUT|GET|POST|DELETE|PATCH) /v1|HTTP/1.1 [0-9]{3}" | sed -E "s/^.*_x5: //"
PUT /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
GET /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
GET /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
```

**O mesmo `PUT` no mesmo tipo de endereço**, e depois dois `GET`s: o Terraform lê o recurso de volta depois de
criá-lo, para registrar no estado o que o servidor guarda e não o que ele mandou. Essa leitura é toda a diferença
entre o Terraform e as outras duas portas, e a próxima seção é sobre para que ela serve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l26-doors\" aria-label=\"Quatro portas à esquerda: o console, o gcloud, o curl e o Terraform. Cada uma manda o mesmo pedido, um PUT do nome de um tópico em /v1/projects/planner-dev/topics, a uma API no meio, que guarda os tópicos orders, invoices e shipments à direita. Só o Terraform tem uma segunda seta, um GET de volta da API para o arquivo de estado dele, chamada refresh: ele lê o que existe, e um plano compara isso com os arquivos. Uma mudança feita por outra porta aparece ali como drift.\"><defs><marker id=\"l26-doors-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-doors-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l26-doors-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o console</text><path d=\"M172.0 40.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"72.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">gcloud</text><path d=\"M172.0 92.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"124.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl</text><path d=\"M172.0 144.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"176.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Terraform</text><path d=\"M172.0 196.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"80.0\" width=\"160.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"380.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma API</text><text x=\"380.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">PUT /v1/…/topics/NAME</text><text x=\"380.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pubsub.googleapis.com</text><path d=\"M462.0 120.0 L536.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-amber)\"></path><rect x=\"540.0\" y=\"60.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"620.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><text x=\"620.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shipments</text><path d=\"M380 162 C 380 236, 110 248, 110 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l26-doors-af-ah-phosphor)\"></path><text x=\"400.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">refresh: GET do que existe, depois comparar com os arquivos</text><text x=\"360.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma mudança por outra porta é o que um plano relata como drift</text></svg>", "caption": "Toda porta manda o mesmo pedido; só o Terraform lê de volta e compara.", "same": ["Terraform"]}
```

## A quarta porta

O console é a mesma coisa de novo. Criar um tópico no formulário dele manda um `PUT` com o mesmo corpo a partir do
navegador, com as credenciais da pessoa conectada; as ferramentas de desenvolvedor do navegador o mostram na aba
de rede. Isso não foi feito aqui, já que o console exige uma conta, e este curso não mostrou captura de tela dele
de propósito: as telas mudam no calendário do Google, e o pedido por baixo delas não.

Os três tópicos existem, e nada neles diz que porta os fez:

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics list --format="value(name.basename())"
invoices
orders
shipments
```
