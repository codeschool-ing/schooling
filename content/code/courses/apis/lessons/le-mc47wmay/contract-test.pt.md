---
title: Um teste de contrato
version: 1
---

**Um teste de contrato manda requisições reais para a API em execução e confronta cada resposta com
o documento.** Se o código de status não é um dos que a operação lista, se falta um cabeçalho
obrigatório, se o corpo não cabe no schema, o teste falha e diz qual. É isso que transforma o
`openapi.yaml` de descrição em documentação viva: no dia em que o `rest.py` e o documento discordam,
um programa avisa.

Para cada requisição ele faz cinco perguntas, uma antes de enviar e quatro depois:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"O que o check_contract.py faz em cada requisição, em ordem. Um: se há corpo, conferi-lo contra o schema de requestBody, e esperar uma recusa se a especificação o recusa. Dois: enviar ao rest.py. Três: procurar o código de status nas responses da operação. Quatro: conferir os cabeçalhos obrigatórios. Cinco: conferir o Content-Type contra content. Seis: validar o corpo contra o schema. Qualquer passo que não se cumpre acrescenta uma linha sob um FAIL daquela requisição.\"><defs><marker id=\"l06-seq-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  o corpo</text><text x=\"65.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">requestBody</text><rect x=\"128\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"179.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  enviar</text><text x=\"179.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rest.py</text><line x1=\"116\" y1=\"65\" x2=\"127\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"242\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  o status</text><text x=\"293.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">responses</text><line x1=\"230\" y1=\"65\" x2=\"241\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"356\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"407.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  cabeçalhos</text><text x=\"407.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">required</text><line x1=\"344\" y1=\"65\" x2=\"355\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"470\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"521.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  tipo de mídia</text><text x=\"521.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">content</text><line x1=\"458\" y1=\"65\" x2=\"469\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"584\" y=\"40\" width=\"102\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6  o corpo</text><text x=\"635.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">schema</text><line x1=\"572\" y1=\"65\" x2=\"583\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l06-seq-ah)\"></line><text x=\"14\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes da requisição</text><text x=\"242\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois da resposta, contra a operação a que ela pertence</text><line x1=\"65\" y1=\"90\" x2=\"65\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"293\" y1=\"90\" x2=\"293\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"407\" y1=\"90\" x2=\"407\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"521\" y1=\"90\" x2=\"521\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><line x1=\"635\" y1=\"90\" x2=\"635\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-seq-ah)\"></line><rect x=\"14\" y=\"142\" width=\"672\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">FAIL, e uma linha dizendo qual passo não se cumpriu</text><text x=\"14\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o servidor aceitou o que a especificação recusa</text><text x=\"686\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o servidor respondeu o que a especificação não descreve</text></svg>", "caption": "Uma requisição, cinco perguntas. A primeira é sobre o que foi enviado, e as outras quatro sobre o que voltou."}
```

A primeira pergunta é a fácil de esquecer. Conferir só o que volta nunca perceberia um servidor que
aceita o que o documento proíbe, e é aí que está a mais séria das duas discordâncias do shelf.

## O teste

Salve-o como `check_contract.py` ao lado dos outros. Ele precisa do `python3-yaml` e do
`python3-jsonschema`, os dois da lição 1, e de nada da venv.

```schooling-example
{
  "language": "python",
  "file": "shelf/check_contract.py",
  "parts": [
    {
      "code": "# shelf/check_contract.py\n\"\"\"Call the running rest.py and check every answer against openapi.yaml.\n\nStart the server first, then run `python3 check_contract.py`. It exits with 1\nwhen the API and its description disagree anywhere.\n\"\"\"\nimport json\nimport os\nimport re\nimport sys\nimport urllib.error\nimport urllib.request\n\nimport jsonschema\nimport yaml",
      "note": "Dois pacotes da linha de `apt-get` da lição 1, `python3-yaml` e `python3-jsonschema`, e a biblioteca padrão para o resto. O teste roda com o `python3` do Ubuntu e não precisa de nada da venv."
    },
    {
      "code": "\nHERE = os.path.dirname(os.path.abspath(__file__))\nwith open(os.path.join(HERE, \"openapi.yaml\"), encoding=\"utf-8\") as f:\n    SPEC = yaml.safe_load(f)\nBASE = SPEC[\"servers\"][0][\"url\"]\nNEW = {\"isbn\": \"9786500000085\", \"title\": \"Esaú e Jacó\", \"author_id\": 1,\n       \"year\": 1904, \"price_cents\": 3790}\nfailures = 0",
      "note": "O endereço vem do próprio `servers` da especificação, então o teste chama o que o documento diz que a API é. `NEW` é um livro que o db.py não tem, e que o teste cria e apaga de novo."
    },
    {
      "code": "\n\ndef deref(node):\n    \"\"\"Follow a $ref such as #/components/responses/NotFound to its object.\"\"\"\n    while \"$ref\" in node:\n        target = SPEC\n        for key in node[\"$ref\"].removeprefix(\"#/\").split(\"/\"):\n            target = target[key]\n        node = target\n    return node",
      "note": "Um `$ref` como `#/components/responses/NotFound` é um caminho dentro do documento, uma chave por segmento."
    },
    {
      "code": "\n\ndef problems(value, schema):\n    \"\"\"What is wrong with value under schema, as sentences; [] if nothing.\"\"\"\n    whole = dict(schema, components=SPEC[\"components\"])\n    return [e.message for e in jsonschema.Draft202012Validator(whole).iter_errors(value)]",
      "note": "Os schemas apontam uns para os outros com `$ref`, e essas referências partem da raiz de um documento. Copiar `components` para dentro do schema conferido dá a elas uma raiz onde `#/components/schemas/Book` existe."
    },
    {
      "code": "\n\ndef operation(method, path):\n    \"\"\"The spec's path template for a real path, and its operation for method.\"\"\"\n    bare = path.split(\"?\")[0]\n    for template, item in SPEC[\"paths\"].items():\n        if re.fullmatch(re.sub(r\"\\{\\w+\\}\", \"[^/]+\", template), bare):\n            return template, item.get(method.lower())\n    return path, None",
      "note": "A que modelo um caminho real pertence: `{id}` vira \"qualquer coisa até a próxima barra\", e a query string fica de fora."
    },
    {
      "code": "\n\ndef send(method, path, body):\n    data = None if body is None else json.dumps(body).encode()\n    request = urllib.request.Request(BASE + path, data=data, method=method)\n    if data is not None:\n        request.add_header(\"Content-Type\", \"application/json\")\n    try:\n        with urllib.request.urlopen(request) as answer:\n            return answer.status, answer.headers, answer.read()\n    except urllib.error.HTTPError as answer:\n        return answer.code, answer.headers, answer.read()",
      "note": "Uma requisição com o cliente do próprio Python. O `urlopen` levanta uma exceção para qualquer 4xx ou 5xx, e a exceção traz o status, os cabeçalhos e o corpo como uma resposta normal, que é tudo o que um teste de contrato quer dela."
    },
    {
      "code": "\n\ndef check(method, path, body=None):\n    \"\"\"Send one request, compare the answer with the spec, print a verdict.\"\"\"\n    global failures\n    template, op = operation(method, path)\n    status, headers, raw = send(method, path, body)\n    kind = headers.get(\"Content-Type\", \"\")\n    wrong = []\n    if op is None:\n        wrong.append(f\"the spec has no {method} {template}; the answer was {kind or 'empty'}\")\n    else:\n        if body is not None:\n            schema = op[\"requestBody\"][\"content\"][\"application/json\"][\"schema\"]\n            refused = problems(body, schema)\n            if refused and status < 400:\n                wrong.append(\"accepted a body the spec refuses: \" + refused[0])",
      "note": "A conferência tem dois sentidos. Primeiro a requisição: um corpo que a especificação recusa deveria ser recusado também pelo servidor, e uma resposta abaixo de 400 quer dizer que não foi."
    },
    {
      "code": "        documented = op[\"responses\"].get(str(status))\n        if documented is None:\n            wrong.append(f\"{status} is not an answer the spec lists\")\n        else:\n            documented = deref(documented)\n            for name, header in documented.get(\"headers\", {}).items():\n                if header.get(\"required\") and name not in headers:\n                    wrong.append(f\"no {name} header\")\n            content = documented.get(\"content\")\n            if content is None:\n                if raw:\n                    wrong.append(\"a body, where the spec says there is none\")\n            elif kind not in content:\n                wrong.append(f\"{kind or 'no body'}, where the spec says {', '.join(content)}\")\n            else:\n                for problem in problems(json.loads(raw), content[kind][\"schema\"]):\n                    wrong.append(\"the answer: \" + problem)\n    print(f\"{'FAIL' if wrong else 'ok':4}  {method} {path} -> {status}\")\n    for line in wrong:\n        print(f\"      {line}\")\n    failures += bool(wrong)\n    return status, headers",
      "note": "Depois a resposta: o código de status está na lista, os cabeçalhos obrigatórios estão lá, o `Content-Type` é um dos que a especificação nomeia, e o corpo cabe no schema? Um status que o documento nunca menciona é uma falha mesmo quando o corpo parece certo."
    },
    {
      "code": "\n\ncheck(\"GET\", \"/books\")\ncheck(\"GET\", \"/books?author_id=3\")\ncheck(\"GET\", \"/books/1\")\ncheck(\"GET\", \"/books/99\")\ncheck(\"GET\", \"/authors/2\")\ncheck(\"GET\", \"/authors/2/books\")",
      "note": "Seis leituras, entre elas um livro que existe e um que não existe."
    },
    {
      "code": "status, headers = check(\"POST\", \"/books\", NEW)\nif status != 201:\n    sys.exit(\"could not create the test book; is shelf.db as db.py made it?\")\nmade = headers[\"Location\"].rsplit(\"/\", 1)[1]\ncheck(\"POST\", \"/books\", NEW)\ncheck(\"PATCH\", f\"/books/{made}\", {\"stock\": 4})\ncheck(\"PUT\", f\"/books/{made}\", {\"stock\": 4})",
      "note": "As escritas, num livro do próprio teste, para que nenhum dos seis do db.py seja tocado: criar, criar de novo, mudar, e substituir com um corpo a que falta a maior parte dos campos."
    },
    {
      "code": "status, headers = check(\"POST\", \"/books\", dict(NEW, isbn=\"978-65-00000-08-5\"))\nif status == 201:\n    check(\"DELETE\", headers[\"Location\"].removeprefix(\"/v1\"))\ncheck(\"DELETE\", f\"/books/{made}\")\ncheck(\"DELETE\", f\"/books/{made}\")\ncheck(\"OPTIONS\", \"/books\")",
      "note": "O mesmo livro com o ISBN escrito do jeito que vem impresso, com hífens, depois a limpeza, e um método que a especificação não descreve."
    },
    {
      "code": "\nprint(f\"{failures} disagreement{'' if failures == 1 else 's'}\")\nsys.exit(1 if failures else 0)",
      "note": "O código de saída é o veredito, então um script ou um job de CI pode rodar o teste e parar numa discordância sem ler uma linha dele."
    }
  ]
}
```

## Rodando

O servidor precisa estar rodando no segundo terminal, como na lição 1: `cd ~/shelf && python3
rest.py`. Depois, no primeiro:

```
ana@api:~/shelf$ python3 check_contract.py; echo "exit $?"
ok    GET /books -> 200
ok    GET /books?author_id=3 -> 200
ok    GET /books/1 -> 200
ok    GET /books/99 -> 404
ok    GET /authors/2 -> 200
ok    GET /authors/2/books -> 200
ok    POST /books -> 201
ok    POST /books -> 409
ok    PATCH /books/7 -> 200
ok    PUT /books/7 -> 422
FAIL  POST /books -> 201
      accepted a body the spec refuses: '978-65-00000-08-5' does not match '^[0-9]{13}$'
      the answer: '978-65-00000-08-5' does not match '^[0-9]{13}$'
