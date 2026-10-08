---
title: Streaming
version: 2
---

Uma resposta chega mais rápido do que parece se as primeiras palavras aparecem enquanto o resto ainda está
sendo escrito. O **streaming** pede ao provedor que mande a resposta em pedaços à medida que são
produzidos, numa resposta HTTP longa, em vez de esperar o todo. Para um chat de atendimento, é a
diferença entre uma caixa em branco por dois segundos e palavras aparecendo na hora.

```schooling-example
{
  "language": "python",
  "file": "stream.py",
  "parts": [
    {
      "code": "import sys\n\nfrom openai import OpenAI\nfrom rag import SYSTEM, retrieve",
      "note": "A busca e as instruções do `rag.py`."
    },
    {
      "code": "client = OpenAI()\nquestion = sys.argv[1]\nsources = retrieve(question)\nnumbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                       for n, (_, path, text, updated, _) in enumerate(sources, 1))",
      "note": "O prompt é montado exatamente como antes."
    },
    {
      "code": "stream = client.chat.completions.create(\n    model=\"llama3.2:3b\", temperature=0, stream=True, stream_options={\"include_usage\": True},\n    messages=[{\"role\": \"system\", \"content\": SYSTEM},\n              {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}])",
      "note": "O `stream=True` transforma a resposta num iterador de pedaços, e o `include_usage` pede as contagens de tokens num último pedaço só delas."
    },
    {
      "code": "pieces = 0\nfor chunk in stream:\n    if chunk.choices and chunk.choices[0].delta.content:\n        print(chunk.choices[0].delta.content, end=\"\", flush=True)\n        pieces += 1\n    if chunk.usage:\n        usage = chunk.usage\nprint()\nprint(f\"{pieces} pieces; usage: {usage.prompt_tokens} in, {usage.completion_tokens} out\")",
      "note": "O texto de cada pedaço é impresso no momento em que chega; o uso é guardado do pedaço que o traz."
    }
  ]
}
```

```
ana@vm:~/rag$ python stream.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought. This is also confirmed by [2], which states that gift cards are valid for two years from purchase.
41 pieces; usage: 336 in, 42 out
```

**A resposta chegou em 41 pedaços**, cada um com mais ou menos um token de texto, impressos à medida
que o modelo os escrevia, e o uso chegou com o último pedaço porque a requisição o pediu com
`include_usage`. Num processador sem placa de vídeo, a diferença é a experiência inteira: as primeiras
palavras aparecem um ou dois segundos depois da busca, e o resto vem na velocidade da leitura.

## O que o streaming muda num pipeline de recuperação

**A busca continua acontecendo antes.** Nada pode ser transmitido até as fontes serem achadas e o prompt
montado, então o tempo até a primeira palavra é o tempo da busca mais o tempo do modelo até o primeiro
token. O streaming esconde o tempo de geração, nunca o de recuperação; uma busca lenta continua sendo uma
primeira palavra lenta.

**As citações chegam no fim, ou em pedaços.** No Chat Completions os marcadores `[1]` são texto comum e
vêm junto com o resto; transformá-los em links tem de esperar cada um estar completo. Na API da
Anthropic, as citações chegam como eventos `citations_delta` próprios, presos ao bloco a que pertencem.

**As verificações rodam depois.** A verificação de citação da aula 7 e qualquer recusa decidida depois da
geração precisam da resposta inteira. Então uma resposta transmitida é mostrada à medida que chega e
depois talvez corrigida ou anotada, o que é uma escolha de interface: algumas equipes mostram o fluxo e
acrescentam avisos no fim, outras seguram uma resposta jurídica até ela ser conferida. De qualquer modo,
**a recusa decidida pelo piso não precisa de streaming nenhum**, mais um motivo para decidi-la antes de o
modelo ser chamado.

## A linha de uso

O streaming muda como o uso chega, não o que ele é: 336 tokens de entrada e 42 de saída, que o registro
na última seção desta aula guarda do mesmo jeito para uma resposta sem streaming. A aula 17 soma esses dois
números em todas as consultas, e uma resposta transmitida cujo uso nunca foi lido é uma consulta que
custou algo que ninguém contou, e por isso o programa o pede.
