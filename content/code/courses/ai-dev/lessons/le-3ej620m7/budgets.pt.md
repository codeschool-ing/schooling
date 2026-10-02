---
title: Orçamentos que são cumpridos, não esperados
version: 1
---

Uma chamada de modelo é a única linha do seu código cujo custo é decidido pela entrada, e a entrada
muitas vezes vem de um usuário. Um usuário pode colar um livro no chat de suporte; um bug pode
repetir uma requisição mil vezes; uma funcionalidade nova pode ser dez vezes mais popular que a
estimativa. **Um orçamento é uma verificação em código que roda antes de a requisição sair**, não
um painel que alguém olha depois da fatura.

## Uma guarda na frente de cada chamada

O `lab/budget.py` embrulha a chamada numa função que conta primeiro e recusa de dois jeitos: uma
requisição grande demais por si só, e um usuário que já gastou a cota do dia:

```schooling-example
{
  "language": "python",
  "file": "lab/budget.py",
  "parts": [
    {
      "code": "import anthropic\n\nDAILY_LIMIT = 20_000  # input tokens per user per day\nPER_REQUEST = 4_000\nclient = anthropic.Anthropic()\nspent: dict[str, int] = {}\n\n\nclass OverBudget(Exception):\n    pass\n\n\n",
      "note": "**Dois limites, em tokens.** Por requisição, para uma colagem não custar uma fortuna; por usuário e por dia, para uma pessoa não gastar a parte de todos."
    },
    {
      "code": "def ask(user: str, messages: list, max_tokens: int = 300):\n    n = client.messages.count_tokens(model=\"scripted-1\", messages=messages).input_tokens\n    if n + max_tokens > PER_REQUEST:\n        raise OverBudget(f\"{n} input tokens + {max_tokens} out is over {PER_REQUEST} per request\")\n    if spent.get(user, 0) + n > DAILY_LIMIT:\n        raise OverBudget(f\"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today\")\n",
      "note": "**Conte primeiro, com o contador do próprio provedor**, e recuse antes de qualquer coisa ser gerada. A recusa é uma exceção com nome, então quem chama não a confunde com uma resposta vazia."
    },
    {
      "code": "    r = client.messages.create(model=\"scripted-1\", max_tokens=max_tokens, messages=messages)\n    spent[user] = spent.get(user, 0) + r.usage.input_tokens\n    return r\n\n\n",
      "note": "**Cobre o que foi de fato usado**, pelo `usage`, não pela estimativa."
    },
    {
      "code": "question = [{\"role\": \"user\", \"content\": \"Explain the shop's shipping rule.\"}]\nhuge = [{\"role\": \"user\", \"content\": open(\"/opt/aidev/share/corpus.txt\").read()[:30_000]}]\nfor user, msgs in [(\"ana\", question), (\"ana\", huge), (\"bea\", question)]:\n    try:\n        r = ask(user, msgs)\n        print(f\"{user}: ok, {r.usage.input_tokens} in, {r.usage.output_tokens} out; spent today {spent[user]}\")\n    except OverBudget as e:\n        print(f\"{user}: refused before sending: {e}\")"
    }
  ]
}
```

Três requisições de dois usuários, a segunda delas uma colagem de trinta mil caracteres:

```
ana@dev:~/shop$ python lab/budget.py
ana: ok, 10 in, 147 out; spent today 10
ana: refused before sending: 7163 input tokens + 300 out is over 4000 per request
bea: ok, 10 in, 147 out; spent today 10
```

**A requisição grande foi recusada antes de ser enviada**: 7.163 tokens contra um limite de 4.000
por requisição. Ela ainda custou uma chamada de contagem. O registro do labllm a mostra como a
requisição 36, seguida da contagem e da requisição que fizeram a terceira (uma chamada de contagem
real é gratuita na API da Anthropic, e tem limite de taxa):

```
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c "import json, sys; [print(r[\"n\"], r[\"path\"], r[\"status\"]) for r in map(json.loads, sys.stdin)]"
36 /v1/messages/count_tokens 200
37 /v1/messages/count_tokens 200
38 /v1/messages 200
```

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
