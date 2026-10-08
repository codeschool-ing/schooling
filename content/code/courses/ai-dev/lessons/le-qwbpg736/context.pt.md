---
title: O contexto é tudo o que ele tem
version: 2
---

Uma janela de chat dá a impressão de que o modelo se lembra da conversa. **Não lembra.** O modelo
lê só o que uma requisição põe na frente dele, e quando a resposta foi escrita, nada daquela
requisição fica dentro do modelo para a próxima. O que parece memória é a aplicação mandando a
conversa inteira de novo, a cada turno. Algumas APIs oferecem guardar o histórico do lado do
provedor e se referir a ele por um id (a Responses API da OpenAI faz isso). Isso muda onde a lista
fica guardada. O modelo continua lendo tudo, e você continua pagando por tudo, a cada turno.

Esse texto, tudo o que o modelo lê antes de escrever, é o **contexto**. A geração da seção 06 era um
laço sobre o contexto; esta seção é sobre o que entra nele.

## O que uma conversa realmente envia

O `~/shop/scratch/turns.py` monta uma conversa de três turnos do jeito que toda aplicação de chat
monta, acrescentando a uma lista, e envia a lista inteira a cada turno. Ele usa o SDK
`anthropic`, o mesmo código que falaria com a API da Anthropic; a seção 03 apontou o SDK para o
Ollama.

```python
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    r = client.messages.create(model="llama3.2:3b", max_tokens=60, system="Answer in one short sentence.",
                               messages=history)
    reply = r.content[0].text
    sent = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {sent} input tokens")
    print(f"  {reply}")
    history.append({"role": "assistant", "content": reply})

print("what the third request carried:")
for message in history[:-1]:
    print(f"  {message['role']:9} | {message['content']}")
```

O prompt de `system` pede respostas curtas, o que deixa a transcrição legível; a próxima parte
desta seção diz o que é um prompt de sistema. O Ollama informa parte da entrada de cada requisição
como `cache_read_input_tokens`, a parte que ele já tinha lido no turno anterior, e a aula 2
explica esse campo, então o programa soma os dois para chegar a tudo o que a requisição levou.

```
ana@dev:~/shop$ python scratch/turns.py
turn 1: 1 messages, 38 input tokens
  You currently have a total of three items in your cart.
turn 2: 3 messages, 66 input tokens
  Your cart now has four items: three mugs and a lamp.
turn 3: 5 messages, 98 input tokens
  There are five items in your cart now.
what the third request carried:
  user      | My cart has three mugs.
  assistant | You currently have a total of three items in your cart.
  user      | Add a lamp to it.
  assistant | Your cart now has four items: three mugs and a lamp.
  user      | How many items are in it now?
```

**Para responder à terceira pergunta, o modelo precisa das duas primeiras trocas**, e o único
jeito de ele ter essas trocas é recebê-las de novo. Aqui está a terceira pergunta enviada sozinha:

```
ana@dev:~/shop$ ollama run llama3.2:3b "How many items are in it now?"
I don't have have any information about an "it" to know how many items are
in it. Could you please provide more context or clarify what you are
referring to? I'll do my best to help.
```

Ele nunca ouviu falar do carrinho. Cada turno reenvia tudo o que veio antes, então os tokens que
você paga crescem a cada troca: 38, 66, 98 aqui, para perguntas de poucas palavras. A aula 2 mede
o quão rápido.

**E repare na terceira resposta da conversa.** O modelo recebeu "três itens" e "quatro itens: três
canecas e um abajur", e respondeu *cinco*. Ter os fatos no contexto torna provável uma resposta
certa; não a torna garantida, e nada na resposta diz qual das duas você recebeu. Rode você mesmo
e é bem possível que venha *quatro*, ou *cinco*, ou outra coisa, já que a seção 08 mostrou que
toda resposta é sorteada. A seção 11 é sobre essa distância.

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
ou porque ele chutou, e a seção 11 é sobre chutar.
