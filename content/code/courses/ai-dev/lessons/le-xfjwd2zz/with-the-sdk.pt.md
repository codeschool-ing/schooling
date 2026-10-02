---
title: Streaming com o SDK
version: 1
---

Ninguém interpreta esses eventos à mão em código de aplicação. O SDK os lê, junta os pedaços e
devolve texto, e no fim monta o mesmo objeto de mensagem que uma requisição comum devolve.

## Pedaços, conforme chegam

```python
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        print(text, end="|", flush=True)
    final = stream.get_final_message()
print()
print(final.stop_reason, final.usage.input_tokens, "in,", final.usage.output_tokens, "out")
```

```
ana@dev:~/shop$ python pieces.py
The| cart| stores| prices| as| integer| cents| because| a| float| cannot| hold| most| decimal| amounts| exactly|.| In| binary| floating| point|,| |0|.|1| plus| |0|.|2| is| not| |0|.|3|,| and| a| total| built| from| many| such| sums| dr|ifts| by| a| cent| here| and| there|.| Inte|gers| add| exactly|,| so| the| cart| adds| cents| and| formats| them| only| at| the| edge|,| when| it| prints| a| price| for| a| person|.|
end_turn 15 in, 82 out
```

As barras ficam onde um pedaço terminou e o próximo começou. **Um pedaço é mais ou menos um token**,
então ele parte onde o tokenizador parte: `dr|ifts` e `Inte|gers` são dois pedaços cada, e `0.1` são
três. A última linha vem do `get_final_message()`, montado depois de o stream acabar, com o
`stop_reason` e as contagens de tokens que uma requisição comum teria dado.

Duas consequências para quem mostra os pedaços:

- **Nunca suponha que um pedaço é uma palavra.** Um programa que põe um espaço entre pedaços, ou
  capitaliza a primeira letra de cada um, produz `dr ifts`.
- **Acrescente, não substitua.** Cada pedaço é texto novo a acrescentar ao que está na tela; nada
  nele repete o que veio antes.

## O mesmo na API da OpenAI

```python
"""The same, through OpenAI's chat completions: chunks with a delta, then a finish_reason."""
import openai

client = openai.OpenAI()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
for chunk in client.chat.completions.create(model="scripted-1", messages=ASK, stream=True):
    choice = chunk.choices[0]
    if choice.delta.content:
        print(choice.delta.content, end="|", flush=True)
    if choice.finish_reason:
        print("\nfinish_reason:", choice.finish_reason)
```

```
ana@dev:~/shop$ python openai_pieces.py
The| cart| stores| prices| as| integer| cents| because| a| float| cannot| hold| most| decimal| amounts| exactly|.| In| binary| floating| point|,| |0|.|1| plus| |0|.|2| is| not| |0|.|3|,| and| a| total| built| from| many| such| sums| dr|ifts| by| a| cent| here| and| there|.| Inte|gers| add| exactly|,| so| the| cart| adds| cents| and| formats| them| only| at| the| edge|,| when| it| prints| a| price| for| a| person|.|
finish_reason: stop
```

Mesmos pedaços, outro embrulho. **Cada chunk leva um `delta`** com o texto novo, e o último leva um
`finish_reason` e nenhum texto. Por baixo, é o mesmo formato de server-sent events sem nomes em
`event:`, terminando numa linha que diz `data: [DONE]`.
