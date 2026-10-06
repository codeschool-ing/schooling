---
title: Quando o fornecedor falha
version: 1
---

APIs de modelo falham de jeitos comuns: um limite de taxa (HTTP 429), um erro interno (500), um servidor ocupado demais para responder (o 529 da Anthropic, *overloaded*). A maioria passa em um ou dois segundos, e a resposta certa é esperar e tentar de novo. **A pergunta para um agente é quem faz a nova tentativa**, porque há três candidatos: o SDK, o adaptador e o laço.

O labllm sabe falhar a pedido. O `/lab/config` recebe o status a devolver e quantas vezes, e só responde a partir da própria máquina. Aqui ele falha duas vezes, depois três:

```
ana@lab:~/agents$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 2}"; echo
{"rpm": 50, "fail_next": 529, "fail_count": 2}
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." | head -n 1
answered after 4 steps, 2401 tokens
ana@lab:~/agents$ tail -n 6 /var/log/labllm/requests.jsonl | python -c 'import json, sys; print(*[json.loads(l)["status"] for l in sys.stdin])'
529 529 200 200 200 200
ana@lab:~/agents$ curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_next\": 529, \"fail_count\": 3}"; echo
{"rpm": 50, "fail_next": 529, "fail_count": 3}
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_lab_0023'}
```

Com duas falhas, a execução respondeu como se nada tivesse acontecido: `answered after 4 steps, 2401 tokens`, igual a sem falhas. O log do labllm mostra o que aconteceu por baixo: `529 529 200`, e depois os outros três pedidos da execução. **O SDK da anthropic tentou de novo duas vezes, sozinho, e não avisou ninguém.** O padrão dele é `max_retries=2`, com espera exponencial começando em meio segundo, e ele repete 408, 409, 429 e todo status 5xx. Com três falhas as tentativas acabaram, e a execução terminou com `anthropic.OverloadedError`, um 529.

## Decida qual camada repete

**As novas tentativas do SDK costumam ser a primeira camada certa**: tratam uma pane curta num pedido, respeitam cabeçalhos `retry-after` e mantêm o laço simples. Saiba que elas existem, e saiba os limites delas. Duas tentativas com espera cobrem um ou dois segundos de problema, não um minuto.

**O laço não deveria repetir um pedido às cegas por cima do SDK.** Duas camadas de três tentativas cada são nove pedidos, e uma pane longa o bastante para esgotar as tentativas do SDK é longa o bastante para que um cliente seja mais bem atendido por um resultado parado do que por uma execução que trava. O `minagent` passa `max_retries` ao SDK e deixa a exceção se propagar, que é a regra da aula 4: uma pane não é algo que o modelo conserta, então não é resultado de ferramenta.

**Onde uma nova tentativa no nível da execução faz sentido, ela precisa ser idempotente.** Repetir uma execução inteira depois de uma queda refaz toda chamada de ferramenta, o que é inofensivo para leituras e perigoso para escritas, e é exatamente para isso que existem as chaves de idempotência da aula 4.

**Limites de taxa merecem tratamento próprio.** Um 429 diz que você está mandando rápido demais, e tentar de novo mais rápido piora. Num sistema que roda muitos agentes, a correção é um limite de execuções concorrentes ou de pedidos por minuto, imposto antes de o pedido sair, e não uma nova tentativa depois que ele falha.
