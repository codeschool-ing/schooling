---
title: O que o assistente vê
version: 2
---

Um assistente no editor parece ler o seu projeto. **Ele lê o que o editor manda**, e o editor
decide isso no instante antes de cada requisição. Ele manda parte do arquivo em que você está,
parte dos outros arquivos que parecem relacionados, e o arquivo de instruções do projeto se houver
um, tudo cortado para caber num orçamento. A aula 1 seção 10 disse que o modelo só sabe o que está
na requisição; esta seção é sobre quem preenche a requisição, e como.

## Um assistente pequeno o bastante para ler

Os assistentes de verdade não publicam as regras exatas, e as mudam com frequência. Então esta aula
usa um escrito para o curso, o `assist`, que segue os mesmos três passos que os de verdade
descrevem na documentação e, ao contrário deles, imprime o que mandou. Salve-o como
`~/shop/scratch/assist.py`:

```schooling-example
{
  "language": "python",
  "file": "scratch/assist.py",
  "parts": [
    {
      "code": "\"\"\"assist: an editor assistant small enough to read, written for this course.\n\nThe assistants built into editors do three things before a model sees anything:\nthey decide which text to send (the file around the cursor, other files that look\nrelated, the project's instruction file), they leave out what they were told to\nleave out, and they fit the rest into a token budget. This does the same three\nthings against your local models, prints what it sent, and keeps the whole\nrequest in scratch/sent.json and the reply in scratch/reply.txt, which the real\nones do not show you. It is not a\ncopy of any of them: their exact rules are their own and mostly unpublished.\n\n    python scratch/assist.py complete FILE:LINE [--open FILE ...] [--accept]\n    python scratch/assist.py ask \"QUESTION\" [--open FILE ...] [--write FILE]\n\nCompletion uses a small code model trained to fill a gap between the text before\nthe cursor and the text after it; questions go to the chat model. Rules:\nAGENTS.md, if present, goes first. Paths matching a line of .assistignore are\nnever read. A file holding something shaped like a secret is refused rather than\nsent. The budget is 3,000 tokens of context. --accept puts the suggestion into\nthe file at the cursor, as pressing Tab would; --write puts the first block of\ncode in the reply into FILE, as a chat panel's Apply button would.\n\"\"\"\n",
      "note": "**O que ela é e como chamá-la.** É uma ferramenta de curso, não um produto: umas cento e cinquenta linhas que fazem o que os assistentes de editor descrevem na documentação deles, para que cada passo possa ser lido."
    },
    {
      "code": "import argparse\nimport fnmatch\nimport json\nimport os\nimport re\nimport sys\nimport urllib.request\n\nimport anthropic\nimport tiktoken\n\nENC = tiktoken.get_encoding(\"o200k_base\")\nBUDGET = 3000\nSECRET = re.compile(r\"(?i)(token|secret|password|api_key)\\s*[=:]\\s*\\S{8,}\")\nCHAT, CODE = \"llama3.2:3b\", \"qwen2.5-coder:1.5b\"\n\n\n",
      "note": "**Os ajustes da ferramenta inteira**: um orçamento de 3.000 tokens, contado com o `tiktoken` porque é rápido e próximo o bastante para um orçamento, um padrão para coisas com cara de segredo, e os dois modelos. `CHAT` responde perguntas; `CODE` preenche lacunas."
    },
    {
      "code": "def ignored(path):\n    try:\n        patterns = [p.strip() for p in open(\".assistignore\") if p.strip() and not p.startswith(\"#\")]\n    except FileNotFoundError:\n        return False\n    return any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(os.path.basename(path), p) for p in patterns)\n\n\ndef gather(paths, used):\n    \"\"\"The other files, in order, each whole or not at all, within what is left of the budget.\"\"\"\n    parts, notes = [], []\n    for p in paths:\n        if ignored(p):\n            notes.append(f\"skipped {p}: listed in .assistignore\")\n            continue\n        text = open(p).read()\n        if SECRET.search(text):\n            notes.append(f\"refused {p}: it holds something shaped like a secret\")\n            continue\n        n = len(ENC.encode(text))\n        if used + n > BUDGET:\n            notes.append(f\"dropped {p}: {n} tokens would pass the budget\")\n            continue\n        parts.append((p, text, n))\n        used += n\n    return parts, used, notes\n\n\n",
      "note": "**Os dois filtros e o orçamento.** Um caminho do `.assistignore` nunca é aberto; um arquivo cujo texto bate com o padrão de segredo é recusado inteiro; o resto entra, na ordem em que foi aberto, até o orçamento acabar, e um arquivo que não cabe sai inteiro em vez de ser cortado."
    },
    {
      "code": "def as_comment(name, text):\n    \"\"\"Another file, for a code model: commented out, so it reads as context and not as code.\"\"\"\n    return \"\".join(f\"# {line}\\n\".replace(\"# \\n\", \"#\\n\") for line in [f\"Path: {name}\"] + text.split(\"\\n\"))\n\n\n",
      "note": "**Como um modelo de código recebe outros arquivos**: como comentários no topo do arquivo que ele está completando. Um modelo de completação continua código, então um texto que ele deve ler e não imitar precisa parecer algo que código pode conter."
    },
    {
      "code": "def report(sections, used, notes):\n    print(f\"context sent ({used} of {BUDGET} tokens):\", file=sys.stderr)\n    for name, _, n in sections:\n        print(f\"  {n:5}  {name}\", file=sys.stderr)\n    for note in notes:\n        print(f\"  {note}\", file=sys.stderr)\n    print(\"---\", file=sys.stderr)\n\n\n",
      "note": "**O que ela diz e as de verdade não dizem**: cada arquivo que mandou, com o tamanho, e cada arquivo que deixou de fora, com o motivo."
    },
    {
      "code": "def complete(target, opened, accept):\n    path, line = target.rsplit(\":\", 1)\n    lines = open(path).read().split(\"\\n\")\n    k = int(line)\n    before, after = \"\\n\".join(lines[:k - 1]) + \"\\n\", \"\\n\" + \"\\n\".join(lines[k:])\n    sections, used = [], 0\n    if os.path.exists(\"AGENTS.md\"):\n        text = open(\"AGENTS.md\").read()\n        sections.append((\"AGENTS.md\", text, len(ENC.encode(text))))\n        used += sections[-1][2]\n    n = len(ENC.encode(before + after))\n    sections.append((f\"{path} (cursor at line {line})\", None, n))\n    used += n\n    others, used, notes = gather(opened, used)\n    sections += others\n    report(sections, used, notes)\n    context = \"\".join(as_comment(name, text) for name, text, _ in sections if text is not None)\n    # Stop at the first blank line, so that one suggestion is one block.\n    request = {\"model\": CODE, \"prompt\": context + before, \"suffix\": after, \"stream\": False,\n               \"options\": {\"num_predict\": 300, \"stop\": [\"\\n\\n\"]}}\n    json.dump(request, open(\"scratch/sent.json\", \"w\"), indent=1)\n    req = urllib.request.Request(\"http://127.0.0.1:11434/api/generate\", json.dumps(request).encode())\n    suggestion = json.load(urllib.request.urlopen(req))[\"response\"].rstrip(\"\\n\")\n    open(\"scratch/reply.txt\", \"w\").write(suggestion + \"\\n\")\n    print(suggestion)\n    if accept:\n        lines[k - 1:k] = suggestion.split(\"\\n\")\n        open(path, \"w\").write(\"\\n\".join(lines))\n\n\n",
      "note": "**Uma completação é uma lacuna com texto dos dois lados.** `prompt` é tudo antes do cursor, `suffix` tudo depois dele, e o `/api/generate` do Ollama põe os dois no formato de preencher-o-meio do próprio modelo de código. A requisição fica guardada em `scratch/sent.json`, e o `--accept` escreve a sugestão onde estava o cursor."
    },
    {
      "code": "def ask(question, opened, write):\n    sections, used = [], 0\n    if os.path.exists(\"AGENTS.md\"):\n        text = open(\"AGENTS.md\").read()\n        sections.append((\"AGENTS.md\", text, len(ENC.encode(text))))\n        used += sections[-1][2]\n    others, used, notes = gather(opened, used)\n    sections += others\n    report(sections, used, notes)\n    prompt = \"\".join(f\"### {name}\\n{text}\\n\" for name, text, _ in sections) + \"\\n\" + question\n    request = {\"model\": CHAT, \"max_tokens\": 1500,\n               \"system\": \"You answer questions about the files shown, briefly, as a senior colleague would.\",\n               \"messages\": [{\"role\": \"user\", \"content\": prompt}]}\n    json.dump(request, open(\"scratch/sent.json\", \"w\"), indent=1)\n    reply = anthropic.Anthropic().messages.create(**request).content[0].text\n    open(\"scratch/reply.txt\", \"w\").write(reply + \"\\n\")\n    print(reply)\n    if write:\n        block = re.search(r\"```\\w*\\n(.*?)\\n```\", reply, re.S)\n        if not block:\n            sys.exit(\"assist: the reply has no block of code to write\")\n        open(write, \"w\").write(block.group(1) + \"\\n\")\n\n\n",
      "note": "**Uma pergunta vai para o modelo de chat**, pelo SDK `anthropic` como todo outro programa deste curso, com os arquivos na mensagem. O `--write` pega o primeiro bloco de código da resposta e o escreve num arquivo."
    },
    {
      "code": "def main():\n    ap = argparse.ArgumentParser(prog=\"assist\")\n    ap.add_argument(\"mode\", choices=[\"complete\", \"ask\"])\n    ap.add_argument(\"target\")\n    ap.add_argument(\"--open\", nargs=\"*\", default=[], help=\"other files open in the editor\")\n    ap.add_argument(\"--accept\", action=\"store_true\", help=\"insert the completion at the cursor\")\n    ap.add_argument(\"--write\", metavar=\"FILE\", help=\"write the reply's first block of code to FILE\")\n    a = ap.parse_args()\n    if a.mode == \"complete\":\n        complete(a.target, a.open, a.accept)\n    else:\n        ask(a.target, a.open, a.write)\n\n\nif __name__ == \"__main__\":\n    main()\n",
      "note": "**Os dois comandos.**"
    }
  ]
}
```

