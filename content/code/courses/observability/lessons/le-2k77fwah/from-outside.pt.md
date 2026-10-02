---
title: Perguntando de fora o que um cliente perguntaria
version: 1
---

Toda verificação até aqui rodou ao lado do serviço. **Uma verificação de fora vê o que nada de dentro
vê**: o nome no DNS, o certificado, o balanceador e a rede entre o cliente e a loja. O blackbox
exporter da aula 5 é esse tipo de verificação, e estava fazendo a pergunta errada.

A pergunta certa é a do cliente. O `blackbox.yml` do laboratório tem um segundo módulo que não lê
endpoint de saúde nenhum: ele **faz um pedido**.

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

Perguntado à mão pelo exporter, com o banco ainda parado desde a seção anterior:

```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '
probe_http_status_code 502
probe_success 0
```

**Status 502, sucesso 0**: a mesma resposta que um cliente recebeu. Com o banco iniciado de novo:

```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- 'http://blackbox-exporter:9115/probe?module=checkout&target=http://storefront:8080/checkout' | grep -E '^probe_(success|http_status_code) '
probe_http_status_code 201
probe_success 1
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 28 seconds (healthy)
```

Isso é uma *verificação sintética*, a prima de código aberto do que os produtos da aula 13 vendem a
partir de vários países ao mesmo tempo. É a melhor verificação de fora que existe, e tem custos que o
`/health` não tem:

- **Toda sonda é um pedido real.** Aqui é uma chaleira cada vez que ela roda, guardada, cobrada num
  cartão de teste e confirmada por e-mail. Uma loja real marca essas requisições, um cabeçalho ou um
  cliente reservado, para que fiquem fora dos relatórios de vendas e nunca cheguem a um depósito, e usa
  um meio de pagamento que não cobra ninguém.
- **Ela testa um caminho.** Um checkout de uma chaleira não diz nada sobre a página de busca ou a de
  conta; cada caminho que vale vigiar precisa da própria verificação.
- **Ainda é uma amostra.** Uma sonda a cada quinze segundos são quatro por minuto contra os trezentos
  checkouts reais da loja, então a taxa de erros da aula 5 vê uma queda parcial que a sonda pode
  perder.

Usadas juntas, uma cobre a outra: **a sonda percebe uma queda quando não há tráfego**, às três da manhã,
e a taxa de erros mede quanto do tráfego real ela feriu. Qual das duas deve acordar alguém é a pergunta
da aula 16.