ok    DELETE /books/8 -> 204
ok    DELETE /books/7 -> 204
ok    DELETE /books/7 -> 404
FAIL  OPTIONS /books -> 501
      the spec has no OPTIONS /books; the answer was text/html;charset=utf-8
2 disagreements
exit 1
```

Treze requisições concordaram com o documento e duas não, e o código de saída 1 diz isso a qualquer
coisa que rode o teste. Os seus ids podem ser diferentes de `7` e `8` se o seu shelf ganhou livros
depois da lição 1; os vereditos não. O teste também deixou a loja como a encontrou:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books | jq length
6
```

## A primeira discordância: uma regra que o servidor não cumpre

O documento diz que um ISBN tem treze dígitos. O teste mandou `978-65-00000-08-5`, que é o mesmo
livro que `9786500000085` escrito do jeito que os ISBNs vêm impressos, e o `rest.py` respondeu 201.
Duas linhas explicam a falha. A primeira diz que o servidor aceitou um corpo que o documento recusa.
A que começa com `the answer:` diz que o livro que ele devolveu também desrespeita o documento,
porque o schema `Book` tem o mesmo pattern.

**E a consequência é pior que um formato.** Olhe a ordem das requisições. A cópia com hífens foi
criada como livro 8 enquanto o livro 7, o mesmo livro com o ISBN sem hífens, ainda existia. O 409 que
o documento promete para um segundo livro com o mesmo ISBN nunca veio, porque o `UNIQUE` do banco
compara strings, e as duas strings são diferentes. Com a regra do documento aplicada, a segunda cópia
teria sido recusada na porta.

