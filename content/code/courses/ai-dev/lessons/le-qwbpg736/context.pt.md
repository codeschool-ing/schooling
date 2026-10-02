---
title: O contexto é tudo o que ele tem
version: 1
---

Uma janela de chat dá a impressão de que o modelo se lembra da conversa. **Não lembra.** O modelo
lê só o que uma requisição põe na frente dele, e quando a resposta foi escrita, nada daquela
requisição fica dentro do modelo para a próxima. O que parece memória é a aplicação mandando a
conversa inteira de novo, a cada turno. Algumas APIs oferecem guardar o histórico do lado do
provedor e se referir a ele por um id (a Responses API da OpenAI faz isso). Isso muda onde a lista
fica guardada. O modelo continua lendo tudo, e você continua pagando por tudo, a cada turno.

Esse texto, tudo o que o modelo lê antes de escrever, é o **contexto**. A geração da aula 1 seção
02 era um laço sobre o contexto; esta seção é sobre o que entra nele.

## O que uma conversa realmente envia

O `lab/turns.py` monta uma conversa de três turnos do jeito que todo aplicativo de chat faz,
acrescentando a uma lista, e pergunta ao labllm quantos tokens de entrada cada requisição levaria.
Ele usa o SDK `anthropic`, o mesmo código que falaria com a API da Anthropic; no laboratório o SDK
aponta para o labllm, e a aula 1 seção 08 mostra como.

```python
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    n = client.messages.count_tokens(model="tiny-1", messages=history).input_tokens
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {n} input tokens")
    history.append({"role": "assistant", "content": "(the reply would go here)"})
```

```
ana@dev:~/shop$ python lab/turns.py
turn 1: 1 messages, 9 input tokens
turn 2: 3 messages, 27 input tokens
turn 3: 5 messages, 47 input tokens
```

E isto é o que a terceira requisição levou, lido do próprio registro do labllm do que ele recebeu:

```
ana@dev:~/shop$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m["role"], "|", m["content"]) for m in json.load(sys.stdin)["request"]["messages"]]'
user | My cart has three mugs.
assistant | (the reply would go here)
user | Add a lamp to it.
assistant | (the reply would go here)
user | How many items are in it now?
```

**Para responder "quantos itens", o modelo precisa da primeira mensagem**, e o único jeito de ele
tê-la é recebê-la de novo. Tire o histórico e a terceira pergunta chega sozinha, sobre um carrinho
de que o modelo nunca ouviu falar. Cada turno reenvia tudo o que veio antes, então os tokens que
você paga crescem a cada troca. A aula 2 mede o quanto.

## O que mais mora no contexto

Uma requisição costuma levar mais que a conversa:

- um **prompt de sistema**, as instruções permanentes: no papel de quem o modelo está agindo, o que
  pode e o que não pode fazer, em que formato responder;
- **documentos** que a aplicação escolheu incluir, como um arquivo do seu editor (aula 3) ou
  trechos achados por busca (aula 6);
- **definições de ferramentas** e os resultados das ferramentas que o modelo pediu (aulas 7 e 8).

Tudo isso é texto, tudo é contado em tokens, e tudo divide um único limite, a **janela de
contexto**, com a resposta que o modelo está prestes a escrever. A aula 2 é sobre esse limite.

## A regra prática

**Se não está na requisição, o modelo não sabe.** Ele não vê o resto do seu repositório, o
chamado em que você está trabalhando, a versão da biblioteca que você instalou, nem o que você
disse a ele ontem em outra aba. Quando um assistente responde como se soubesse essas coisas, ou é
porque uma ferramenta as pôs no contexto sem você notar (a aula 3 mostra o que um editor junta),
ou porque ele chutou, e a aula 1 seção 07 é sobre chutar.
