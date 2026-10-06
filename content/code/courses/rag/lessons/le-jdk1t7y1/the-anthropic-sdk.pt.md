---
title: O SDK da Anthropic e suas citações
version: 1
---

A Messages API da Anthropic faz uma coisa que o formato Chat Completions deixa para o programa: ela pode
receber as fontes como **documentos** e devolver a resposta já presa a eles, cada frase com o documento de
onde veio e os caracteres exatos que usou. A aula 7 tirava o `[1]` do texto e conferia depois; aqui o
provedor devolve estrutura.

```schooling-example
{
  "language": "python",
  "file": "rag_claude.py",
  "parts": [
    {
      "code": "import sys\n\nimport anthropic\nfrom rag import retrieve",
      "note": "O SDK da Anthropic, e o `retrieve` do `rag.py`: a busca não muda com o provedor do gerador."
    },
    {
      "code": "client = anthropic.Anthropic()\nquestion = sys.argv[1]\nsources = retrieve(question)\ndocuments = [{\"type\": \"document\", \"title\": path, \"citations\": {\"enabled\": True},\n              \"source\": {\"type\": \"text\", \"media_type\": \"text/plain\", \"data\": text}}\n             for _, path, text, _, _ in sources]",
      "note": "Cada fonte vira um bloco `document` com o caminho como título e citações ativadas. A numeração some: a API se refere aos documentos pela posição na lista."
    },
    {
      "code": "message = client.messages.create(\n    model=\"extract-1\", max_tokens=300,\n    system=\"Answer the customer's question from the documents.\",\n    messages=[{\"role\": \"user\", \"content\": documents + [{\"type\": \"text\", \"text\": question}]}])",
      "note": "Os documentos vão na mensagem do usuário, antes da pergunta. O prompt de sistema é mais curto, porque agora é a API, e não o prompt, que pede as citações."
    },
    {
      "code": "for block in message.content:\n    if block.type == \"text\" and block.text.strip():\n        print(block.text)\n        for c in block.citations or []:\n            print(f\"  document {c.document_index}, {c.document_title}, characters {c.start_char_index}-{c.end_char_index}\")\nprint(\"usage:\", message.usage.input_tokens, \"in,\", message.usage.output_tokens, \"out\")",
      "note": "A resposta é uma lista de blocos de texto, e um bloco que veio de um documento leva uma lista `citations`: qual documento, o título e o intervalo de caracteres de onde o texto foi tirado."
    }
  ]
}
```

## Rodando

```
ana@lab:~/rag$ python rag_claude.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought.
  document 0, Gift card terms > Validity, characters 0-62
Gift cards are valid for two years from purchase and cannot be exchanged for cash.
  document 1, Payments, invoices and gift cards > Gift cards, characters 0-82
usage: 187 in, 32 out
```

**Cada frase voltou como um bloco próprio, com uma citação dizendo qual documento e quais caracteres.**
*Document 0, Gift card terms > Validity, characters 0-62*: os primeiros 62 caracteres daquela fonte são a
frase citada. Um programa agora consegue destacar o trecho exato na fonte quando um leitor clica na
citação, que é a experiência que o leitor jurídico da aula 2 queria.

Duas notas sobre o que é real aqui. Os formatos de requisição e resposta são os da Anthropic, como o SDK
os espera; o labgen implementa o bloco `document`, o campo `citations` e o tipo de citação
`char_location` com fidelidade bastante para o SDK oficial ler as respostas dele. As respostas são do
extract-1. Um modelo Claude real escreve as próprias frases e prende citações aos trechos em que se
apoiou; o extract-1 copia frases inteiras, então os trechos dele são sempre frases inteiras começando no
primeiro caractere.

## O que muda e o que não muda

**A busca não muda.** O `retrieve` é importado do `rag.py`: quais pedaços chegam ao modelo é decidido
antes de qualquer provedor entrar, e trocar o gerador deixa a revocação em 3 exatamente onde a aula 8 a
mediu.

**O prompt encolhe.** A instrução de citar cada frase pelo número some; a própria API pede as citações. A
contagem de tokens mostra isso: 187 tokens de entrada aqui, contra 314 para a mesma pergunta pelo
`rag.py`, na próxima seção e no registro.

**A verificação não some.** A seção sobre citação literal da aula 7 disse: um intervalo diz de onde o
provedor afirma que o texto veio. Para uma resposta jurídica, o programa ainda confirma que o texto citado
está na fonte naqueles caracteres, o que, com o intervalo na mão, é uma comparação de strings.

## Escolhendo entre os dois

Escreva contra o formato que o provedor que você usa faz melhor, mantenha a busca independente dele, e
mantenha a avaliação da aula 8 rodando nos dois. A pergunta a fazer a um recurso específico de um provedor
é a que a aula 6 fez à reordenação: o que o conjunto de teste diz que ele compra.
