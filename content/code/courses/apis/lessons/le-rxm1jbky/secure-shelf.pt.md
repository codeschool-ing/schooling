---
title: O shelf protegido
version: 1
---

Esta lição acrescenta dois arquivos a `~/shelf` e não muda nada do que já está lá. **O `secure.py` é a
API de livros com todas as defesas da lição embutidas**, e `site/page.html` é uma página web que a
chama de outra origem, que é o que torna essas defesas visíveis. O `rest.py` da lição 1 fica como
estava; você pode começar esta lição a partir do fim da lição 1.

O `secure.py` atende um tipo de endereço só, um livro em `/v1/books/<id>`, com dois métodos: GET o lê
e PATCH muda o estoque dele. É pequeno de propósito. Um GET é a requisição que o navegador manda sem
perguntar antes, e um PATCH com corpo JSON é uma sobre a qual ele precisa perguntar, então os dois
juntos mostram as duas metades do CORS. Salve-o como `~/shelf/secure.py` com o `nano`, como você
salvou o `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/secure.py",
  "parts": [
    {
      "code": "# shelf/secure.py\n\"\"\"The books API with lesson 13's defences: CORS, security headers and HTTPS.\n\n    python3 secure.py                  http://127.0.0.1:8000\n    python3 secure.py --tls            https://127.0.0.1:8443, with tls/server.crt\n    python3 secure.py --host 0.0.0.0 --origin http://192.168.64.5:8080\n\"\"\"\nimport argparse\nimport json\nimport os\nimport re\nimport ssl\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db\n\nHERE = os.path.dirname(os.path.abspath(__file__))",
      "note": "A mesma biblioteca padrão do `rest.py`, mais `ssl` para o modo HTTPS e `argparse` para as três opções da docstring. `HERE` deixa o programa achar o certificado de qualquer diretório em que for iniciado."
    },
    {
      "code": "ORIGINS = {\"http://localhost:8080\"}",
      "note": "A **lista de permissões**: as origens das páginas que podem ler as respostas desta API. É um conjunto de strings inteiras, comparadas exatamente, e `--origin` acrescenta itens quando o programa começa."
    },
    {
      "code": "SECURITY = [\n    (\"Content-Security-Policy\", \"default-src 'none'; frame-ancestors 'none'\"),\n    (\"X-Content-Type-Options\", \"nosniff\"),\n    (\"Referrer-Policy\", \"no-referrer\"),\n    (\"Cache-Control\", \"no-store\"),\n]\nHSTS = (\"Strict-Transport-Security\", \"max-age=31536000\")",
      "note": "Quatro cabeçalhos que vão em **toda** resposta, erros incluídos, e um quinto que só faz sentido sobre HTTPS. A seção sobre cabeçalhos diz o que cada um faz."
    },
    {
      "code": "\n\nclass Secure(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    tls = False\n\n    def version_string(self):\n        return \"shelf\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True",
      "note": "`version_string` é o que a biblioteca põe no cabeçalho `Server`. A API da lição 1 mandava ali a versão exata do Python; esta manda um nome e nada mais. O corpo é lido inteiro antes de qualquer resposta, como no `rest.py`."
    },
    {
      "code": "\n    def cors(self):\n        \"\"\"Vary always; Allow-Origin only for a page on the list.\"\"\"\n        headers = getattr(self, \"headers\", None)\n        origin = headers.get(\"Origin\") if headers else None\n        if origin in ORIGINS:\n            return [(\"Access-Control-Allow-Origin\", origin), (\"Vary\", \"Origin\")]\n        return [(\"Vary\", \"Origin\")]",
      "note": "A decisão de CORS, num lugar só. Uma página da lista recebe a própria origem de volta em `Access-Control-Allow-Origin`; qualquer outra origem não recebe nada. `Vary: Origin` sai nos dois casos, porque a resposta depende desse cabeçalho mesmo quando diz não."
    },
    {
      "code": "\n    def reply(self, status, value=None, extra=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in SECURITY + ([HSTS] if self.tls else []) + self.cors() + list(extra):\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, extra=()):\n        self.reply(status, {\"error\": message}, extra)",
      "note": "Toda resposta sai por `reply`, e é isso que torna \"toda resposta\" verdade: os cabeçalhos de segurança, o HSTS quando a conexão é HTTPS, os cabeçalhos de CORS e depois o que quem chamou acrescentar."
    },
    {
      "code": "\n    def send_error(self, code, message=None, explain=None):\n        \"\"\"What the library would have answered in HTML, answered in JSON.\"\"\"\n        self.close_connection = True\n        self.error(code, message or self.responses[code][0])",
      "note": "A biblioteca responde alguns erros sozinha, um método que ela não conhece ou uma linha de requisição malformada, e responde em HTML sem nenhum dos cabeçalhos acima. Sobrescrever `send_error` faz esses também passarem por `reply`."
    },
    {
      "code": "\n    def book(self):\n        m = re.fullmatch(r\"/v1/books/(\\d+)\", self.path.split(\"?\")[0])\n        return int(m.group(1)) if m else None\n\n    def do_OPTIONS(self):\n        \"\"\"The preflight: may this page send this method with these headers?\"\"\"\n        if self.book() is None:\n            return self.error(404, \"no such resource\")\n        extra = [(\"Allow\", \"GET, PATCH, OPTIONS\")]\n        if self.headers.get(\"Origin\") in ORIGINS:\n            extra += [(\"Access-Control-Allow-Methods\", \"GET, PATCH\"),\n                      (\"Access-Control-Allow-Headers\", \"Content-Type\"),\n                      (\"Access-Control-Max-Age\", \"600\")]\n        self.reply(204, None, extra)",
      "note": "O **preflight**. Qualquer cliente pode perguntar quais métodos o endereço aceita, e recebe `Allow`. Uma página da lista recebe também os métodos e cabeçalhos que pode enviar, e `Max-Age`, o número de segundos que o navegador dela pode guardar a resposta. Responde **204**, onde a API da lição 1 respondia 501."
    },
    {
      "code": "\n    def do_GET(self):\n        ident = self.book()\n        if ident is None:\n            return self.error(404, \"no such resource\")\n        with db.connect() as conn:\n            row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\", (ident,)).fetchone()\n        return self.reply(200, dict(row)) if row else self.error(404, f\"no book {ident}\")\n\n    def do_PATCH(self):\n        ident = self.book()\n        if ident is None:\n            return self.error(404, \"no such resource\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.error(415, \"send the change as application/json\")\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            return self.error(400, \"the body is not valid JSON\")\n        if (not isinstance(value, dict) or set(value) != {\"stock\"}\n                or type(value[\"stock\"]) is not int or value[\"stock\"] < 0):\n            return self.error(422, \"send {\\\"stock\\\": n}, n a whole number from 0\")\n        with db.connect() as conn:\n            conn.execute(\"UPDATE books SET stock = ? WHERE id = ?\", (value[\"stock\"], ident))\n            row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\", (ident,)).fetchone()\n        return self.reply(200, dict(row)) if row else self.error(404, f\"no book {ident}\")",
      "note": "Um livro, lido e alterado. O PATCH aceita um único campo, `stock`, e recusa todo o resto com os códigos que a lição 1 escolheu. Nada nesses dois métodos menciona CORS: a decisão foi tomada uma vez, em `cors`."
    },
    {
      "code": "\n    def refuse(self):\n        self.error(405, f\"{self.command} is not allowed here\", [(\"Allow\", \"GET, PATCH, OPTIONS\")])\n\n    do_POST = do_PUT = do_DELETE = refuse",
      "note": "POST, PUT e DELETE são métodos que a biblioteca conhece, então recebem **405** e um cabeçalho `Allow` em vez de um 501."
    },
    {
      "code": "\n\ndef main():\n    args = argparse.ArgumentParser()\n    args.add_argument(\"--host\", default=\"127.0.0.1\")\n    args.add_argument(\"--origin\", action=\"append\", default=[])\n    args.add_argument(\"--tls\", action=\"store_true\")\n    a = args.parse_args()\n    ORIGINS.update(a.origin)\n    port = 8443 if a.tls else 8000\n    server = ThreadingHTTPServer((a.host, port), Secure)",
      "note": "HTTP simples na porta 8000, a não ser que venha `--tls`. `--host` decide em que endereço o programa escuta: 127.0.0.1 por padrão, que só esta máquina alcança."
    },
    {
      "code": "    if a.tls:\n        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)\n        ctx.minimum_version = ssl.TLSVersion.TLSv1_2\n        ctx.load_cert_chain(os.path.join(HERE, \"tls/server.crt\"), os.path.join(HERE, \"tls/server.key\"))\n        server.socket = ctx.wrap_socket(server.socket, server_side=True)\n        Secure.tls = True\n    scheme = \"https\" if a.tls else \"http\"\n    print(f\"secure shelf on {scheme}://{a.host}:{port}, pages allowed: {' '.join(sorted(ORIGINS))}\",\n          flush=True)\n    server.serve_forever()\n\n\nif __name__ == \"__main__\":\n    main()",
      "note": "O modo HTTPS na porta 8443: o mesmo servidor, com o socket de escuta envolvido em TLS usando o certificado e a chave que a seção de HTTPS cria. Versões de TLS anteriores à 1.2 são recusadas."
    }
  ]
}
```