**Ele usa dois modelos, porque os editores usam.** O texto fantasma que aparece enquanto você
digita vem de um modelo pequeno treinado para uma tarefa só, preencher uma lacuna no código, e ele
precisa responder em um ou dois segundos. Perguntas num painel de chat vão para um modelo geral
maior. Um modelo treinado para **preencher o meio** (*fill-in-the-middle*) recebe o texto antes do
cursor e o texto depois dele, e escreve só o que vai entre os dois. O `llama3.2:3b`, o modelo do
curso, é do segundo tipo, e o Ollama diz isso quando recebe um pedido de inserção:

```
ana@dev:~/shop$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "def add(a, b):\n", "suffix": "\n\nprint(add(1, 2))\n", "stream": false}'; echo
{"error":"registry.ollama.ai/library/llama3.2:3b does not support insert"}
```

O `qwen2.5-coder:1.5b` é um modelo do primeiro tipo, da família Qwen da Alibaba, com cerca de 1 GB:

```sh
ollama pull qwen2.5-coder:1.5b
```

Ele é usado para completar nesta aula e em nenhum outro lugar; toda pergunta continua indo para o
`llama3.2:3b`.

## Um pedido de completação

A ana começou um método em `shop/cart.py`: a assinatura e a docstring que diz para que ele serve.
O cursor está na linha vazia depois da docstring:

