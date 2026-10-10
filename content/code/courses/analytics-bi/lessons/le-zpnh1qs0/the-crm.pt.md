---
title: Um CRM para onde mandar
version: 1
---

Um reverse ETL de verdade manda para o Salesforce, o HubSpot ou um help desk, pela API de cada um, com
conta e contrato. Para montar o trabalho sem nada disso, você precisa de algo que se comporte como a API
de um CRM e rode na sua máquina. Aqui está um, pequeno o bastante para ler. Não é preciso saber Python
para usá-lo: copie com o botão do código e salve como `~/reverse/crm.py`.

```schooling-example
{"language": "python", "file": "crm.py", "parts": [{"code": "# crm.py: a pretend CRM, so the sync has somewhere to send contacts.\nimport json, time\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom urllib.parse import urlparse, parse_qs\n\nHEALTH = {\"active\", \"at risk\", \"lapsed\"}\nLIMIT = 10                      # requests per second before it refuses\ncontacts, seen, stats = [], [], {\"requests\": 0, \"refused\": 0}", "note": "Ele só usa a biblioteca padrão do Python, então roda com o `python3` que o Ubuntu já tem. `HEALTH` é a lista de opções do CRM: os únicos valores que o campo de saúde aceita. `LIMIT` é quantas requisições por segundo ele permite, como a API de todo CRM real."}, {"code": "class CRM(BaseHTTPRequestHandler):\n    def reply(self, code, body, extra=None):\n        data = json.dumps(body).encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"application/json\")\n        for k, v in (extra or {}).items():\n            self.send_header(k, v)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "Toda resposta é JSON com um código de status, do jeito que uma API real responde."}, {"code": "    def busy(self):\n        now = time.time()\n        seen[:] = [t for t in seen if now - t < 1] + [now]\n        stats[\"requests\"] += 1\n        if len(seen) > LIMIT:\n            stats[\"refused\"] += 1\n            self.reply(429, {\"error\": \"too many requests\"}, {\"Retry-After\": \"1\"})\n            return True\n        return False", "note": "Uma requisição além de `LIMIT` no último segundo é recusada com `429` e um cabeçalho `Retry-After` dizendo quanto esperar. APIs reais fazem isso para se proteger, e uma sincronização precisa respeitar."}, {"code": "    def body(self):\n        return json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n\n    def do_GET(self):\n        url = urlparse(self.path)\n        if url.path == \"/stats\":\n            return self.reply(200, dict(stats, contacts=len(contacts)))\n        wanted = parse_qs(url.query).get(\"external_id\", [None])[0]\n        self.reply(200, [c for c in contacts if wanted in (None, c[\"external_id\"])])", "note": "`GET /contacts?external_id=…` lista os registros com essa chave, e `/stats` diz quantos contatos ele guarda e quantas requisições recusou."}, {"code": "    def do_POST(self):\n        if self.busy():\n            return\n        contact = self.body()\n        contacts.append(dict(contact, crm_id=len(contacts) + 1))\n        self.reply(201, {\"status\": \"created\", \"crm_id\": len(contacts)})", "note": "`POST /contacts` sempre cria um registro novo, seja o que for que vier nele. É o que a maioria dos CRMs faz com POST, e esta aula mostra o que isso faz com uma sincronização."}, {"code": "    def do_PUT(self):\n        if self.busy():\n            return\n        external_id, contact = self.path.rsplit(\"/\", 1)[1], self.body()\n        if contact.get(\"health\") not in HEALTH:\n            return self.reply(400, {\"error\": \"health must be one of \" + \", \".join(sorted(HEALTH))})\n        for c in contacts:\n            if c[\"external_id\"] == external_id:\n                c.update(contact)\n                return self.reply(200, {\"status\": \"updated\"})\n        contacts.append(dict(contact, external_id=external_id, crm_id=len(contacts) + 1))\n        self.reply(201, {\"status\": \"created\"})", "note": "`PUT /contacts/<id>` é um upsert pela chave externa: atualiza o registro se ele existir, cria se não existir. Uma saúde fora da lista é recusada com `400`."}, {"code": "    def do_DELETE(self):\n        if self.busy():\n            return\n        external_id = self.path.rsplit(\"/\", 1)[1]\n        before = len(contacts)\n        contacts[:] = [c for c in contacts if c[\"external_id\"] != external_id]\n        self.reply(200 if len(contacts) < before else 404, {\"status\": \"deleted\" if len(contacts) < before else \"not found\"})\n\n    def log_message(self, *args):\n        pass                    # quiet: the sync prints what matters", "note": "`DELETE /contacts/<id>` remove os registros com essa chave. As duas últimas linhas calam o log de requisições do próprio servidor."}, {"code": "HTTPServer((\"127.0.0.1\", 8000), CRM).serve_forever()", "note": "Ele escuta na porta 8000, só dentro da máquina, e guarda tudo na memória: pare-o e o CRM fica vazio de novo."}]}
```

Ele se comporta como as APIs que substitui nas três coisas com que uma sincronização precisa lidar:
identifica um contato por uma chave que você escolhe, recusa valores que os campos não permitem e recusa
requisições que chegam rápido demais. Difere numa coisa que importa só para esta aula: esquece tudo
quando é parado, então começar de novo é começar com um CRM novo.

Abra um **segundo terminal**, conecte-se de novo à máquina com `ssh` e suba-o ali:

```sh
cd ~/reverse
python3 crm.py
```

Ele não imprime nada e fica rodando até o Ctrl+C. De volta ao primeiro terminal, pergunte como ele está:

```
ana@vm:~/reverse$ curl -s -w '\n' localhost:8000/stats
{"requests": 0, "refused": 0, "contacts": 0}
```

Um CRM vazio, nenhuma requisição ainda. Deixe-o rodando pelo resto da aula.
