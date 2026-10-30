---
title: One request, three ways
version: 1
---

**The console, the command line and declared infrastructure are three doors into one room.** Behind each is the
same API, the one lesson 24 called by hand, and what reaches it from any of them is the same request: a verb, a
resource's name, a body. This lesson makes that concrete by creating three topics through three doors and
reading what each one sent, and then looks at what happens when two doors are used on the same resource.

Start the emulator empty, as in lesson 1, and make a directory for Terraform with Pub/Sub pointed at it, the
same way lesson 25 did:

```sh
mkdir -p ~/gcp/doors && cd ~/gcp/doors
cp ~/gcp/hierarchy/provider.tf .
sed -i 's|  access_token = "placeholder"|  access_token = "placeholder"\n\n  pubsub_custom_endpoint = "http://localhost:8085/v1/"|' provider.tf
terraform init -input=false
```

## Door one: gcloud

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics create orders --log-http 2>&1 | grep -E "^(uri|method):"
uri: http://localhost:8085/v1/projects/planner-dev/topics/orders?alt=json
method: PUT
```

## Door two: the API itself

```
ana@laptop:~/gcp/doors$ curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/topics/invoices
{
  "name": "projects/planner-dev/topics/invoices"
}
```

## Door three: Terraform

Save this as `topics.tf`:

```hcl
resource "google_pubsub_topic" "shipments" {
  name   = "shipments"
  labels = { team = "planner" }
}
```

Terraform's provider logs its HTTP requests when asked with `TF_LOG=DEBUG`. The log is long; the `grep` keeps
the request lines and the status lines, and the `sed` removes the timestamp and the provider's name from the
front of each:

```
ana@laptop:~/gcp/doors$ TF_LOG=DEBUG terraform apply -input=false -no-color -auto-approve 2>&1 | grep -E "(PUT|GET|POST|DELETE|PATCH) /v1|HTTP/1.1 [0-9]{3}" | sed -E "s/^.*_x5: //"
PUT /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
GET /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
GET /v1/projects/planner-dev/topics/shipments?alt=json HTTP/1.1
HTTP/1.1 200 OK
```

**The same `PUT` to the same kind of address**, and then two `GET`s: Terraform reads the resource back after
creating it, to record in its state what the server holds rather than what it sent. That read is the whole
difference between Terraform and the other two doors, and the next section is what it is for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l26-doors\" aria-label=\"Four doors on the left: the console, gcloud, curl and Terraform. Each sends the same request, a PUT of a topic's name to /v1/projects/planner-dev/topics, to one API in the middle, which holds the topics orders, invoices and shipments on the right. Terraform alone has a second arrow, a GET back from the API to its state file, labelled refresh: it reads what exists, and a plan compares that with its files. A change made through another door shows up there as drift.\"><defs><marker id=\"l26-doors-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-doors-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l26-doors-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the console</text><path d=\"M172.0 40.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"72.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">gcloud</text><path d=\"M172.0 92.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"124.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl</text><path d=\"M172.0 144.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"176.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Terraform</text><path d=\"M172.0 196.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"80.0\" width=\"160.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"380.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one API</text><text x=\"380.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">PUT /v1/…/topics/NAME</text><text x=\"380.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pubsub.googleapis.com</text><path d=\"M462.0 120.0 L536.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-amber)\"></path><rect x=\"540.0\" y=\"60.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"620.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><text x=\"620.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shipments</text><path d=\"M380 162 C 380 236, 110 248, 110 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l26-doors-af-ah-phosphor)\"></path><text x=\"400.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">refresh: GET what exists, then compare with the files</text><text x=\"360.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a change through another door is what a plan reports as drift</text></svg>", "caption": "Every door sends the same request; only Terraform reads back and compares."}
```

## The fourth door

The console is the same again. Creating a topic in its form sends a `PUT` with the same body from the
browser, with the signed-in person's credentials; the browser's developer tools show it in their network tab.
That was not done here, since the console needs an account, and this course has not shown a screenshot of it
on purpose: the screens change on Google's schedule, and the request under them does not.

All three topics exist, and nothing about them says which door made them:

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics list --format="value(name.basename())"
invoices
orders
shipments
```