Qual lado está errado é uma decisão, não um fato que o teste possa saber. Aqui é o código: o
documento enuncia a regra da loja e o `rest.py` esqueceu de conferi-la. Num projeto de verdade você
corrigiria no mesmo dia, acrescentando o pattern às conferências por que toda escrita já passa, e
aquela linha do teste viraria `ok`. O `rest.py` do shelf fica como está, porque toda lição deste
curso se apoia nele; a linha que falha fica como uma discordância conhecida pelo resto do curso.

## A segunda: uma resposta que ninguém descreveu

`OPTIONS /books` recebeu o 501 e a página HTML da lição 1. O documento não tem operação `options`,
então o teste aponta o método como não descrito e nomeia o tipo de mídia que voltou, `text/html`,
numa API que responde JSON em todo o resto. Esta discordância vai no outro sentido: o documento fica
calado e o servidor responde mesmo assim. Ou o servidor deveria responder `OPTIONS` direito, assunto
a que a lição 13 volta por causa dos navegadores, ou o documento deveria descrever o que ele faz.

## O que ele não consegue ver

**Um teste de contrato confere as requisições que envia, e nenhuma outra.** Este envia quinze. Ele
nunca pede `/v1/books?author_id=abc`, embora o documento diga que `author_id` é um inteiro:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' 'localhost:8000/v1/books?author_id=abc'
[]
200
```

O `rest.py` aceitou o texto, não achou autor com esse id e respondeu 200 com uma lista vazia. Um
cliente que mandou um nome onde vai um id fica sabendo que não há livros, em vez de saber que pediu
errado. Nada na execução acima conseguiria ver isso.

Escrever mais requisições à mão ajuda, e a outra abordagem também: ferramentas que leem o documento e
geram as requisições elas mesmas, muitas, apontadas para cada borda que os schemas descrevem. O
Schemathesis é uma, e o Dredd outra; nenhuma é rodada neste curso. Elas acham mais do que uma lista
feita à mão, e acham contra o mesmo documento, que é o que importa. O documento é o único lugar onde o
contrato está enunciado, e toda conferência, à mão ou gerada, é uma conferência contra ele.
