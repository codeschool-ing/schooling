---
title: O que nunca cortar
version: 2
---

A compactação vale para fontes tanto quanto para conversas: um documento longo buscado por um agente,
uma fonte antiga ainda no contexto de um chat, uma seção longa demais para o orçamento. A aula 12
comprimia fontes mantendo frases inteiras sobre a pergunta; um resumo vai além, e algumas frases não
sobrevivem a serem separadas das vizinhas. Duas seções da política de devoluções, resumidas em no máximo
25 palavras:

```schooling-example
{
  "language": "python",
  "file": "policy.py",
  "parts": [
    {
      "code": "import sys\n\nfrom chunking import load, sections\nfrom compact import summarise\n\nmeta, body = load()[\"returns-policy\"]\nfor path, text in sections(body):\n    if path.endswith(sys.argv[1]):\n        print(\" \".join(text.split()))\n        print(\"summary:\")\n        print(summarise([text], int(sys.argv[2])))",
      "note": "Uma seção da política de devoluções, e o resumo que o modelo faz dela."
    }
  ]
}
```
```
ana@vm:~/rag$ python policy.py "Items that cannot be returned" 25
The following cannot be returned unless they arrive damaged or faulty: - personalised copies and copies signed by the author; - jigsaw puzzles and games whose packaging has been opened; - anything bought in the clearance section; - newspapers and magazines.
summary:
Certain items, including personalised copies, opened games, clearance purchases, and newspapers, cannot be returned unless damaged or faulty.
```

**O resumo manteve a regra, a exceção e os quatro tipos de item**, numa frase só, e perdeu uma coisa
no caminho: *copies signed by the author* virou *personalised copies*, e um cliente com um exemplar
autografado não é mais nomeado por ele. Uma lista resumida numa frase mantém as categorias e larga os
membros, e o membro largado é aquele sobre o qual alguém pergunta.

```
ana@vm:~/rag$ python policy.py "Gifts" 25
The person who received a gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return from their own account.
summary:
The person who received a gift can return it with a receipt, getting store credit, while the buyer must initiate the return from their own account.
```

A regra dos presentes manteve as duas metades, e a segunda metade perdeu a condição. A política diz que
o comprador inicia a devolução *para receber o dinheiro de volta no cartão original, em vez disso*; o
resumo diz que o comprador tem de iniciá-la, e ponto, então ele se lê como uma regra sobre toda
devolução de presente e é sobre a exceção. Uma frase que dependia do *instead* foi reescrita sem a
palavra, e o sentido foi junto.

Destas e das seções anteriores, as coisas que uma compactação precisa manter, ou manter juntas:

- **Identificadores e números**: números de pedido, valores, datas, prazos. São ditos uma vez e
  necessários com exatidão.
- **Negações e condições**: *not*, *unless*, *only*, *except*. Perder uma inverte a frase.
- **Referências com aquilo a que se referem**: *it*, *them*, *instead*, *the other*. Uma frase que
  aponta para trás só é verdadeira ao lado do que aponta.
- **Escolhas e instruções da pessoa**: o que ela pediu e como falar com ela.
- **Tudo o que uma resposta já citou.** Se uma resposta citou uma fonte como [2], o contexto compactado
  ainda precisa deixar o [2] ser conferido, ou a verificação da aula 7 não tem o que verificar.
