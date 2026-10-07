---
title: Streaming com o SDK
version: 2
---

Ninguém interpreta esses eventos à mão em código de aplicação. O SDK os lê, junta os pedaços e
devolve texto, e no fim monta o mesmo objeto de mensagem que uma requisição comum devolve.

## Pedaços, conforme chegam

```python
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        print(text, end="|", flush=True)
    final = stream.get_final_message()
print()
print(final.stop_reason, final.usage.input_tokens, "in,", final.usage.output_tokens, "out")
```

```
ana@dev:~/shop$ python pieces.py
The| use| of| cents| to| store| prices| in| cart| stores| is| a| historical| convention| that| originated| from| the| United| States|.| In| the| |197|0|s|,| the| US| government| mandated| that| prices| be| displayed| in| cents| and| fractions| of| a| cent|,| as| part| of| the| Uniform| Pricing| Act|.| This| law| required| retailers| to| display| prices| in| a| way| that| was| easy| to| understand| and| compare|.| C|ents| made| it| simple| to| express| prices| and| discounts| in| a| way| that| was| intuitive| to| consumers|,| as| it| provided| a| clear| and| consistent| unit| of| measurement|.| Additionally|,| using| cents| allowed| for| more| precise| price| displays|,| making| it| easier| for| consumers| to| make| informed| purchasing| decisions|.| Over| time|,| this| convention| was| adopted| by| other| countries| and| has| since| become| a| standard| practice| in| retail| pricing|.|
end_turn 18 in, 144 out
```

As barras ficam onde um pedaço terminou e o próximo começou. **Um pedaço é mais ou menos um token**,
então ele parte onde o tokenizador parte: `C|ents` são dois pedaços, e `1970s` são quatro, um
espaço, `197`, `0` e `s`. A última linha vem do `get_final_message()`, montado depois de o stream
acabar, com o `stop_reason` e as contagens de tokens que uma requisição comum teria dado.

A resposta também está errada sobre o mundo: atribui o hábito a uma "Uniform Pricing Act" dos anos
1970. A pergunta não diz nada sobre o código da ana, então o modelo respondeu sobre lojas em geral
(aula 1 seção 10), e respondeu com confiança (aula 1 seção 11). O streaming muda quando você vê uma
resposta, não quanto ela vale.

Duas consequências para quem mostra os pedaços:

- **Nunca suponha que um pedaço é uma palavra.** Um programa que põe um espaço entre pedaços, ou
  capitaliza a primeira letra de cada um, produz `C ents`.
- **Acrescente, não substitua.** Cada pedaço é texto novo a acrescentar ao que está na tela; nada
  nele repete o que veio antes.

## O mesmo na API da OpenAI

```python
"""The same, through OpenAI's chat completions: chunks with a delta, then a finish_reason."""
import openai

client = openai.OpenAI()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
for chunk in client.chat.completions.create(model="llama3.2:3b", messages=ASK, stream=True):
    choice = chunk.choices[0]
    if choice.delta.content:
        print(choice.delta.content, end="|", flush=True)
    if choice.finish_reason:
        print("\nfinish_reason:", choice.finish_reason)
```

```
ana@dev:~/shop$ python openai_pieces.py
The| practice| of| storing| prices| in| cents| in| shopping| carts| is| a| long|-standing| convention| in| the| United| States|.| This| tradition| originated| in| the| |196|0|s|,| when| prices| on| merchandise| were| typically| displayed| in| cents|,| as| a| way| to| make| calculations| easier| for| cash|iers|.| When| a| customer| entered| the| store|,| the| cashier| would| scan| the| items|,| calculate| the| total| cost| in| penn|ies|,| and| then| make| change| in| dollars|.| This| system| allowed| the| cashier| to| quickly| and| accurately| process| transactions|,| as| well| as| to| break| down| change| into| smaller| denomin|ations|.| Over| time|,| the| use| of| cents| has| become| ingr|ained| in| shopping| culture|,| despite| the| widespread| adoption| of| digital| payment| systems| and| electronic| cash| registers|.| Today|,| customers| often| take| the| presence| of| cents| in| shopping| carts| as| a| given|,| without| questioning| the| decision| to| use| this| system| as| the| default|.|
finish_reason: stop
```

Outros pedaços, porque é um segundo sorteio, e o mesmo embrulho por baixo: `cash|iers`, `penn|ies`,
`denomin|ations`. **Cada chunk leva um `delta`** com o texto novo, e o último leva um
`finish_reason` e nenhum texto. Por baixo, é o mesmo formato de server-sent events sem nomes em
`event:`, terminando numa linha que diz `data: [DONE]`.
