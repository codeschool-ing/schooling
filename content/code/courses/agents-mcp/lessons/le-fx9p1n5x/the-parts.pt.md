---
title: Do que um agente é feito
version: 2
---

Desmonte o `agent.py` e sobram cinco peças. Todo agente deste curso, e todo SDK de agente das aulas 8 a 10, são essas mesmas cinco peças com mais código em volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"As partes de um agente. Um programa hospedeiro guarda a conversa até aqui e a regra de parada. Ele manda a conversa e as definições das ferramentas ao modelo. O modelo responde com uma chamada de ferramenta ou com uma resposta. A chamada é executada pelo hospedeiro numa ferramenta, e o resultado entra na conversa. Uma resposta, ou a regra de parada, encerra o laço.\"><defs><marker id=\"l1parts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1parts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l1parts-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"380\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o programa hospedeiro</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conversa</text><text x=\"50\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda mensagem até aqui</text><rect x=\"40\" y=\"140\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">regra de parada</text><text x=\"50\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passos, tokens, tempo</text><rect x=\"220\" y=\"100\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o laço</text><text x=\"230\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">enviar, ler, executar, anexar</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">modelo</text><text x=\"530\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resposta ou chamada</text><rect x=\"520\" y=\"170\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text><text x=\"530\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, search_help</text><path d=\"M380 115 L520 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-amber)\"></path><path d=\"M520 84 L380 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-amber)\"></path><path d=\"M380 140 L520 192\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-wire)\"></path><path d=\"M520 206 L380 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-wire)\"></path><text x=\"450\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pedido</text><text x=\"450\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultado</text><path d=\"M200 88 L220 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M200 168 L220 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path></svg>", "caption": "O modelo só devolve palavras ou o pedido de uma ferramenta. Quem age é o hospedeiro.", "same": ["get_order, search_help"]}
```

- **Um modelo** que pode responder de dois jeitos: com texto, ou com um pedido estruturado que nomeia uma ferramenta e seus argumentos. A aula 4 é sobre o segundo.
- **Ferramentas**: funções que o programa aceita executar, cada uma descrita ao modelo por um nome, uma frase e um esquema. No `agent.py` elas são `get_order` e `search_help`, e o código delas é o `shop.py`, que o modelo nunca vê.
- **A conversa**: a lista `messages`, que começa com a mensagem do usuário e ganha uma resposta do modelo e um lote de resultados de ferramenta a cada passo. **Ela é o estado inteiro do agente.** Nada fica guardado em outro lugar.
- **O laço**: mandar, ler, executar, anexar, de novo.
- **Uma regra de parada**: o modelo responder, ou o limite do próprio programa, o que vier primeiro. O `agent.py` tem as duas, e o limite é de cinco passos.

## O modelo nunca age

A imagem a descartar é a de um modelo metendo a mão num banco de dados. Na execução para a Bia, o `llama3.2:3b` devolveu um bloco que dizia, na prática, *"chame get_order com order_id M-1042"*. O `agent.py` leu esse bloco, procurou `get_order` no `RUN`, chamou `shop.get_order("M-1042")` na máquina da ana e pôs o resultado na conversa. **O modelo pediu; o hospedeiro agiu.** Toda permissão que um agente tem é, portanto, uma permissão que o hospedeiro concede, e é por isso que a aula 17 é sobre o hospedeiro e não sobre o modelo.

## A conversa viaja inteira

Uma API de modelo não guarda nada entre pedidos. Então cada passo manda tudo de novo: o prompt de sistema, as definições das ferramentas, a mensagem da Bia, cada chamada anterior e cada resultado anterior. Para ver isso, ponha um gravador entre o programa e o Ollama. Este escuta na porta 11435, repassa cada pedido para a 11434 sem mexer nele e o anota. Salve-o como `~/agents/recorder.py`; as aulas seguintes o usam sempre que perguntam o que um programa de fato mandou.

```python
"""recorder.py: stands between your programs and Ollama, and writes down every request.

Point a program at http://127.0.0.1:11435 instead of 11434 and it works as
before, while each request lands in requests.jsonl as one JSON line: the path,
the body the program sent, the status, how long the reply took, and the tokens
the reply says it used. A line is written when the reply is complete, so a
request the program gave up on still appears, marked client_left.
"""
import http.client
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = "requests.jsonl"


