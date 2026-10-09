---
title: Asking from outside what a customer would ask
version: 2
---

Every check so far ran next to the service. **A check from outside sees what nothing inside can**:
the DNS name, the certificate, the load balancer and the network between the customer and the shop.
The blackbox exporter of lesson 5 is that kind of check, and it was asking the wrong question.

The right question is the customer's. The lab's `blackbox.yml` has a second module that does not
read a health endpoint at all: it **places an order**.

```
ana@obs:~/shop$ sed -n '/^  checkout:/,$p' blackbox.yml
  checkout:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
      body: '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}'
      valid_status_codes: [201]
```

Asked by hand through the exporter, with the database still stopped from the previous section:

```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '
probe_http_status_code 502
probe_success 0
```

**Status 502, success 0**: the same answer a customer got. With the database started again:

```sh
docker compose start postgres
```


```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '
probe_http_status_code 201
probe_success 1
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 28 seconds (healthy)
```

This is a *synthetic check*, the open-source cousin of what lesson 13's products sell from many
countries at once. It is the best outside check there is, and it has costs that `/health` does not:

- **Every probe is a real order.** Here it is one kettle every time it runs, stored, charged to a
  test card and confirmed by e-mail. A real shop marks such requests, a header or a reserved
  customer, so that they can be left out of sales reports and never reach a warehouse, and uses a
  payment method that charges nobody.
- **It tests one path.** A checkout of a kettle says nothing about the search page or the account
  page; each path worth watching needs its own check.
- **It is still a sample.** One probe every fifteen seconds is four a minute against the shop's
  three hundred real checkouts, so the error ratio of lesson 5 sees a partial outage the probe can
  miss.

Used together they cover each other: **the probe notices an outage when there is no traffic**, at
three in the morning, and the error ratio measures how much of the real traffic it hurt. Which of the
two should wake somebody is lesson 16's question.

Before the next lesson, take the health check away again:

```sh
rm compose.override.yaml
docker compose up -d orders
```