## A página

A página tem dois botões. "Read it" manda um GET, "Set the stock to 11" manda um PATCH, e cada um
imprime o que voltou, ou o erro, embaixo dos botões e no console do navegador. Ela monta o endereço
da API a partir do próprio, trocando a porta por 8000, então chama a API no host de onde foi
carregada, seja ele qual for.

```sh
mkdir ~/shelf/site
```

Salve-a como `~/shelf/site/page.html`:

```html
<!-- shelf/site/page.html -->
<!doctype html>
<meta charset="utf-8">
<title>A page on another origin</title>
<h1>Book 1, read from another origin</h1>
<button id="read">Read it</button>
<button id="sell">Set the stock to 11</button>
<pre id="out"></pre>
<script>
  const api = `${location.protocol}//${location.hostname}:8000/v1/books/1`;
  const show = (line) => {
    document.getElementById("out").textContent += line + "\n";
    console.log(line);
  };
  document.getElementById("read").onclick = async () => {
    try {
      const r = await fetch(api);
      show(`GET ${r.status} ${await r.text()}`);
    } catch (e) {
      show(`GET failed: ${e}`);
    }
  };
  document.getElementById("sell").onclick = async () => {
    try {
      const r = await fetch(api, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ stock: 11 }),
      });
      show(`PATCH ${r.status} ${await r.text()}`);
    } catch (e) {
      show(`PATCH failed: ${e}`);
    }
  };
