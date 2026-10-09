---
title: Quando o laço não acaba
version: 2
---

O cliente pergunta se a Marginalia vende primeiras edições autografadas de *Dom Casmurro*. A central de ajuda não tem nada que responda. Eis o `llama3.2:3b`:

```
ana@lab:~/agents$ python react_native.py "Do you sell signed first editions of Dom Casmurro?"
We do sell signed first editions of Dom Casmurro. If you're interested in purchasing one, please provide the title and quantity you'd like to buy, and I'll be happy to assist you with the ordering process.
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=267
  said:     
  called:   search_help({"query": "signed first editions Dom Casmurro"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=end_turn  input_tokens=317
  said:     We do sell signed first editions of Dom Casmurro. If you're interested in purchasing one, please
```

**Ele não entrou em laço. Fez algo pior.** Uma busca, três artigos sobre outros assuntos (pedidos de escolas, entre eles), e depois um sim confiante. Nada do que voltou diz que a Marginalia vende exemplares autografados; os artigos que voltaram dizem que exemplares autografados não podem ser devolvidos, o que é outro assunto. O rastro mostra a lacuna em duas linhas: `returned` não traz nada sobre primeiras edições, e `said` promete uma.

Essa falha é de novo a da aula 1, uma resposta que o modelo inventou depois de uma ferramenta, e a guarda do `react_native.py` nem chegou a ser alcançada. Para ver a guarda funcionar, o modelo tem de se repetir, e um modelo pequeno que para depois de uma chamada não faz isso quando pedido. Então esta seção usa um **dublê**: um programa que fala a Messages API da Anthropic e responde a cada passo com uma resposta escrita de antemão. Não há modelo nenhum dentro dele. Salve-o como `~/agents/standin.py`; aulas seguintes o usam sempre que precisam que um modelo siga um caminho exato.

```python
"""standin.py REPLIES.json: a stand-in model. It answers Anthropic's Messages API with replies written in advance.

It has no model in it. REPLIES.json maps a phrase to the list of replies a
conversation gets, one per step: the first user message that contains the
phrase picks the list, and the number of assistant turns so far picks the
reply. A reply is {"text": ...}, {"tool": NAME, "input": {...}}, or a list of
those, sent as one message. Point a program at http://127.0.0.1:11436.
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPLIES = json.load(open(sys.argv[1]))


def text_of(message):
    c = message["content"]
    return c if isinstance(c, str) else " ".join(b.get("text", "") for b in c)


class StandIn(BaseHTTPRequestHandler):
    def do_POST(self):
        req = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        first = text_of(req["messages"][0])
        step = sum(1 for m in req["messages"] if m["role"] == "assistant")
        script = next((r for phrase, r in REPLIES.items() if phrase in first), None)
        if script is None or step >= len(script):
            return self.reply(400, {"type": "error", "error": {
                "type": "invalid_request_error", "message": "standin.py has no reply written for this step"}})
        planned = script[step] if isinstance(script[step], list) else [script[step]]
        content = [{"type": "text", "text": p["text"]} if "text" in p else
                   {"type": "tool_use", "id": f"toolu_{step}_{n}", "name": p["tool"], "input": p["input"]}
                   for n, p in enumerate(planned)]
        uses_tool = any(b["type"] == "tool_use" for b in content)
        self.reply(200, {"id": f"msg_standin_{step}", "type": "message", "role": "assistant",
                         "model": req["model"], "content": content,
                         "stop_reason": "tool_use" if uses_tool else "end_turn", "stop_sequence": None,
                         "usage": {"input_tokens": 0, "output_tokens": 0}})   # it counts nothing

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11436), StandIn).serve_forever()
```

As respostas são um arquivo. Este dá a qualquer conversa que mencione *signed first editions* dois passos, cada um com uma frase e uma busca, e a segunda busca é a primeira de novo: a forma de um laço comum, posta por escrito. Salve-o como `~/agents/loop.json`:

```json
{"signed first editions": [
  [{"text": "The help centre should say whether signed copies are sold."},
   {"tool": "search_help", "input": {"query": "signed copies"}}],
  [{"text": "Those articles do not mention signed copies; I will search for signed copies."},
   {"tool": "search_help", "input": {"query": "signed copies"}}]
]}
```

Suba o dublê e aponte o `react_native.py` para ele numa execução. O programa não mudou; só o endereço para onde ele manda é outro.

```
ana@lab:~/agents$ python standin.py loop.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python react_native.py "Do you sell signed first editions of Dom Casmurro?"
host: step 2 repeats search_help({"query": "signed copies"}); stopping
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=0
  said:     The help centre should say whether signed copies are sold.
  called:   search_help({"query": "signed copies"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=tool_use  input_tokens=0
  said:     Those articles do not mention signed copies; I will search for signed copies.
  called:   search_help({"query": "signed copies"})
  returned: refused: repeat
```

O passo 1 buscou `signed copies` e recebeu três artigos sobre outros assuntos. A frase do passo 2 diz isso, e então pede a mesma busca com as mesmas palavras. A guarda do `react_native.py` mantém um conjunto de chamadas já feitas, como nome da ferramenta e argumentos com chaves ordenadas; a segunda chamada já estava nele, então o hospedeiro parou a execução e escreveu por quê. **Sem a guarda, esta execução repetiria a busca até o limite de passos**, pagando por um pedido maior a cada vez. O dublê não conta tokens, e é por isso que o rastro diz 0; com um modelo de verdade, cada um desses pedidos carrega tudo o que veio antes.

## Por que modelos entram em laço

Um modelo escolhe o próximo passo a partir da conversa até ali. Se nada nela mudou, a mesma escolha é provável de novo: a busca não trouxe nada útil, então buscar continua sendo o movimento óbvio, e a consulta que parecia a melhor antes continua parecendo. Laços reais raramente são tão escancarados. Mais frequente é um modelo alternar entre duas consultas, ou ler o mesmo pedido com maiúsculas diferentes, o que uma guarda de igualdade exata deixa passar.

## O que um hospedeiro pode fazer

| falha | o que fazer no hospedeiro |
|---|---|
| a mesma chamada, mesmos argumentos | recusá-la, ou parar a execução (esta seção) |
| chamadas quase idênticas | normalizar os argumentos antes de comparar: aparar, passar para minúsculas, ordenar chaves |
| uma chamada a ferramenta que não existe | devolver um erro que nomeia as ferramentas que existem |
| nenhum progresso por vários passos | parar depois de N passos sem ferramenta nova ou resultado novo (aula 5) |
| responder antes de consultar qualquer coisa | exigir ao menos uma chamada em perguntas sobre pedidos, e conferir que a resposta cita um resultado |

Parar não é o mesmo que falhar com educação. Uma execução parada ainda deve uma resposta a alguém, e a útil aqui é honesta: *"a central de ajuda não diz; vou passar isto para uma pessoa."* A aula 5 é sobre o que um agente devolve quando um limite dispara, e é a outra metade de cada guarda desta tabela.
