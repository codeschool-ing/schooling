---
title: Chamando o endpoint de embeddings do Gemini
version: 1
---

A chamada de embedding de todo provedor tem o mesmo formato: entra texto, volta um vetor por texto,
e o que muda são os nomes das coisas. A aula 7 conheceu esse formato pelo SDK da OpenAI. Esta seção
o conhece pelo do Google, `google-genai`, e três seções mais adiante pelo do Cohere.

**Nenhum dos dois SDKs fala com o Google ou com o Cohere aqui.** Os dois falam com o
**labembed**, um servidor pequeno escrito para este curso que escuta em `127.0.0.1:8500`. Ele
responde às mesmas URLs com o mesmo JSON que os provedores respondem, de um jeito parecido o
bastante para que as bibliotecas deles o aceitem sem modificação. Os vetores são reais, dos dois
modelos que rodam nesta máquina, servidos com os nomes do próprio laboratório, `lab-minilm` (384 números) e `lab-wordllama` (256). O
que ele não é: o modelo do Google. Ele recusa o nome `gemini-embedding-001` em vez de responder com
outra coisa usando esse nome. Contra o Google, o código abaixo muda em três lugares — sem
`http_options`, o nome real do modelo e a sua própria chave — e em nada mais.

```schooling-example
{
  "language": "python",
  "file": "gemini.py",
  "parts": [
    {
      "code": "import os\nimport numpy as np\nfrom google import genai\nfrom google.genai import types",
      "note": "O SDK se instala como `google.genai`; `types` traz as classes com que uma requisição é montada."
    },
    {
      "code": "client = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)",
      "note": "`genai.Client` recebe a chave e, por `http_options`, o endereço para onde mandar as requisições. Aqui é o labembed; sem `http_options`, o SDK vai para o Google."
    },
    {
      "code": "r = client.models.embed_content(model=\"lab-minilm\", contents=\"When your refund arrives\")\nv = np.array(r.embeddings[0].values, dtype=np.float32)\nprint(len(r.embeddings), v.shape)",
      "note": "Entra um texto. A resposta traz uma lista de embeddings, um por texto, e cada um tem seus números em `values`."
    },
    {
      "code": "titles = [\"Tracking a parcel\", \"Payment methods we accept\", \"Audiobooks\"]\nr = client.models.embed_content(\n    model=\"lab-wordllama\",\n    contents=titles,\n    config=types.EmbedContentConfig(\n        task_type=\"RETRIEVAL_DOCUMENT\",\n        output_dimensionality=128,\n    ),\n)",
      "note": "Três textos numa chamada, com um `config` que diz para que eles servem e quantos números devolver. O `lab-wordllama` devolve 256 se ninguém pedir menos."
    },
    {
      "code": "V = np.array([e.values for e in r.embeddings], dtype=np.float32)\nprint(V.shape, np.linalg.norm(V, axis=1).round(4))\nV = V / np.linalg.norm(V, axis=1, keepdims=True)",
      "note": "Imprima os comprimentos como chegaram e depois divida cada vetor pelo próprio comprimento. O Google documenta que só a saída de tamanho cheio vem normalizada, então um vetor truncado precisa desta linha para que o produto escalar seja um cosseno."
    }
  ],
  "output": "ana@lab:~/emb$ python gemini.py\n1 (384,)\n(3, 128) [1. 1. 1.]\nana@lab:~/emb$ jq -c '{path, inputs, dims, task_type}' /var/log/labembed/requests.jsonl\n{\"path\":\"/v1beta/models/lab-minilm:batchEmbedContents\",\"inputs\":1,\"dims\":384,\"task_type\":null}\n{\"path\":\"/v1beta/models/lab-wordllama:batchEmbedContents\",\"inputs\":3,\"dims\":128,\"task_type\":\"RETRIEVAL_DOCUMENT\"}"
}
```

