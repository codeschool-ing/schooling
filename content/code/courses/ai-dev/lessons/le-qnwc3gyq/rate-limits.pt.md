---
title: Limites de taxa
version: 1
---

Todo provedor limita quanto uma conta pode pedir: requisições por minuto, tokens por minuto e,
muitas vezes, tokens por dia. Os números dependem do nível da conta e do modelo, e ficam no console
do provedor. **O que importa ao código é o que acontece no limite**: o provedor responde 429 e diz
quando tentar de novo.

O labllm pode ser mandado a permitir três requisições por minuto, para o limite aparecer
funcionando:

```python
"""Five requests in a row, with the SDK's retries off, to see the limit as it is."""
import anthropic

model = anthropic.Anthropic(max_retries=0)
for n in range(1, 6):
    try:
        raw = model.messages.with_raw_response.create(
            model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
        print(n, raw.http_response.status_code, "remaining:", raw.headers["anthropic-ratelimit-requests-remaining"])
    except anthropic.RateLimitError as e:
        print(n, e.status_code, "retry-after:", e.response.headers["retry-after"], "|", e.message)
```

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"rpm": 3, "clear": true}' >/dev/null; python burst.py
1 200 remaining: 2
2 200 remaining: 1
3 200 remaining: 0
4 429 retry-after: 60 | Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'This request would exceed the rate limit of 3 requests per minute.'}, 'request_id': 'req_lab_0009'}
5 429 retry-after: 60 | Error code: 429 - {'type': 'error', 'error': {'type': 'rate_limit_error', 'message': 'This request would exceed the rate limit of 3 requests per minute.'}, 'request_id': 'req_lab_0010'}
```

**Os cabeçalhos fazem a contagem regressiva antes de o limite chegar.** Cada resposta bem-sucedida
diz quantas requisições sobram na janela: 2, 1, 0. A quarta recebe 429 e `retry-after: 60`, o número
de segundos até a requisição mais antiga sair da janela. Os cabeçalhos reais da Anthropic têm esses
nomes; os outros provedores mandam a mesma informação com nomes próprios.

## O que fazer com um 429

- **Espere o que o `retry-after` diz**, não menos. Repetir antes só rende outro 429.
- **Leia a contagem restante antes de chegar a zero.** Um job em lote que vê `remaining: 1` pode
  desacelerar em vez de falhar.
- **Divida o limite de propósito.** Uma chave serve a todo usuário da aplicação. Uma fila na frente
  do modelo, com limite por usuário, impede o pico de um usuário de gastar o minuto de todos.
- **Peça mais quando os números pedirem.** Os limites sobem com o uso e com um pedido ao provedor.
  Um projeto que só funciona num nível mais alto precisa saber qual nível e como chegar lá.