```
ana@dev:~/shop$ sed -n 28,34p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """
```

Ela pede uma completação com dois outros arquivos abertos no editor, do jeito que estariam nas abas
dela:

```
ana@dev:~/shop$ python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py
context sent (599 of 3000 tokens):
    332  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
        for line in self.lines:
            if line.sku == sku:
                if line.quantity > quantity:
                    line.quantity -= quantity
                    return
                elif line.quantity == quantity:
                    self.lines.remove(line)
                    return
        raise ValueError(f"no {sku} in cart")
```

As linhas acima de `---` são o que o `assist` informa sobre a própria requisição: **599 tokens de
contexto de um orçamento de 3.000**, feitos do arquivo em que ela está e das duas abas abertas.
Abaixo de `---` está a sugestão. A sua vai ser outra: isto é um sorteio como qualquer outro.

Leia-a contra a docstring. Ela acha a linha, tira as unidades, remove a linha quando chega a zero,
e recusa um sku que o carrinho não tem. Agora peça para tirar três canecas de duas: nenhum ramo
casa, o laço termina, e o erro diz `no MUG-01 in cart`, o que é falso. A recusa vem pelo motivo
errado. A aula 3 seção 04 não aceita esta sugestão; ela pede de novo, com os testes escritos antes.

## O que estava na requisição

