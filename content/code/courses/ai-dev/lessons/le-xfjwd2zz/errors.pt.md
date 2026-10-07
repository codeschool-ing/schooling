---
title: Um stream que quebra no meio
version: 2
---

Uma requisição comum dá certo ou falha. **Um stream pode fazer as duas coisas**: começa, entrega
parte da resposta e então falha. O código de status era 200 quando o primeiro byte saiu, então a
falha precisa viajar dentro do stream, como um evento `error`.

O jeito mais fácil de ver um é tirar o servidor do ar enquanto ele escreve. O Ollama é parado abaixo
com `sudo pkill -x ollama`, cinco segundos depois de começar uma resposta, que é o que fechar o
terminal que roda o `ollama serve` faz, e parecido com o que uma conexão caída ou um servidor que
quebrou parecem do lado do programa. Inicie-o de novo depois, com `sudo systemctl start ollama` ou
`ollama serve`.

## O que o leitor tinha quando quebrou

```python
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except Exception as e:  # an API error, or the connection itself, as below
    print(f"\n[{type(e).__module__}.{type(e).__name__}: {e}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
```

```
ana@dev:~/shop$ python midstream.py & sleep 5; sudo pkill -x ollama; wait
The practice of pricing products in cents in cart stores is a historical and cultural convention that originated in the United States. The reason for this is rooted in the country's early commerce practices,
[httpx2.RemoteProtocolError: peer closed connection without sending complete message body (incomplete chunked read)]
[207 characters were on the screen and are not an answer]
```

**Duzentos e sete caracteres chegaram à tela antes do erro.** E o erro não é do SDK: é
`httpx2.RemoteProtocolError`, da biblioteca HTTP que fica por baixo, que o SDK deixa passar quando
uma conexão morre no meio de um stream. Um programa que pegasse só `anthropic.APIError` teria
terminado num traceback com meia resposta na tela. É por isso que o `midstream.py` pega toda exceção
neste ponto e diz qual foi: seja lá o que encerrou o stream, o que o leitor tem não é uma resposta.

Um erro que o provedor manda dentro do stream, como um `overloaded_error` quando está ocupado, chega
como um `anthropic.APIStatusError`; este nem teve a chance, porque não havia mais servidor para
mandá-lo.

## Pelo relay

O relay da aula 9 seção 04 pega a mesma falha, com o mesmo `except` amplo, e manda à página o
próprio evento `error`:

```
ana@dev:~/shop$ python relay.py & sleep 3; node client.mjs "Explain in a paragraph why the cart stores prices in cents." & sleep 5; sudo pkill -x ollama; wait %2; kill %1
The practice of storing prices in cents in retail stores, particularly in the United States, dates back to the early 20th century. One reason for this convention is historical and practical. Prior
[error: the answer stopped halfway; please ask again]
```

A página mostra o texto parcial e depois a mensagem, e **esse par é o estado honesto**: estas
palavras chegaram, a resposta não. Dois jeitos errados de lidar com isso são comuns:

- **Deixar o texto parcial como se fosse a resposta.** Ele parece uma resposta, e para no meio de
  uma frase. Marque-o, ou substitua-o.
- **Repetir e acrescentar.** Uma segunda requisição começa a resposta de novo pela primeira palavra.
  Acrescentada ao que está na tela, ela repete uma frase e meia. Uma repetição substitui.

## Repetindo um stream

Uma falha antes do primeiro pedaço é igual a uma requisição comum que falhou: repita com espera
crescente, como a aula 10 mostra. Uma falha depois de pedaços mostrados é uma decisão da página.
**Repetir sozinho** serve se a nova resposta substitui a velha e a pessoa vê que recomeçou.
**Perguntar à pessoa** é melhor quando a resposta é longa e ela talvez já tenha lido o bastante. De
um jeito ou de outro, o log deve dizer que um stream quebrou depois de N tokens, porque esses tokens
foram cobrados.
