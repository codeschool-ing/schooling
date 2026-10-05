---
title: Quando o normal se move
version: 1
---

Um detector é uma descrição do normal congelada no dia em que foi construído. Na segunda semana da
história do curso a Marginalia lança uma assinatura, a **Marginalia Unlimited**, e a caixa de
entrada muda. `data/week2.jsonl` tem vinte mensagens daquela semana, a maioria sobre a assinatura.

Nenhuma delas é spam. São clientes, perguntando sobre algo de que a referência nunca ouviu falar.
Pontuá-las uma a uma, como fez a seção anterior, responde à pergunta errada; o olhar útil é o do
**lote**.

```schooling-example
{
  "language": "python",
  "file": "drift.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]\nweek2 = [json.loads(l) for l in open(\"data/week2.jsonl\")]\nref = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"train\"])\nheld = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"test\"])\nbest = lambda Q, R: (Q @ R.T).max(axis=1)\ncut = np.percentile(1 - best(held, ref), 95)",
      "note": "A referência e o limite da seção anterior: k=1, no percentil 95 dos chamados separados."
    },
    {
      "code": "def batch(name, B):\n    S = B @ B.T\n    np.fill_diagonal(S, -1)\n    score = 1 - best(B, ref)\n    inside = (S.max(axis=1) > best(B, ref)).sum()\n    print(f\"{name}: {len(B)} messages, mean score {score.mean():.3f}, \"\n          f\"flagged {(score > cut).sum()}, nearest neighbour in the batch {inside}\")\n    return score\n\nbatch(\"inbox (normal)\", embed([m[\"text\"] for m in inbox if not m[\"odd\"]]))\nW = embed([w[\"text\"] for w in week2])\ns = batch(\"week 2\", W)",
      "note": "Três números por lote: a nota média, quantas mensagens passam do limite e quantas têm o vizinho mais próximo dentro do lote, e não entre os chamados antigos."
    },
    {
      "code": "for i in np.argsort(-s)[:7]:\n    print(f\"   {s[i]:.3f}  {'*' if s[i] > cut else ' '} {week2[i]['id']}  {week2[i]['text'][:52]}\")",
      "note": "As sete mensagens da semana 2 mais longe do normal, com estrela quando passam do limite."
    },
    {
      "code": "for name, R in ((\"before\", ref), (\"after adding w01-w10\", np.vstack([ref, W[:10]]))):\n    s = 1 - best(W[10:], R)\n    print(f\"w11-w20 {name}: flagged {(s > cut).sum()}, mean score {s.mean():.3f}\")",
      "note": "Refaça a base: junte as dez primeiras mensagens da semana 2 à referência e pontue as outras dez de novo."
    }
  ]
}
```

```
ana@lab:~/emb$ python drift.py
inbox (normal): 32 messages, mean score 0.357, flagged 0, nearest neighbour in the batch 1
week 2: 20 messages, mean score 0.461, flagged 4, nearest neighbour in the batch 11
   0.810  * w19  Upgrade from monthly to yearly, how?
   0.682  * w10  How much is the annual subscription compared to mont
   0.617  * w13  Can I pause my subscription while I'm travelling?
   0.600  * w16  Is there a student discount on the subscription?
   0.554    w01  How do I cancel my Marginalia Unlimited subscription
   0.537    w03  Which books are included in the Unlimited subscripti
   0.536    w05  Can I share my Unlimited plan with my family?
w11-w20 before: flagged 3, mean score 0.450
w11-w20 after adding w01-w10: flagged 0, mean score 0.368
```

## O que o lote mostra e uma mensagem sozinha não

**Só quatro das vinte passam do corte**, e as quatro são sobre a assinatura: passar do mensal para
o anual, comparar preços, pausar, desconto de estudante. A mensagem sobre cancelar a Unlimited fica
com 0,554, logo abaixo da linha em 0,560, e as duas seguintes, sobre o que a
Unlimited inclui e se ela pode ser compartilhada, vêm logo atrás.
Mensagem por mensagem, o assunto novo quase todo passa.

Os números do lote não deixam passar. Contra as mensagens normais da primeira caixa de entrada:

| | caixa de entrada (normais) | semana 2 |
|---|---|---|
| nota média | 0,357 | 0,461 |
| marcadas | 0 | 4 |
| vizinho mais próximo no mesmo lote | 1 de 32 | 11 de 20 |

A média subiu, o que diz que o lote como um todo se afastou da referência. A última linha é o sinal
mais forte. Na primeira caixa de entrada, só uma mensagem normal estava mais perto de outra mensagem
da caixa do que de qualquer chamado antigo. Na semana 2, **onze de vinte** estavam: as mensagens
sobre a assinatura ficam mais perto umas das outras. Um grupo de mensagens novas que se parecem
mais entre si do que com qualquer coisa conhecida é a cara de um **assunto novo**, e não de um
punhado de esquisitices sem relação.

Isso se chama **deriva** (*drift*): os dados que um sistema vê se afastam dos dados sobre os quais
ele foi construído. Não é uma anomalia em nenhuma mensagem, e marcar essas mensagens uma a uma,
todo dia, mandaria vinte clientes legítimos por semana para uma fila de revisão.

## O que fazer

Duas coisas, e as duas são decisões de uma pessoa.

**Acrescentar o assunto.** Se a loja encaminha chamados por categoria, assinaturas agora são uma
sexta categoria, e o classificador da aula 4 precisa de exemplos rotulados dela.

**Refazer a base.** Acrescente exemplos do novo normal à referência. As duas últimas linhas da saída
juntam as dez primeiras mensagens da semana 2 e pontuam as outras dez de novo: as marcadas caem de
3 para 0 e a média de 0,450 para 0,368.

Refazer a base tem seu próprio custo. Tudo o que entra na referência deixa de ser marcado, que foi
o que o spam plantado fez com k=1 duas seções atrás. Então acrescente mensagens que alguém leu, não
tudo o que chegou, e continue de olho nos números do lote. Uma nota média que sobe semana após
semana é o sinal de que a referência precisa de outra olhada.