O `assist` guardou a requisição em `scratch/sent.json`. O `~/shop/scratch/sent.py` imprime o
começo dela, o fim, e o começo do texto depois da lacuna:

```python
import json

r = json.load(open("scratch/sent.json"))
before, after = r["prompt"].split("\n"), r["suffix"].split("\n")
print("model:", r["model"], " stop:", r["options"]["stop"])
print("\n".join(before[:2] + ["(...)"] + before[-7:]))
print("<the gap the model fills>")
print("\n".join(after[:3] + ["(...)"]))
```

```
ana@dev:~/shop$ python scratch/sent.py
model: qwen2.5-coder:1.5b  stop: ['\n\n']
# Path: shop/coupons.py
# from shop.cart import Cart
(...)
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """

<the gap the model fills>

    def subtotal(self) -> int:
        return sum(line.unit_price * line.quantity for line in self.lines)
(...)
```

Três coisas para notar, porque toda ferramenta de completação tem uma versão de cada uma:

- **O cursor é uma lacuna entre dois textos.** O modelo recebe o código antes do cursor e o código
  depois dele, então consegue ver o que precisa vir em seguida além do que veio antes. É por isso
  que uma completação consegue fechar um bloco direito e parar onde o próximo método começa: o código
  abaixo do cursor também está na requisição.
- **Os outros arquivos são escolhidos pela ferramenta, não por você.** Aqui são os que a ana tinha
  abertos, e eles chegam como comentários bem no topo. Assistentes de verdade também usam arquivos
  editados há pouco e arquivos com nome parecido com o seu, e alguns fazem busca no repositório. Um
  arquivo que ninguém escolheu pode estar na requisição.
- **Um orçamento decide o que fica de fora.** 3.000 tokens aqui. Um arquivo grande, ou muitas abas
  abertas, quer dizer que algo fica de fora, e o modelo não vai dizer o que não viu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"De onde vem uma requisição de completar. O editor tem o arquivo com o cursor, as abas abertas e o arquivo de instruções. O assist deixa de fora arquivos da lista de exclusão e arquivos com algo com cara de segredo, encaixa o resto num orçamento de 3.000 tokens e manda o resultado ao modelo.\"><defs><marker id=\"cx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">no editor</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arquivo de instruções</text><rect x=\"20\" y=\"92\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o arquivo, em volta do cursor</text><rect x=\"20\" y=\"144\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abas abertas</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as regras do assistente</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lista de exclusão</text><rect x=\"270\" y=\"92\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checagem de segredos</text><rect x=\"270\" y=\"144\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">orçamento: 3.000 tokens</text><path d=\"M182 59 L266 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 111 L266 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 163 L266 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a requisição</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"142\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que o modelo vê</text><path d=\"M452 59 L516 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 111 L516 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 163 L516 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M360 196 L360 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o que ficou de fora: nada avisa</text></svg>", "caption": "O modelo vê a requisição, e a requisição é o que a ferramenta montou. Toda ferramenta de completar tem alguma versão destas três regras."}
```

**A conclusão prática é a mesma da aula 1, aplicada ao editor:** quando uma sugestão ignora uma
convenção ou chama uma função que não existe, a primeira pergunta é se o arquivo que a define
estava no contexto. Abri-lo numa aba, ou citá-lo numa pergunta no chat, muitas vezes resolve.
