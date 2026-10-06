---
title: Um resumo é uma escolha
version: 1
---

O `compact.py` pede ao modelo um resumo num número dado de palavras:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
  "parts": [
    {
      "code": "def summarise(turns, words):\n    \"\"\"extract-1's summary of the turns, in at most WORDS words.\"\"\"\n    reply = client.chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": f\"Summarise the conversation in at most {words} words.\"},\n        *({\"role\": \"user\", \"content\": t} for t in turns)])\n    return reply.choices[0].message.content",
      "note": "O resumo é do modelo: a instrução e o limite de palavras na mensagem de sistema, os turnos como a conversa. Com o extract-1 é uma seleção de frases inteiras; com um modelo de linguagem seriam frases novas."
    }
  ]
}
```

Aqui está o resumo do extract-1 dos onze primeiros turnos da Beatriz em no máximo 40 palavras:

```
ana@lab:~/rag$ python one.py 40
The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. How do I send back Mansfield Park?
```

Quatro frases, todas dela, e cada uma verdadeira. **Lido como registro da conversa, ele está errado de
jeitos que ninguém veria só pelo resumo.** Não há número de pedido, então um atendente que pega o chat
começa pedindo-o de novo. Nada diz que ela quer só e-mail, então a próxima resposta pode prometer um
telefonema que ela disse não poder atender. Nada diz para onde vai o exemplar de reposição, então ele
vai para o endereço de onde ela sai na semana que vem. E "I bought it somewhere else in the meantime"
perdeu a frase que dizia o que era "it".

O extract-1 resume mantendo as frases mais próximas do sentido médio da conversa, então mantém aquilo de
que a conversa mais trata, dois livros e uma troca, e larga o que é dito uma vez: um identificador, uma
preferência, um endereço. Um modelo de linguagem escreve frases próprias e perde outras coisas, às
vezes as mesmas. **O ponto não são as escolhas deste resumidor; é que todo resumo é uma escolha**, feita
por algo que não sabe de quais detalhes o próximo turno vai precisar. A próxima seção mede a escolha em
vez de lê-la.