def usage_in(raw):
    """Tokens from a JSON reply, or from a stream's events: in (all of the prompt), of those cached, and out."""
    found = {}
    for line in raw.decode(errors="replace").splitlines():
        line = line.removeprefix("data:").strip()
        if not line.startswith("{"):
            continue
        event = json.loads(line)
        u = event.get("usage") or (event.get("message") or {}).get("usage")
        if not u:
            continue
        if "prompt_tokens" in u:   # OpenAI's shape: the cached tokens are part of prompt_tokens
            cached = (u.get("prompt_tokens_details") or {}).get("cached_tokens") or 0
            found.update(input_tokens=u["prompt_tokens"], cached_tokens=cached, output_tokens=u["completion_tokens"])
        else:                      # Anthropic's shape: input_tokens leaves the cached ones out
            if "input_tokens" in u:   # a stream's last event may carry the output count alone
                cached = u.get("cache_read_input_tokens") or 0
                found.update(input_tokens=u["input_tokens"] + cached, cached_tokens=cached)
            found["output_tokens"] = u.get("output_tokens", found.get("output_tokens"))
    return found


class Recorder(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        started = time.monotonic()
        upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
        upstream.request(self.command, self.path, body, {"Content-Type": "application/json"})
        reply = upstream.getresponse()
        self.send_response(reply.status)
        self.send_header("Content-Type", reply.getheader("Content-Type", "application/json"))
        self.send_header("Connection", "close")
        self.end_headers()
        raw, client_left = b"", False
        while chunk := reply.read1(65536):
            raw += chunk
            if not client_left:
                try:
                    self.wfile.write(chunk)
                    self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    client_left = True   # the program gave up on this request; it was still sent
        record = {"path": self.path, "request": json.loads(body or b"{}"), "status": reply.status,
                  "ms": round(1000 * (time.monotonic() - started)), "usage": usage_in(raw)}
        if client_left:
            record["client_left"] = True
        with open(LOG, "a") as log:
            log.write(json.dumps(record) + "\n")

    do_GET = do_POST

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11435), Recorder).serve_forever()
```

Inicie-o em segundo plano e rode de novo a pergunta da Bia com o `ANTHROPIC_BASE_URL` apontado para o gravador só nesse comando:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] answer: Hi Bia, 

Unfortunately, since your order M-1042 was delivered on September 24th, you will not be able to return it. Our return policy typically applies to orders that have not been shipped or are still in the processing stage. 

However, I recommend contacting our customer service team to see if there are any exceptions or alternatives we can offer. We're here to help and would like to ensure you're satisfied with your purchase.
ana@lab:~/agents$ python -c 'import json; [print(n, r["usage"]["input_tokens"], r["usage"]["cached_tokens"], r["usage"]["output_tokens"], r["ms"]) for n, r in enumerate(map(json.loads, open("requests.jsonl")), 1)]'
1 270 239 18 2451
2 239 238 92 9552
```

As colunas são o número do pedido, os tokens de entrada, quantos deles o Ollama já tinha em cache de um pedido anterior, os tokens de saída e os milissegundos que levou. O segundo pedido levava tudo o que o primeiro levava mais a chamada do modelo e o pedido que ela trouxe, então devia ser o maior dos dois. **Ele é menor: 239 tokens contra 270.** Alguma coisa que o programa mandou não chegou ao modelo.

O modelo nunca lê JSON. O Ollama transforma cada pedido num texto comprido no formato em que o modelo foi treinado, usando um template que vem com o modelo, e é o template que decide o que entra:

```
ana@lab:~/agents$ ollama show llama3.2:3b --template | grep -n Tools
7:{{- if .Tools }}When you receive a tool call response, use the output to format an answer to the orginal user question.
14:{{- if and $.Tools $last }}
20:{{ range $.Tools }}
```

A linha 14 é a história inteira. As descrições das ferramentas só são escritas na conversa **dentro da última mensagem, quando ela é do usuário**. No primeiro pedido era a da Bia, então o modelo viu as duas ferramentas e pediu uma. No segundo, a última mensagem era um resultado de ferramenta, então as ferramentas ficaram de fora, e um modelo que não enxerga uma ferramenta não consegue pedi-la. É por isso que o agente da Bia fez uma chamada e depois teve de responder com o que tinha, e isso vai acontecer com todo agente deste curso que roda no `llama3.2:3b`: **uma chamada de ferramenta por vez que o usuário fala, e nunca duas seguidas.**

Saem daí duas lições, e nenhuma é sobre este modelo. Um modelo só sabe o que o pedido carrega depois que o fornecedor o transformou em texto, então "eu mandei as ferramentas" e "o modelo viu as ferramentas" são afirmações diferentes, e só uma medida como a de cima as separa. E o template faz parte do modelo que você escolheu: o modelo de uma API paga, ou um local maior, dá vários passos sem pestanejar, e este não consegue. Onde uma aula precisa que um agente dê vários passos seguidos para mostrar um mecanismo, ela usa um modelo dublê cujas respostas estão escritas na própria aula, e diz isso onde acontece.

Nem o assistente nem o agente é mais barato como regra: o assistente levou a central de ajuda inteira num pedido, e o agente leva um pouco mais a cada passo. A aula 18 mede quando cada um ganha, e começa desse crescimento.
