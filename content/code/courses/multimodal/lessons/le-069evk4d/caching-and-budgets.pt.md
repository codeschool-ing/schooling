---
title: Nunca pagar duas vezes, e conferir antes da chamada
version: 1
---

O pedido mais barato é o que nunca é enviado. Uma loja faz as mesmas perguntas às mesmas imagens mais vezes do que espera: uma nova tentativa depois de um tempo esgotado, duas pessoas abrindo a mesma nota, um lote rodado de novo depois de uma correção em outro lugar. Um cache com chave em **tudo o que molda a resposta** responde isso do disco:

```schooling-example
{
  "language": "python",
  "file": "cached.py",
  "parts": [
    {
      "code": "\"\"\"Ask about a picture once; the second time, answer from disk. The key is everything that shapes the reply.\"\"\"\nimport base64\nimport hashlib\nimport json\nimport os\nimport sys\n\nfrom openai import OpenAI\n\n"
    },
    {
      "code": "CACHE = \"cache\"\n\n\n",
      "note": "**As respostas ficam como arquivos num diretório**, um por pergunta feita."
    },
    {
      "code": "def describe(path, prompt, model=\"lab-vision-1\", detail=\"high\"):\n    raw = open(path, \"rb\").read()\n    key = hashlib.sha256(json.dumps([hashlib.sha256(raw).hexdigest(), prompt, model, detail]).encode()).hexdigest()\n    hit = os.path.join(CACHE, key + \".json\")\n",
      "note": "**A chave é um hash de tudo o que molda a resposta**: o hash da própria imagem, o prompt, o modelo e o `detail`. Deixe um de fora e duas perguntas diferentes dividem uma resposta."
    },
    {
      "code": "    if os.path.exists(hit):\n        return json.load(open(hit)), \"cache\"\n",
      "note": "**Um acerto não custa nada**: nenhum pedido, nenhum token, nenhuma espera."
    },
    {
      "code": "    url = \"data:image/png;base64,\" + base64.b64encode(raw).decode()\n    r = OpenAI().chat.completions.create(model=model, messages=[{\"role\": \"user\", \"content\": [\n        {\"type\": \"text\", \"text\": prompt}, {\"type\": \"image_url\", \"image_url\": {\"url\": url, \"detail\": detail}}]}])\n",
      "note": "**Uma falha é o pedido da aula 8**, sem mudança."
    },
    {
      "code": "    out = {\"text\": r.choices[0].message.content, \"tokens\": r.usage.prompt_tokens}\n    os.makedirs(CACHE, exist_ok=True)\n    json.dump(out, open(hit, \"w\"))\n    return out, \"provider\"\n\n\n",
      "note": "**A resposta e os tokens que custou são gravados antes de serem devolvidos**, para a próxima pergunta idêntica ser um acerto."
    },
    {
      "code": "for prompt in sys.argv[2:]:\n    out, source = describe(sys.argv[1], prompt)\n    print(\"%-8s %4d tokens  %s\" % (source, out[\"tokens\"], out[\"text\"][:48]))",
      "note": "**Uma imagem, vários prompts**, cada um impresso com a origem da resposta."
    }
  ]
}
```

```
ana@lab:~/mm$ python cached.py media/invoice-0931.png "What is the total?" "What is the total?" "What is the total of this invoice?"
provider 1113 tokens  The invoice is INV-0931 from Lantern & Quill Dis
cache    1113 tokens  The invoice is INV-0931 from Lantern & Quill Dis
provider 1116 tokens  The invoice is INV-0931 from Lantern & Quill Dis
ana@lab:~/mm$ grep -c chat/completions /var/log/labmm/requests.jsonl
2
```

Três perguntas, dois pedidos no log do labmm. O segundo "What is the total?" veio do cache. A terceira pergunta quer dizer a mesma coisa com outras palavras e **errou o cache**, porque a chave é o prompt exato: um cache por significado é possível, gerando o embedding do prompt como a aula 12 fez com os pedaços, e ele pode então devolver a resposta de uma pergunta que só parecia parecida. A resposta em si é a regra `l08-invoice-high` da aula 8, escrita pelo curso.

Um cache guarda as respostas do provedor, que podem conter dados pessoais das imagens. Ele precisa das mesmas regras de retenção e de exclusão que as imagens.

O segundo hábito é um **orçamento conferido antes da chamada**. Uma cota mensal por usuário, em centavos inteiros como esta plataforma guarda o próprio dinheiro, e uma estimativa feita com a unidade da planilha antes de qualquer coisa ser enviada:

```python
"""A monthly allowance per user, in integer cents, checked BEFORE the call rather than after."""
from decimal import ROUND_CEILING, Decimal

PER_SECOND = Decimal("0.0001")   # sheet: whisper-1 input_cost_per_second, in dollars
ALLOWANCE = 50           # cents a user may spend in a month

spent = {"ana": 47}


def charge_cents(seconds):
    cents = Decimal(str(seconds)) * PER_SECOND * 100
    return int(cents.to_integral_value(rounding=ROUND_CEILING))   # UP: an estimate that undercharges is a leak


def transcribe(user, seconds):
    cost = charge_cents(seconds)
    if spent.get(user, 0) + cost > ALLOWANCE:
        return f"refused: {seconds} s costs {cost} cents and {user} has {ALLOWANCE - spent.get(user, 0)} left"
    spent[user] = spent.get(user, 0) + cost
    return f"sent: {seconds} s for {cost} cents, {user} has {ALLOWANCE - spent[user]} left"


for seconds in (55.38, 600, 1800):
    print(transcribe("ana", seconds))
```

```
ana@lab:~/mm$ python -c "print(600 * 0.0001 * 100)"
6.000000000000001
ana@lab:~/mm$ python budget.py
sent: 55.38 s for 1 cents, ana has 2 left
refused: 600 s costs 6 cents and ana has 2 left
refused: 1800 s costs 18 cents and ana has 2 left
```

A ligação de um minuto custa um centavo e é enviada. Dez minutos custariam seis centavos com dois sobrando e são recusados antes de qualquer áudio sair. Três escolhas ali são deliberadas. A estimativa **arredonda para cima**, porque uma estimativa que arredonda para baixo deixa cada chamada passar uma fração de centavo mais barata, e mil delas somam. E a conferência é **antes** da chamada: um orçamento lido depois que a conta chega é um relatório, não um limite.

A terceira é o `Decimal`, e a primeira linha da captura mostra por quê. Em ponto flutuante, 600 segundos a US$ 0,0001 dão 6,000000000000001 centavos, e arredondar para cima transforma isso em **7**. A primeira versão deste programa fez exatamente isso, e toda ligação de dez minutos era recusada um centavo antes. Dinheiro nunca é float, a mesma regra que esta plataforma segue para o próprio dinheiro.
