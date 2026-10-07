---
title: Orçamentos que são cumpridos, não esperados
version: 2
---

Uma chamada de modelo é a única linha do seu código cujo custo é decidido pela entrada, e a entrada
muitas vezes vem de um usuário. Um usuário pode colar um livro no chat de suporte; um bug pode
repetir uma requisição mil vezes; uma funcionalidade nova pode ser dez vezes mais popular que a
estimativa. **Um orçamento é uma verificação em código que roda antes de a requisição sair**, não
um painel que alguém olha depois da fatura.

## Uma guarda na frente de cada chamada

O `~/shop/scratch/budget.py` embrulha a chamada numa função que estima primeiro e recusa de dois
jeitos: uma requisição grande demais por si só, e um usuário que já gastou a cota do dia:

```schooling-example
{
  "language": "python",
  "file": "scratch/budget.py",
  "parts": [
    {
      "code": "import anthropic\nimport tiktoken\n\nDAILY_LIMIT = 20_000  # input tokens per user per day\nPER_REQUEST = 3_000\nMARGIN = 1.2  # tiktoken is not this model's tokenizer, so the estimate gets room\nclient = anthropic.Anthropic()\nenc = tiktoken.get_encoding(\"o200k_base\")\nspent: dict[str, int] = {}\n\n\nclass OverBudget(Exception):\n    pass\n\n\n",
      "note": "**Dois limites, em tokens.** Por requisição, para uma colagem não custar uma fortuna; por usuário e dia, para uma pessoa não gastar a parte de todo mundo. O `MARGIN` está lá porque a estimativa vem de um tokenizador que não é o deste modelo."
    },
    {
      "code": "def ask(user: str, messages: list, max_tokens: int = 300):\n    n = int(sum(len(enc.encode(m[\"content\"])) for m in messages) * MARGIN)\n    if n + max_tokens > PER_REQUEST:\n        raise OverBudget(f\"about {n} input tokens + {max_tokens} out is over {PER_REQUEST} per request\")\n    if spent.get(user, 0) + n > DAILY_LIMIT:\n        raise OverBudget(f\"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today\")\n",
      "note": "**Estime antes, na sua própria máquina**, e recuse antes de mandar qualquer coisa. A recusa é uma exceção com nome, então quem chama não tem como confundi-la com uma resposta vazia."
    },
    {
      "code": "    r = client.messages.create(model=\"llama3.2:3b\", max_tokens=max_tokens, messages=messages)\n    used = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)\n    spent[user] = spent.get(user, 0) + used\n    return r, used\n\n\n",
      "note": "**Cobre o que foi usado de verdade**, pelo `usage`, não pela estimativa."
    },
    {
      "code": "code = open(\"shop/cart.py\").read()\nquestion = [{\"role\": \"user\", \"content\": code + \"\\nExplain the shipping rule above.\"}]\nhuge = [{\"role\": \"user\", \"content\": open(\"CONVENTIONS.md\").read() * 8}]\nfor user, msgs in [(\"ana\", question), (\"ana\", huge), (\"bea\", question)]:\n    try:\n        r, used = ask(user, msgs)\n        print(f\"{user}: ok, {used} in, {r.usage.output_tokens} out; spent today {spent[user]}\")\n    except OverBudget as e:\n        print(f\"{user}: refused before sending: {e}\")\n"
    }
  ]
}
```

Três requisições de dois usuários, a segunda delas oito cópias do `CONVENTIONS.md` coladas numa
pergunta:

```
ana@dev:~/shop$ python scratch/budget.py
ana: ok, 299 in, 141 out; spent today 299
ana: refused before sending: about 3590 input tokens + 300 out is over 3000 per request
bea: ok, 299 in, 139 out; spent today 299
```

**A requisição grande foi recusada antes de ser enviada**: uns 3.590 tokens pela estimativa, contra
um limite de 3.000 por requisição. Ela não custou nada, nem uma chamada, porque a estimativa foi
feita nesta máquina. Essa é a troca com a chamada de contagem do provedor da aula 2 seção 03: um
número exato por uma ida e volta pela rede, ou uma estimativa com margem de graça. Uma guarda como
esta é o lugar da estimativa; a conta é o lugar do número exato, e o `usage` é de onde ele vem.

## De onde vêm os limites

- **Por requisição**: o tamanho da maior requisição legítima, mais uma margem. A janela da aula 2
  seção 02 é o limite rígido; o seu orçamento é um mais baixo que você escolheu.
- **Por usuário, por dia**: da estimativa de custo da aula 2 seção 05 e de quanto dela uma pessoa
  pode gastar. Guardado num banco de dados, não num dicionário em memória como aqui, para sobreviver
  a um reinício e ser compartilhado entre servidores.
- **Para a conta inteira**: os consoles dos provedores oferecem limites de gasto ou alertas, ou os
  dois. Ligue-os no primeiro dia, baixos, e suba-os de propósito. Eles são a última linha, não a
  única: param o dinheiro, e param junto a funcionalidade para todo mundo.

**Recuse com uma mensagem com que uma pessoa consiga agir.** "Esta mensagem é longa demais para
processar; mande um trecho mais curto" deixa o usuário resolver. Um erro genérico depois de um 400
do provedor não deixa, e já custou a chamada de contagem e o tempo.
