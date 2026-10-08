---
title: O SDK da Anthropic e as citações dele
version: 2
---

A API Messages da Anthropic faz uma coisa que o formato Chat Completions deixa para o programa: ela pode
receber as fontes como **documentos** e devolver a resposta já presa a elas, cada parte com o documento
de onde veio e os caracteres exatos que usou. A aula 7 tirou o `[1]` do texto e o conferiu depois; com
citações de documento, o provedor devolve estrutura.

O Ollama também fala a API Messages, e por isso o `env.sh` define `ANTHROPIC_BASE_URL`. O `documents.py`
manda as fontes do jeito que a documentação da Anthropic mostra:

```schooling-example
{
  "language": "python",
  "file": "documents.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import retrieve\n\nclient = anthropic.Anthropic()\nquestion, citations = sys.argv[1], sys.argv[2:] != [\"plain\"]\nsources = retrieve(question)",
      "note": "O SDK da Anthropic, e o `retrieve` do `rag.py`: a busca não muda com o provedor do gerador. Um segundo argumento, `plain`, deixa as citações de fora."
    },
    {
      "code": "documents = []\nfor _, path, text, _, _ in sources:\n    doc = {\"type\": \"document\", \"title\": path, \"source\": {\"type\": \"text\", \"media_type\": \"text/plain\", \"data\": text}}\n    if citations:\n        doc[\"citations\"] = {\"enabled\": True}\n    documents.append(doc)",
      "note": "Cada fonte vira um bloco `document` com o caminho como título. Com as citações ligadas, a API prende cada parte da resposta aos caracteres do documento de onde ela veio."
    },
    {
      "code": "try:\n    message = client.messages.create(\n        model=\"llama3.2:3b\", max_tokens=300,\n        system=\"Answer the customer's question from the documents.\",\n        messages=[{\"role\": \"user\", \"content\": documents + [{\"type\": \"text\", \"text\": question}]}])\nexcept anthropic.BadRequestError as e:\n    sys.exit(f\"refused: {e.message}\")\nprint(message.content[0].text)\nu = message.usage\nprint(f\"usage: {u.input_tokens} in, {u.cache_read_input_tokens or 0} read from cache, {u.output_tokens} out\")",
      "note": "Os documentos vão na mensagem do usuário, antes da pergunta. O primeiro bloco da resposta, e o uso, que diz quanto da requisição o modelo leu: `input_tokens` é a parte lida do zero, e `cache_read_input_tokens` a parte que uma requisição anterior já tinha processado, que o Ollama, como a Anthropic, conta à parte."
    }
  ]
}
```

## Rodando

```
ana@vm:~/rag$ python documents.py "How long is a gift card valid?"
refused: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'json: cannot unmarshal object into Go struct field MessagesRequest.messages.citations of type []anthropic.Citation'}, 'request_id': 'req_ba8656454cd844834e5cf92d'}
ana@vm:~/rag$ python documents.py "How long is a gift card valid?" plain
I don't have the specific information on the validity period of gift cards. However, I can suggest some general guidelines.

Gift card validity periods vary depending on the issuer and type of card. Some gift cards may be valid for a specific period, such as one year from the date of purchase, while others may be valid for a longer period, such as five years.

Typically, gift cards can be categorized into the following types:

1. Fixed-term gift cards: These have a specific expiration date, usually one year from the date of purchase.
2. Open-ended gift cards: These do not have an expiration date and can be used until the balance is depleted.
3. Bonus gift cards: These offer additional rewards or benefits, but may have specific rules or restrictions.

To find the specific validity period of a gift card, it's best to check the issuer's website or contact their customer service directly. They can provide you with the most up-to-date and accurate information on the card's validity.
usage: 27 in, 15 read from cache, 202 out
```

**O Ollama recusou a requisição.** A implementação dele da API Messages não tem citações de documento, e
o erro diz isso nas palavras do programa em Go que leu a requisição. É uma resposta justa: uma requisição
que pede algo que o servidor não sabe fazer deve falhar.