</script>
```

**A página fica num diretório só dela porque o servidor que a publica publica tudo.** O
`python3 -m http.server` entrega todo arquivo abaixo do diretório em que começa, a quem pedir.
Iniciado em `~/shelf`, ele serviria o `shelf.db` e, ao fim da seção de HTTPS, uma chave privada.

Com os dois arquivos salvos, o projeto fica assim:

```
ana@api:~/shelf$ ls; ls site
db.py
rest.py
secure.py
site
page.html
```

## Rodando os dois

Cada servidor precisa de um terminal próprio, então esta lição usa três: o primeiro para os seus
comandos, como sempre, e mais dois para os servidores. Se o `rest.py` ainda estiver rodando de uma
lição anterior, pare-o antes com `Ctrl+C`, porque os dois programas querem a porta 8000. No segundo
terminal:

```sh
cd ~/shelf && python3 secure.py
```

Ele diz o endereço em que escuta e a única origem em que confia:

```
secure shelf on http://127.0.0.1:8000, pages allowed: http://localhost:8080
```

E no terceiro:

```sh
cd ~/shelf/site && python3 -m http.server 8080
```

A API agora está em `http://localhost:8000` e a página em `http://localhost:8080/page.html`. Mesma
máquina, mesmo nome, porta diferente: duas origens, como a seção anterior mostrou.

