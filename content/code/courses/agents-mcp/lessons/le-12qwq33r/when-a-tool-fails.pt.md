---
title: Quando uma ferramenta falha
version: 1
---

## Por padrão, a execução termina

O `get_order` levanta `LookupError` para um pedido que não existe. Com o padrão do ADK:

```
ana@lab:~/agents$ python adk_run.py default "Where is my order M-9999?" 2> stderr.txt; wc -l < stderr.txt; tail -1 stderr.txt
support  call    get_order {"order_id": "M-9999"}
raised   LookupError: no order M-9999
174
LookupError: no order M-9999
```

**A exceção encerrou a execução.** O modelo tinha pedido o pedido, a ferramenta levantou erro, e o ADK não mandou nada de volta ao modelo: o erro saiu do `run_async`, onde o `adk_run.py` o capturou, e o ADK registrou um traceback de 174 linhas na saída de erro no caminho (`stderr.txt`). Compare com a aula 8, em que o SDK mandou ao modelo uma frase genérica e a execução seguiu. Aqui um pedido inexistente e um programa que caiu parecem iguais para o cliente, a menos que o código em volta da execução decida outra coisa.

## Um callback transforma o erro num resultado

O `on_tool_error_callback` é chamado quando uma ferramenta levanta erro, com a ferramenta, os argumentos e a exceção. O que ele devolver vira o resultado da ferramenta:

```schooling-example
{
  "language": "python",
  "file": "adk_run.py",
  "parts": [
    {
      "code": "def say_what_failed(tool, args, tool_context, error):\n",
      "note": "**O callback**: a ferramenta, os argumentos, o contexto e o erro."
    },
    {
      "code": "    return {\"error\": f\"{type(error).__name__}: {error}\"}",
      "note": "**Um resultado com o tipo e a mensagem do erro**, que é a regra da aula 4 mais uma vez."
    }
  ]
}
```

```
ana@lab:~/agents$ python adk_run.py caught "Where is my order M-9999?"
support  call    get_order {"order_id": "M-9999"}
support  result  get_order {"error": "LookupError: no order M-9999"}
support  text    I could not find an order M-9999. Could you check the number in your confirmation email?
```

Agora o modelo leu `{"error": "LookupError: no order M-9999"}` e pôde responder ao cliente. Um callback no agente cobre toda ferramenta, o que é um lugar melhor para a regra que um `try` em cada função.

## O limite de chamadas ao modelo

```
ana@lab:~/agents$ python adk_run.py one-call "Where is my order M-1043?" 2> stderr.txt; wc -l < stderr.txt
support  call    get_order {"order_id": "M-1043"}
support  result  get_order {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "s
raised   LlmCallsLimitExceededError: Max number of llm calls limit of `1` exceeded
98
```

O `RunConfig(max_llm_calls=1)` deixou acontecer uma chamada ao modelo, rodou a ferramenta que ele pediu, e levantou `LlmCallsLimitExceededError` antes da segunda chamada; o ADK registrou 98 linhas no caminho. Como o limite da aula 8, é uma exceção, então o programa decide o que o cliente vê. O padrão é 500 chamadas por execução, um teto contra um laço desgovernado e não um orçamento; um agente de suporte que precisa de mais que um punhado de chamadas para uma mensagem tem um problema que um limite maior não resolve.
