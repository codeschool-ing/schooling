---
title: O objetivo, escrito como regras
version: 2
---

Um SLI calculado à mão é uma consulta. Um objetivo com que uma equipe convive é **um conjunto de
regras de gravação**, avaliadas a cada poucos segundos e guardadas como séries. Assim painéis e
alertas leem os mesmos números e ninguém redigite a expressão com outra janela. As da loja, em
`prometheus/rules/slo.yml`, um arquivo a salvar do jeito que o `cat` abaixo o imprime:

```
ana@obs:~/shop$ cat prometheus/rules/slo.yml
# The checkout's service level objective: 99.5% of checkouts do not fail on
# our side. The window is one hour so that a lesson can watch it move; in
# production it would be 28 days, and every expression below is the same.
groups:
  - name: checkout-slo
    interval: 30s
    rules:
      - record: checkout:sli_availability:ratio_rate5m
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[5m]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[5m]))
      - record: checkout:sli_availability:ratio_rate1h
        expr: |
          sum(rate(http_server_requests_total{job="storefront",route="/checkout",code!~"5.."}[1h]))
          / sum(rate(http_server_requests_total{job="storefront",route="/checkout"}[1h]))
      - record: checkout:sli_latency:ratio_rate1h
        expr: |
          sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[1h]))
          / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[1h]))
      - record: checkout:error_budget_remaining:ratio_1h
        expr: 1 - (1 - checkout:sli_availability:ratio_rate1h) / (1 - 0.995)
```

Quatro séries, nomeadas pela convenção `nível:métrica:operação`, que diz o que foi agregado, a partir
de quê, e como:

- **`checkout:sli_availability:ratio_rate5m`** e **`…ratio_rate1h`**: o SLI de disponibilidade em duas
  janelas. A curta é para acompanhar um incidente; a longa é a janela do objetivo.
- **`checkout:sli_latency:ratio_rate1h`**: a fração respondida em até meio segundo.
- **`checkout:error_budget_remaining:ratio_1h`**: o que resta do orçamento, como fração. 1 quer dizer
  intacto, 0 quer dizer gasto, e um número negativo quer dizer que o objetivo foi descumprido.

**A janela é de uma hora.** Um objetivo real usa 28 dias, e uma aula não pode esperar 28 dias para
vê-lo se mexer. Então o laboratório a comprime: toda expressão é a mesma com `[28d]` no lugar de
`[1h]`, e toda conclusão escala. O Prometheus recebe a ordem de ler o arquivo de novo:

```
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == "checkout-slo") | .rules[] | [.name, .health] | @tsv'
checkout:sli_availability:ratio_rate5m	unknown
checkout:sli_availability:ratio_rate1h	unknown
checkout:sli_latency:ratio_rate1h	unknown
checkout:error_budget_remaining:ratio_1h	unknown
```

As quatro regras estão carregadas, com saúde `unknown` porque nenhuma foi avaliada ainda. Trinta
segundos depois existem os primeiros valores.

Duas notas práticas. Um `rate` de 28 dias sobre contadores crus lê 28 dias de amostras a cada
avaliação, o que é caro. Montagens reais gravam as razões de janela curta e tiram a média delas, ou
guardam a janela longa num armazenamento feito para isso. E **o objetivo, 0.995, está escrito num
lugar só**: se ele aparece em todo alerta e todo painel, o dia em que muda é o dia em que eles
começam a discordar.