---
title: Um stream que quebra no meio
version: 1
---

Uma requisição comum dá certo ou falha. **Um stream pode fazer as duas coisas**: começa, entrega
parte da resposta e então falha. O código de status era 200 quando o primeiro byte saiu, então a
falha precisa viajar dentro do stream, como um evento `error`.

O labllm pode ser mandado a falhar um stream de propósito. Este é o interruptor do laboratório, não
algo que um provedor oferece:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"stream_error_after": 12}'; echo
{"rpm": 50, "fail_next": null, "fail_count": 0, "stream_error_after": 12}
```

## O que o leitor tinha quando quebrou

```python
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except anthropic.APIError as e:
    print(f"\n[{type(e).__name__}: {e.message}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
```

```
ana@dev:~/shop$ python midstream.py
The cart stores prices as integer cents because a float cannot hold
[APIStatusError: {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}}]
[67 characters were on the screen and are not an answer]
```

**Sessenta e sete caracteres chegaram à tela antes do erro.** O SDK lançou `APIStatusError` de
dentro do laço, com o erro do provedor na mensagem. Um `overloaded_error` como este é um tipo de
erro real, e é o provedor dizendo que está ocupado, não que a requisição estava errada.

## Pelo relay

O relay da aula 9 seção 04 pega o mesmo erro e manda à página o próprio evento `error`:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"stream_error_after": 12}' >/dev/null; python relay.py & sleep 1; node client.mjs 'Explain in a paragraph why the cart stores prices in cents.'; kill $!
The cart stores prices as integer cents because a float cannot hold
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