**Um método recebe um texto ou uma lista deles.** `embed_content` devolveu um embedding para o
título sozinho e três para a lista, na ordem em que os títulos entraram. Não há um campo `index`
para casar, como na resposta da OpenAI; a posição em `r.embeddings` é a única ligação de volta com o
texto, então guarde a lista que você mandou.

A linha de log que o labembed escreveu para cada requisição mostra algo que o código não mostra.
**O SDK mandou as duas chamadas para `:batchEmbedContents`**, o endpoint para vários textos, até a
que tinha um título só: o nome do método está no singular e a requisição que passa pela rede é um
lote de um. O log também mostra o `task_type` chegando como `null` na primeira chamada e como
`RETRIEVAL_DOCUMENT` na segunda, que é o assunto da próxima seção.

## Menos dimensões, a pedido

`output_dimensionality=128` pediu 128 números em vez dos 256 do modelo, e recebeu. O servidor fica
com as 128 primeiras coordenadas e descarta o resto, o que só funciona com um modelo treinado para
que as coordenadas iniciais carreguem sozinhas a maior parte do significado. A aula 7 mediu quanto
isso custa ao `lab-wordllama` nas 24 consultas. O `lab-minilm` não foi treinado assim, e pedir 128 a
ele é recusado, como mostra a segunda recusa no fim desta seção.

O modelo do próprio Google, **gemini-embedding-001**, devolve 3.072 números por padrão e é
documentado como treinado exatamente para esse corte, com 768 e 1.536 como os tamanhos menores
recomendados. A documentação também diz que **só a saída cheia, de 3.072 números, vem
normalizada.** Uma mais curta são as primeiras coordenadas de um vetor unitário, que já
não tem comprimento 1, então o produto escalar entre duas delas deixa de ser um cosseno. A última
parte de `gemini.py` divide cada vetor pelo próprio comprimento por esse motivo. O labembed
renormaliza depois de cortar, e é por isso que os comprimentos impressos antes dessa linha já são
1,0 e, aqui, a linha não muda nada. Contra o Google, é ela que mantém cada nota na faixa da aula 2.

## Quando uma requisição é recusada

O SDK transforma uma recusa num `ClientError` com o código HTTP, a palavra de status do Google e a
mensagem:

```schooling-example
{
  "language": "python",
  "file": "gemini_errors.py",
  "parts": [
    {
      "code": "import os\nfrom google import genai\nfrom google.genai import errors, types\n\nclient = genai.Client(\n    api_key=os.environ[\"GEMINI_API_KEY\"],\n    http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]),\n)\ntries = [\n    (\"gemini-embedding-001\", None),\n    (\"lab-minilm\", types.EmbedContentConfig(output_dimensionality=128)),\n    (\"lab-minilm\", types.EmbedContentConfig(task_type=\"SEARCH_QUERY\")),\n]\nfor model, config in tries:\n    try:\n        client.models.embed_content(model=model, contents=\"Audiobooks\", config=config)\n    except errors.ClientError as e:\n        print(e.code, e.status, \"|\", e.message)",
      "note": "Três requisições que o servidor recusa, cada uma por um motivo. `errors.ClientError` é o que o SDK levanta para qualquer resposta 4xx, e ela traz o código, a palavra de status do Google e a mensagem."
    }
  ],
  "output": "ana@lab:~/emb$ python gemini_errors.py\n404 NOT_FOUND | The model `gemini-embedding-001` does not exist or you do not have access to it. This lab serves lab-minilm and lab-wordllama.\n400 INVALID_ARGUMENT | This model does not support specifying dimensions.\n400 INVALID_ARGUMENT | Invalid value at 'requests[0].task_type' (SEARCH_QUERY)"
}
```

A primeira é a verificação do nome: o nome de modelo de um provedor recebe um 404 aqui, nunca um
substituto. A segunda é o modelo de dimensão fixa recusando `output_dimensionality`, a mesma recusa
que a aula 7 encontrou no endpoint da OpenAI. A terceira é um task type que não existe; a lista dos
válidos do Google está na próxima seção, e `SEARCH_QUERY` não está nela.
