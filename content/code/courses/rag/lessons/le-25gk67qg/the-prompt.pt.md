---
title: O prompt
version: 1
---

A aula 1 montou o menor prompt possível: seções numeradas e a pergunta, sob uma instrução de uma linha.
Isso bastava para mostrar a ideia. Um prompt que uma equipe poria na frente de clientes diz mais, e cada
linha acrescentada está ali para tornar uma falha menos provável. O `answer.py` é esse prompt e o código
em volta dele:

```schooling-example
{
  "language": "python",
  "file": "answer.py",
  "parts": [
    {
      "code": "import re\nimport sys\n\nfrom openai import OpenAI\nfrom search import conn, vector\n\nSYSTEM = \"\"\"You answer questions from Marginalia's customers, using only the numbered sources.\nCite every sentence with the number of the source it comes from, like [1].\nIf the sources do not answer the question, reply: \"I could not find that in our documents.\"\nIf two sources disagree, prefer the one updated most recently, and say so.\"\"\"\nFLOOR = 0.5\nREFUSAL = \"I could not find that in our documents.\"\nclient = OpenAI()",
      "note": "As instruções, na mensagem de sistema. Cada linha pede um comportamento que esta aula depois confere: responder pelas fontes, citar cada frase, dizer quando as fontes se calam, e preferir a mais nova de duas fontes que discordam. `FLOOR` é a nota que a aula 6 escolheu."
    },
    {
      "code": "def sources_for(question, k=3, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"The chunks worth showing the model: filtered, and above the floor lesson 6 chose.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "A busca da aula 6, filtrada para documentos públicos em vigor, com o que fica abaixo do piso descartado. A data e a versão do documento de cada pedaço também vêm da tabela, porque o prompt as mostra."
    },
    {
      "code": "def prompt(question, sources):\n    blocks = [f\"[{n}] {s['path']} (updated {s['updated']})\\n{s['text']}\" for n, s in enumerate(sources, 1)]\n    return \"\\n\\n\".join(blocks + [f\"Question: {question}\"])",
      "note": "Cada fonte ganha um número, o caminho de títulos e a data numa linha, e o texto embaixo. A pergunta vem por último."
    }
  ]
}
```

## O que o modelo recebe

O `show_prompt.py` imprime exatamente o que o `ask` manda para uma pergunta, a mensagem de sistema e
depois a mensagem do usuário:

```
ana@lab:~/rag$ python show_prompt.py "How long after my return arrives will I get the refund?"
You answer questions from Marginalia's customers, using only the numbered sources.
Cite every sentence with the number of the source it comes from, like [1].
If the sources do not answer the question, reply: "I could not find that in our documents."
If two sources disagree, prefer the one updated most recently, and say so.
---
[1] Returns and refunds policy > Refunds (updated 2026-02-02)
We refund within three working days of the return reaching our warehouse. The money goes back to
the card or account you paid with, and your bank may take another five to ten days to show it.
Delivery costs are refunded when you return the whole order; when you return part of it, they are
not.

[2] Returns and refunds policy > The return window (updated 2026-02-02)
You have 30 days from delivery to return a printed book in the condition you received it. The 30
days start on the day the carrier records the parcel as delivered, not on the day you placed the
order. For an order that arrived in several parcels, each parcel has its own 30 days.

[3] Returns and refunds policy > Items sold by marketplace sellers (updated 2026-02-02)
Items marked Sold by, followed by a seller's name, are returned to the seller and not to us. Every
seller must accept returns for at least 14 days from delivery, and many accept them for longer. The
seller's own policy is on their page. If a seller does not answer a return request within two
working days, open a claim from the order and we decide it.

Question: How long after my return arrives will I get the refund?
```

Três fontes passaram pelo filtro e pelo piso, todas do regulamento de devoluções atual. Só a primeira
tem a resposta; as outras duas marcaram mais de 0,5 e falam de devoluções em geral. A aula 12 trata do
que fazer com fontes assim. Esta aula as aceita como vêm.

## Por que cada parte está ali

**As fontes são numeradas**, para que uma frase possa apontar para uma e um programa possa seguir o
ponteiro. Um número é melhor que um título para isso, porque um título pode conter qualquer caractere e
um modelo reproduz um número curto com exatidão.

**Cada fonte leva o caminho e a data.** O caminho diz ao modelo, e a quem ler uma citação depois, de que
documento e de que seção um trecho vem. A data é o que torna a quarta instrução possível: um modelo não
consegue preferir a mais nova de duas fontes que ele não consegue datar.

**A pergunta vem por último.** Instruções e fontes primeiro, pergunta no fim, para que a última coisa que
o modelo lê antes de escrever seja o que lhe perguntaram. A aula 12 volta ao posicionamento.

**As instruções são poucas e verificáveis.** Quatro linhas, cada uma descrevendo um comportamento que esta
aula depois testa: as respostas vêm das fontes, toda frase é citada, o silêncio é admitido, e conflitos
são resolvidos pela data. Uma instrução que ninguém confere é um desejo.

## O que o extract-1 faz com ele

Das quatro instruções, o extract-1 segue duas por construção: ele só copia frases das fontes, e cita
cada uma. Segue a terceira só em parte, porque a recusa dele vem do próprio limiar de similaridade,
embora use a frase de recusa que o prompt lhe dá. Ignora a quarta por completo; não tem noção de data.
Um modelo real lê as quatro e as segue na maior parte das vezes, que é uma afirmação diferente de
sempre. O resto desta aula trata do código que confere.
