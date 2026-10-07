---
title: Quando ele se paga
version: 1
---

Uma máquina é paga por hora, ocupada ou não. Uma API é paga por token e não custa nada quando
ninguém a chama. Então a comparação não é "qual é mais barato", e sim **em que volume os dois custam
o mesmo**.

Primeiro, o tamanho das requisições da ana. O `volume.py` manda cada um dos quarenta casos ao
modelo, pela biblioteca da Anthropic e pelo Ollama, e lê o `usage` que volta, que conta os tokens
que a requisição de fato usou:

```python
import json

import anthropic

client = anthropic.Anthropic()  # Ollama, through desk.env
system = open("prompts/triage.txt").read()
ins, outs = [], []
for line in open("cases/triage.jsonl"):
    r = client.messages.create(model="llama3.2:3b", max_tokens=10, system=system,
                               messages=[{"role": "user", "content": json.loads(line)["text"]}])
    # the part of the prompt the server had already read is counted apart, as a cache read
    ins.append(r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0))
    outs.append(r.usage.output_tokens)
print(f"{len(ins)} e-mails: {sum(ins) / len(ins):.1f} tokens in, {sum(outs) / len(outs):.1f} out, on average")
```

```
ana@desk:~/desk$ python volume.py
40 e-mails: 81.1 tokens in, 3.9 out, on average
```

Uns 81 tokens de entrada e quatro de saída. A entrada é o prompt de três linhas e um e-mail, mais o
que o template de chat do modelo põe em volta deles, os tokens especiais da aula 1 seção 08; a saída
é um rótulo de uma ou duas palavras, e às vezes dois rótulos onde o prompt pediu um. **As contagens
são da Llama**, feitas com o tokenizador dela: o Claude conta o mesmo texto com outro, então o número
é uma estimativa do tamanho, que é tudo de que um ponto de equilíbrio precisa. O servidor informa a
parte do prompt que já tinha lido na requisição anterior como leitura de cache, e o `volume.py` soma
as duas de volta; a aula 17 trata de por que uma API as conta separadas.

O `breakeven.py` pega esses números, arredondados para cima, 82 de entrada e 5 de saída, os preços de um modelo na tabela e o
custo mensal de uma máquina. A Lantern Books recebe uns 400 e-mails por dia, e a máquina custa US$
1.500 por mês: os dois são suposições do curso, redondas o bastante para serem lidas como tais.

```python
import json
import sys

sheet = json.load(open("litellm-21881c57.json"))  # the copy sheet.py keeps, from lesson 2
model, machine = sys.argv[1], float(sys.argv[2])  # the machine's monthly cost is an assumption
tokens_in, tokens_out, per_day = 82, 5, 400  # volume.py, rounded up
price = sheet[model]
per_request = tokens_in * price["input_cost_per_token"] + tokens_out * price["output_cost_per_token"]
print(f"{model}: ${per_request * 1e6:.0f} per million requests")
print(f"  ana's {per_day} a day: ${per_request * per_day * 30:.2f} a month")
print(f"  a ${machine:,.0f} machine pays for itself at {machine / per_request / 30:,.0f} requests a day")
```

```
ana@desk:~/desk$ python breakeven.py claude-haiku-4-5 1500
claude-haiku-4-5: $107 per million requests
  ana's 400 a day: $1.28 a month
  a $1,500 machine pays for itself at 467,290 requests a day
```

**Um dólar e vinte e oito centavos por mês.** A 400 e-mails por dia, toda a carga de classificação
da Lantern Books custa menos que um café no modelo mais barato que a tabela lista para a Anthropic, e
uma máquina teria de classificar **467.290 e-mails por dia** para custar o mesmo. Agora o Claude Opus
5.5, a que a tabela dá quatro vezes esse preço por token:

```
ana@desk:~/desk$ python breakeven.py claude-opus-5-5 1500
claude-opus-5-5: $428 per million requests
  ana's 400 a day: $5.14 a month
  a $1,500 machine pays for itself at 116,822 requests a day
```

Quatro vezes o custo por requisição, e ainda **US$ 5,14 por mês**. O volume de equilíbrio cai para
116.822 por dia, que é umas 290 vezes o que a loja recebe.

## O formato da resposta

A conta aqui é sobre uma tarefa pequena: poucos tokens de entrada, quase nenhum de saída. Mude
qualquer um deles e o equilíbrio se move:

- **prompts longos ou respostas longas** multiplicam o custo por requisição, e o volume de
  equilíbrio cai na mesma proporção;
- **volume alto e constante** mantém a máquina ocupada, que é o único jeito de ela sair barata por
  token (seção 05);
- **uma carga em rajadas** pede uma máquina dimensionada para o pico e paga no vale.

Para a ana, a resposta em dinheiro nem chega perto. **Auto-hospedar ainda pode ser certo para ela**,
mas não pelo custo, e a seção 08 lista os motivos que não são sobre dinheiro.
