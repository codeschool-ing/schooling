---
title: Quando o fornecedor falha
version: 2
---

APIs de modelo falham de jeitos comuns: um limite de taxa (HTTP 429), um erro interno (500), um servidor ocupado demais para responder (o 529 da Anthropic, *overloaded*). A maioria passa em um ou dois segundos, e a resposta certa é esperar e tentar de novo. **A pergunta para um agente é quem faz a nova tentativa**, porque há três candidatos: o SDK, o adaptador e o laço.

Para ver quem repete, ponha na frente do Ollama algo que falhe de propósito. O `flaky.py` responde aos primeiros N pedidos do jeito que a API da Anthropic responde quando está sobrecarregada, com um 529 e o mesmo corpo de erro, e repassa todo pedido seguinte ao Ollama. Ele imprime cada status que manda. Salve-o como `~/agents/flaky.py`:

```python
"""flaky.py N: answer the first N requests on port 11437 with 529 Overloaded, then pass the rest on to Ollama."""
import http.client
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

left = int(sys.argv[1])


class Flaky(BaseHTTPRequestHandler):
    def do_POST(self):
        global left
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if left > 0:
            left -= 1
            status = 529
            data = json.dumps({"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}).encode()
        else:
            upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
            upstream.request("POST", self.path, body, {"Content-Type": "application/json"})
            reply = upstream.getresponse()
            status, data = reply.status, reply.read()
        print(status, flush=True)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11437), Flaky).serve_forever()
```

Rode uma vez deixando dois pedidos falharem, e outra deixando três:

```
ana@lab:~/agents$ python flaky.py 2 > flaky.log &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." | head -n 1
answered after 2 steps, 726 tokens
ana@lab:~/agents$ cat flaky.log
529
529
200
200
ana@lab:~/agents$ pkill -f "^python flaky.py"
ana@lab:~/agents$ python flaky.py 3 > flaky.log &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11437 python run.py "Can I return the copy of Dracula I bought in September? My order is M1047." 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}
ana@lab:~/agents$ cat flaky.log
529
529
529
```

Com duas falhas, a execução respondeu como se nada tivesse acontecido: `answered after 2 steps, 726 tokens`. O log do `flaky.py` mostra o que aconteceu por baixo: `529 529 200 200`, duas recusas e depois os dois pedidos reais da execução. **O SDK da anthropic tentou de novo duas vezes, sozinho, e não avisou ninguém.** O padrão dele é `max_retries=2`, com espera exponencial começando em meio segundo, e ele repete 408, 409, 429 e todo status 5xx. Com três falhas as tentativas acabaram depois de três investidas, e a execução terminou com `anthropic.OverloadedError`, um 529.

## Decida qual camada repete

**As novas tentativas do SDK costumam ser a primeira camada certa**: tratam uma pane curta num pedido, respeitam cabeçalhos `retry-after` e mantêm o laço simples. Saiba que elas existem, e saiba os limites delas. Duas tentativas com espera cobrem um ou dois segundos de problema, não um minuto.

**O laço não deveria repetir um pedido às cegas por cima do SDK.** Duas camadas de três tentativas cada são nove pedidos, e uma pane longa o bastante para esgotar as tentativas do SDK é longa o bastante para que um cliente seja mais bem atendido por um resultado parado do que por uma execução que trava. O `minagent` passa `max_retries` ao SDK e deixa a exceção se propagar, que é a regra da aula 4: uma pane não é algo que o modelo conserta, então não é resultado de ferramenta.

**Onde uma nova tentativa no nível da execução faz sentido, ela precisa ser idempotente.** Repetir uma execução inteira depois de uma queda refaz toda chamada de ferramenta, o que é inofensivo para leituras e perigoso para escritas, e é exatamente para isso que existem as chaves de idempotência da aula 4.

**Limites de taxa merecem tratamento próprio.** Um 429 diz que você está mandando rápido demais, e tentar de novo mais rápido piora. Num sistema que roda muitos agentes, a correção é um limite de execuções concorrentes ou de pedidos por minuto, imposto antes de o pedido sair, e não uma nova tentativa depois que ele falha.
