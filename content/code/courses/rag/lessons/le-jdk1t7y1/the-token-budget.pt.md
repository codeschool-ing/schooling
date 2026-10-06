---
title: O orçamento de tokens
version: 1
---

Toda requisição tem um limite de tamanho, e a aula 1 bateu nele: 9.072 tokens de documentos contra a
janela de 8.192 do extract-1, recusados antes de uma palavra ser lida. Com recuperação o prompt é pequeno,
algumas centenas de tokens, e o limite parece longe. Ele deixa de parecer no dia em que alguém aumenta o k,
acrescenta um histórico de conversa, ou indexa um documento com uma seção enorme. Um programa que conta
antes de mandar nunca encontra a recusa.

## Contando antes de mandar

O `budget.py` conta os tokens de cada parte do prompt com a codificação do provedor, mantém as fontes na
ordem de posição enquanto cabem, e descarta o resto:

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "import sys\n\nimport tiktoken\nfrom rag import SYSTEM, retrieve",
      "note": "O tiktoken para a contagem, e a busca e as instruções do `rag.py`."
    },
    {
      "code": "enc = tiktoken.get_encoding(\"cl100k_base\")\nBUDGET = int(sys.argv[2])\nquestion = sys.argv[1]\nsources = retrieve(question)",
      "note": "O orçamento vem da linha de comando, e as fontes da busca, em ordem de posição."
    },
    {
      "code": "cost = lambda s: len(enc.encode(f\"[0] {s[1]} (updated {s[3]})\\n{s[2]}\"))\nfixed = len(enc.encode(SYSTEM)) + len(enc.encode(f\"Question: {question}\"))\nprint(f\"instructions and question: {fixed} tokens\")",
      "note": "Uma fonte custa o cabeçalho e o texto. As instruções e a pergunta são pagas aconteça o que acontecer."
    },
    {
      "code": "kept, used = [], fixed\nfor s in sources:\n    if used + cost(s) > BUDGET:\n        print(f\"  drop  {cost(s):4} tokens  {s[1]}\")\n        continue\n    kept.append(s)\n    used += cost(s)\n    print(f\"  keep  {cost(s):4} tokens  {s[1]}\")\nprint(f\"{used} of {BUDGET} tokens, {len(kept)} of {len(sources)} sources\")",
      "note": "Percorrer as fontes em ordem de posição, ficar com cada uma que cabe inteira, e descartar cada uma que não cabe."
    }
  ]
}
```

```
ana@lab:~/rag$ python budget.py "How long after my return arrives will I get the refund?" 400
instructions and question: 85 tokens
  keep    84 tokens  Returns and refunds policy > Refunds
  keep    85 tokens  Returns and refunds policy > The return window
  keep   104 tokens  Returns and refunds policy > Items sold by marketplace sellers
358 of 400 tokens, 3 of 3 sources
ana@lab:~/rag$ python budget.py "How long after my return arrives will I get the refund?" 250
instructions and question: 85 tokens
  keep    84 tokens  Returns and refunds policy > Refunds
  drop    85 tokens  Returns and refunds policy > The return window
  drop   104 tokens  Returns and refunds policy > Items sold by marketplace sellers
169 of 250 tokens, 1 of 3 sources
```

Com 400 tokens para gastar, as três fontes cabem, 358 no total. Com 250, a primeira fonte cabe e as duas
seguintes não, e o prompt sai com uma fonte, 169 tokens. A pergunta do reembolso continua com a resposta,
porque a resposta era a primeira fonte. **Descartar pela posição mantém a melhor e perde o resto**, o que
está certo quando a posição é um bom guia, e a aula 12 trata dos casos em que não é.

## O que contar

**Tudo o que entra na requisição.** As instruções, as fontes com os cabeçalhos, a pergunta, qualquer
histórico de conversa, e o espaço deixado para a resposta: a recusa da aula 1 foi de 9.072 tokens mais 256
reservados para a resposta. Um orçamento que esquece a resposta é um orçamento que falha nas respostas
mais longas.

**Com a codificação do provedor.** A contagem aqui é do `cl100k_base` do tiktoken, que é com o que o
labgen conta; o uso do provedor para esta pergunta pelo `rag.py` diz 314 tokens de prompt, que incluem o
custo extra por mensagem que o provedor acrescenta e esta contagem deixa de fora. Perto o bastante para
orçar com margem, nunca perto o bastante para orçar até o último token. A API da Anthropic oferece um
endpoint de contagem de tokens exatamente para isso, e o labgen não o implementa.

**Na ordem de posição, inteiras.** Uma fonte cortada ao meio para caber é uma fonte sem a segunda metade,
em geral a metade com a exceção. Descartar fontes inteiras mantém cada fonte intacta.

## Por que um orçamento menor que a janela

A janela é o máximo que uma requisição pode levar, não o que ela deveria levar. A aula 1 deu três motivos
para não enchê-la, preço, tempo e distração, e cada um vale com um centésimo da janela tanto quanto com
ela inteira. Então o orçamento é uma decisão de produto: o menor contexto que mantém a correção da aula 8
onde está. A aula 12 mede esse número e empacota a janela para atingi-lo.