## Vendo no seu próprio navegador

**Quem aplica o CORS é o navegador, então o único jeito de vê-lo funcionar é num navegador.** A VM não
tem tela, e o navegador que você tem é o do seu computador. Isso cria um problema que os comandos curl
nunca tiveram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O seu computador tem um navegador e o próprio 127.0.0.1. Dentro dele, a VM tem o próprio 127.0.0.1 e um endereço numa rede privada, 192.168.64.5. O navegador só alcança a VM por esse endereço; um servidor escutando no 127.0.0.1 da VM não pode ser alcançado pelo navegador.\"><defs><marker id=\"l13-vm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">o seu computador</text><rect x=\"30\" y=\"60\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">navegador</text><rect x=\"30\" y=\"150\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"115.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o próprio computador</text><rect x=\"330\" y=\"45\" width=\"370\" height=\"180\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">a VM, api</text><rect x=\"350\" y=\"85\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.64.5</text><text x=\"430.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">endereço na rede</text><rect x=\"350\" y=\"155\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"430.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a própria VM</text><rect x=\"540\" y=\"85\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"612.5\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">secure.py</text><text x=\"612.5\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--host 0.0.0.0</text><rect x=\"540\" y=\"155\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612.5\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">secure.py</text><text x=\"612.5\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">padrão: 127.0.0.1</text><line x1=\"200\" y1=\"85\" x2=\"348\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><text x=\"262\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">http://192.168.64.5:8000</text><line x1=\"115\" y1=\"110\" x2=\"115\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><text x=\"122\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">http://127.0.0.1:8000</text><text x=\"115\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nada escuta na 8000 aqui</text><line x1=\"510\" y1=\"110\" x2=\"538\" y2=\"110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><line x1=\"510\" y1=\"180\" x2=\"538\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line></svg>", "caption": "Duas máquinas diferentes atendem por 127.0.0.1. O navegador no seu computador só alcança a VM pelo endereço dela na rede, então a API precisa escutar ali."}
```

`127.0.0.1` quer dizer "esta máquina" para quem o lê. Dentro da VM, é a VM; digitado no navegador do
seu computador, é o seu computador, onde nada escuta na 8000. **Para alcançar a VM de fora, um servidor
precisa escutar num endereço que a VM tem na rede dela**, e o `secure.py` escuta em `127.0.0.1` a não
ser que alguém diga outra coisa. O `http.server` já escuta em todos os endereços da máquina.

Descubra o endereço da VM no terminal do seu próprio computador:

```sh
multipass info api
```

A linha que interessa é a `IPv4`. Suponha que ela diga `192.168.64.5`; use o seu onde esta lição
escrever esse. Pare o `secure.py` com `Ctrl+C` e inicie de novo escutando em todos os endereços, e
confiando na página como o seu navegador vai vê-la:

```sh
python3 secure.py --host 0.0.0.0 --origin http://192.168.64.5:8080
```

Depois abra `http://192.168.64.5:8080/page.html` no navegador, abra as ferramentas de desenvolvedor
(`F12` na maioria dos navegadores, ou `Ctrl+Shift+I`; `Cmd+Option+I` no Mac) e escolha a aba Console.
**Esses três comandos não foram executados para este curso**: a máquina em que ele foi gravado não tem
endereço fora dela mesma, pelo motivo que a lição 1 explica. O que as próximas seções citam de um
navegador foi gravado com o Chromium no computador de gravação, alcançando o `localhost` da máquina do
laboratório.

`0.0.0.0` quer dizer todos os endereços, e é tão amplo quanto parece. O Multipass põe a VM numa rede
que só o seu computador alcança, e é isso que torna seguro fazer isso aqui. Numa máquina alugada na
internet o mesmo comando poria a API na internet, então não o rode lá.
