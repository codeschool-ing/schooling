---
title: Reescrevendo a pergunta
version: 2
---

A busca precisa de uma pergunta que se sustente sozinha. A correção comum é uma **reescrita**: antes
de buscar, pedir a um modelo que transforme a última mensagem e a conversa até ali numa pergunta que
não precise de histórico. O motor de chat do LlamaIndex que faz isso leva a instrução como template:

```schooling-example
{
  "language": "python",
  "file": "condense.py",
  "parts": [
    {
      "code": "from llama_index.core.chat_engine.condense_question import DEFAULT_TEMPLATE\n\nprint(DEFAULT_TEMPLATE)",
      "note": "A instrução que o motor de chat de condensação do LlamaIndex manda, impressa da própria biblioteca."
    }
  ]
}
```

```
ana@vm:~/rag$ python condense.py
Given a conversation (between Human and Assistant) and a follow up message from Human, rewrite the message to be a standalone question that captures all relevant context from the conversation.

<Chat History>
{chat_history}

<Follow Up Message>
{question}

<Standalone question>
```

O `rewrite.py` manda esse template ao llama3.2:3b com os turnos anteriores da Beatriz como histórico, e
busca com o que volta:

```schooling-example
{
  "language": "python",
  "file": "rewrite.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom llama_index.core.chat_engine.condense_question import DEFAULT_TEMPLATE\nfrom openai import OpenAI\nfrom search import vector\n\nclient = OpenAI()\nturns = [json.loads(line)[\"text\"] for line in open(f\"data/{sys.argv[1]}.jsonl\")]",
      "note": "O modelo de texto do LlamaIndex, o modelo e a busca da aula 6. Só o modelo de texto é emprestado: a chamada é a do SDK puro."
    },
    {
      "code": "for n in map(int, sys.argv[2:]):\n    history = \"\\n\".join(f\"Human: {t}\" for t in turns[:n - 1])\n    prompt = DEFAULT_TEMPLATE.format(chat_history=history, question=turns[n - 1])\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0,\n                                           messages=[{\"role\": \"user\", \"content\": prompt}])\n    question = reply.choices[0].message.content.strip()\n    top = vector(question, 1, \"status = %s\", (\"current\",))[0]\n    print(f\"turn {n}: {turns[n - 1]}\")\n    print(f\"  rewritten: {question}\")\n    print(f\"  {top[3]:.3f}  {top[1]}\")",
      "note": "Para cada turno nomeado, os turnos anteriores do cliente como histórico, a reescrita que o modelo devolve, e o pedaço que a pergunta reescrita acha primeiro."
    }
  ]
}
```

```
ana@vm:~/rag$ python rewrite.py chat-a 10 11 12
turn 10: How do I send back Mansfield Park?
  rewritten: Can I return the damaged copy of Mansfield Park and send it back to you, and if so, where should I send it?
  0.594  Returns and refunds policy > Damaged, faulty and wrong items
turn 11: How long will the refund for Middlemarch take?
  rewritten: Here is a rewritten version of the follow-up message as a standalone question that captures all relevant context from the conversation:

"Will the refund for the incorrect book, Mansfield Park, be processed quickly enough to arrive before I move house next week, and if so, how long can I expect it to take?"
  0.592  Returns and refunds policy > Damaged, faulty and wrong items
turn 12: Sorry, what was my order number again? I need it for my notes.
  rewritten: What is the order number for the two parcels that were sent to me, one of which has water damage and the other of which contains the wrong book?
  0.590  Returns and refunds policy > Damaged, faulty and wrong items
```

**Três reescritas, três erros, e três buscas que acharam a seção dos livros danificados.** O turno 10
virou uma pergunta sobre devolver *the damaged copy of Mansfield Park*; o livro danificado era o
*Persuasion*. A reescrita do turno 11 começou com *Here is a rewritten version of the follow-up
message*, o modelo falando da tarefa em vez de fazê-la, e depois trocou os títulos: o reembolso é do
*Middlemarch*, e a reescrita pergunta sobre o *Mansfield Park*. O turno 12 pediu o número do pedido
*of the two parcels*, que nenhum documento consegue responder. Uma reescrita é uma chamada ao modelo, e
uma chamada ao modelo pode errar; esta errou todas as vezes, e cada erro foi direto para a busca.

Há uma versão mais barata, sem chamada nenhuma ao modelo: **achar o turno anterior mais parecido com a
mensagem nova, e pô-lo na frente para a busca**. É uma recuperação, o mesmo tipo de busca da aula 6,
sobre os turnos do próprio cliente. Ela lê os turnos da tabela que a seção depois da próxima monta,
então o `chat.py` nesse modo roda antes, em silêncio, para enchê-la:

```schooling-example
{
  "language": "python",
  "file": "recalled.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nimport memory\n\nchat, account = sys.argv[1], sys.argv[2]\nturns = [json.loads(line)[\"text\"] for line in open(f\"data/{chat}.jsonl\")]\nfor n in map(int, sys.argv[3:]):\n    print(f\"turn {n}: {turns[n - 1]}\")\n    for turn, text, score in memory.recall(account, turns[n - 1], 2, before=n):\n        print(f\"   {score:.3f}  turn {turn}: {text}\")",
      "note": "Para cada turno nomeado na linha de comando, os dois turnos anteriores do mesmo cliente que o `memory.recall` acha mais perto dele."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-a memory > /dev/null
ana@vm:~/rag$ python recalled.py chat-a A-1001 10 11 12
turn 10: How do I send back Mansfield Park?
   0.578  turn 3: The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
   0.372  turn 7: I have photographs of the damaged cover next to the box. Where do I send them?
turn 11: How long will the refund for Middlemarch take?
   0.427  turn 5: For Persuasion I would like a replacement, not a refund.
   0.682  turn 6: For Middlemarch I want my money back. I bought it somewhere else in the meantime.
turn 12: Sorry, what was my order number again? I need it for my notes.
   0.491  turn 1: Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   0.325  turn 2: The order had two books. Persuasion arrived with water damage on the cover.
```

Para cada pergunta, os dois turnos anteriores mais próximos dela. **O turno 10 recupera o turno 3**, o
livro errado, com 0,578, e **o turno 11 recupera o turno 6**, "For Middlemarch I want my money back",
com 0,682. São os turnos que uma reescrita teria usado. O segundo turno recuperado é mais fraco todas
as vezes, então o `chat.py` pega só o mais próximo, e só quando ele chega ao `LIKE`, 0,5; o melhor
casamento do turno 12, o turno 1, tem 0,491 e fica de fora, o que a seção sobre estado retoma. Um
turno recuperado que não se parece em nada com a pergunta desviaria a busca do que foi perguntado,
que é o mesmo desvio que uma reescrita descuidada causa.

O turno recuperado vai para a busca e **não para o prompt**. O modelo recebe a pergunta do cliente
como ele a escreveu. As palavras da própria Beatriz não são fonte: são o que ela disse, e não o que a
política da Marginalia diz, e uma resposta que as cita cita a cliente para ela mesma.