A segunda execução é a perigosa. Sem o campo `citations` a requisição foi aceita, e **a resposta não
sabe nada sobre os vales-presente da Marginalia**. A linha de uso diz por quê: 27 tokens lidos do zero e
15 do cache, que são a mensagem de sistema e a pergunta e mais nada. O Ollama aceitou os blocos
`document` e os jogou fora, e nada na resposta ou no status diz isso. Camadas de compatibilidade são
parciais, e a parte que elas deixam de fora nem sempre falha alto; **a contagem de tokens de entrada é o
único lugar onde um descarte silencioso aparece**, e esse é um motivo para registrá-la em cada
requisição.

Com uma chave da Anthropic sua, o `documents.py` roda como está contra um modelo Claude: os documentos
são lidos, e a resposta volta em blocos, cada um com uma lista `citations` dando a posição do documento,
o título e o intervalo de caracteres usado, para que um programa destaque o trecho exato quando um
leitor clica na citação. É a experiência que o leitor jurídico da aula 2 queria, e ela não foi rodada
para este curso.

## O mesmo pipeline pelo SDK da Anthropic

O que todo servidor que fala a API Messages lê é texto. O `rag_claude.py` manda as fontes como o
`rag.py` manda, numeradas, na mensagem do usuário:

```schooling-example
{
  "language": "python",
  "file": "rag_claude.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import SYSTEM, retrieve\n\nclient = anthropic.Anthropic()\nquestion = sys.argv[1]\nsources = retrieve(question)\nnumbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                       for n, (_, path, text, updated, _) in enumerate(sources, 1))",
      "note": "As mesmas fontes numeradas e as mesmas instruções do `rag.py`, escritas como texto puro, que todo servidor que fala a API Messages lê."
    },
    {
      "code": "message = client.messages.create(\n    model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM,\n    messages=[{\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}])\nprint(message.content[0].text)\nu = message.usage\nprint(f\"usage: {u.input_tokens} in, {u.cache_read_input_tokens or 0} read from cache, {u.output_tokens} out\")",
      "note": "O SDK é o da Anthropic e a requisição é da API Messages; só a forma das fontes mudou. As citações voltam a ser `[n]` no texto, que o verificador da aula 7 já lê."
    }
  ]
}
```

```
ana@vm:~/rag$ python rag_claude.py "How long is a gift card valid?"
According to sources [1] and [2], a gift card is valid for two years from the day it was bought.
usage: 1 in, 335 read from cache, 26 out
```

**A resposta volta pelo SDK da Anthropic com citações `[n]` no texto**, e desta vez o uso conta as
fontes: 336 tokens de prompt, dos quais 1 era novo para o servidor e 335 foram lidos do cache dele. O
Ollama guarda o começo do último prompt que processou, e a consulta registrada na última seção tinha
feito a mesma pergunta com as mesmas fontes na mesma ordem. O uso da Anthropic conta as duas partes
separadas, `input_tokens` e `cache_read_input_tokens`, e um programa que registra só a primeira registra
um token para esta requisição.

## O que muda e o que não muda

**A busca não muda.** O `retrieve` é importado do `rag.py`: quais pedaços chegam ao modelo é decidido
antes de qualquer provedor entrar, e trocar o gerador deixa o recall@3 exatamente onde a aula 8 o mediu.

**A verificação não some.** A seção sobre citações literais da aula 7 disse: um trecho diz de onde o
provedor diz que o texto veio. Para uma resposta jurídica, o programa ainda confirma que o texto citado
está na fonte, e com o trecho em mãos isso é uma comparação de strings; com `[n]` no texto, é o
`verify.py` da aula 7.

## Escolhendo entre os dois

Escreva contra o formato que o provedor que você usa faz melhor, mantenha a busca independente dele, e
mantenha a avaliação da aula 8 rodando nos dois. A pergunta a fazer a um recurso específico de um
provedor é a que a aula 6 fez à reordenação: o que o conjunto de teste diz que ele compra. E antes de
confiar num deles por um servidor compatível, confira que o servidor o implementa, lendo a contagem de
tokens de uma requisição que deveria ter sido grande.
