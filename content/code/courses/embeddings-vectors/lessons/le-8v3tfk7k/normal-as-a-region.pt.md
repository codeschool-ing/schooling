---
title: O normal como uma região
version: 1
---

Toda manhã a caixa de entrada do suporte da Marginalia tem um dia de mensagens de clientes, e a
maioria trata das cinco coisas em que a aula 4 separou os chamados: entrega, devoluções,
pagamentos, contas e e-books. Algumas não tratam de nada que a loja faz. Um sorteio de prêmios, uma
candidatura a emprego, uma pergunta sobre lasanha, uma linha de teclado batido a esmo. A Ana quer
achar essas antes que alguém gaste tempo encaminhando.

A cópia que o curso tem de um desses dias é `data/inbox.jsonl`, e o curso marcou quais mensagens
não se encaixam, do mesmo jeito que a aula 3 marcou qual artigo responde a qual pergunta:

```
ana@lab:~/emb$ wc -l data/tickets.jsonl data/inbox.jsonl
  150 data/tickets.jsonl
   40 data/inbox.jsonl
  190 total
ana@lab:~/emb$ grep -c "\"odd\": true" data/inbox.jsonl
8
```

## Um classificador sempre responde

A primeira ideia é reaproveitar o classificador da aula 4 e deixar as mensagens estranhas caírem
para fora dele. Elas não caem, porque **um classificador não tem resposta para "nenhuma destas"**.
Ele foi feito para escolher entre cinco rótulos, e escolhe, seja lá o que receber:

```schooling-example
{
  "language": "python",
  "file": "forced.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]",
      "note": "Leia os 150 chamados rotulados e as 40 mensagens do dia na caixa de entrada."
    },
    {
      "code": "labels = sorted({t[\"label\"] for t in tickets})\nV = embed([t[\"text\"] for t in tickets])\nC = np.array([V[[t[\"label\"] == l for t in tickets]].mean(axis=0) for l in labels])\nC /= np.linalg.norm(C, axis=1, keepdims=True)",
      "note": "O classificador por centroide mais próximo da aula 4: um vetor médio por rótulo, normalizado de volta para comprimento 1."
    },
    {
      "code": "odd = [m for m in inbox if m[\"odd\"]]\nfor m, row in zip(odd, embed([m[\"text\"] for m in odd]) @ C.T):\n    j = row.argmax()\n    print(f\"{m['id']}  {labels[j]:9} {row[j]:.3f}  {m['text'][:44]}\")",
      "note": "Entregue cada uma das oito mensagens estranhas ao mais próximo dos cinco centroides e imprima o rótulo que ganhou, com a nota."
    }
  ]
}
```

```
ana@lab:~/emb$ python forced.py
m33  returns   0.321  Congratulations!!! You have been selected to
m34  ebooks    0.097  Meu pedido ainda não chegou e já faz duas se
m35  account   0.034  What is the boiling point of water at the to
m36  account   0.207  asdf qwer zxcv 12345 lkjh
m37  shipping  0.273  Dear hiring manager, please find attached my
m38  returns   0.100  Can you recommend a good recipe for vegetabl
m39  payments  0.112  Increase your website traffic by 500% with o
m40  shipping  0.091  Je n'arrive pas à me connecter à mon compte 
```

A pergunta sobre o ponto de ebulição da água no alto do Everest foi para `account`, com nota
0,034, que é quase nada. A candidatura a emprego foi para `shipping`. As notas são baixas, e um
leitor cuidadoso poderia pôr um corte nelas. Só que esse corte já é outro método disfarçado: ele
pergunta quão longe uma mensagem está do que o classificador conhece, que é a pergunta que esta
aula faz diretamente.

## Descreva o normal e meça a distância até ele

As mensagens estranhas não têm nada em comum entre si. Spam, francês, ruído e um currículo não
formam uma categoria, e as estranhas da semana que vem serão outras, então não há com que treinar
um sexto rótulo. O que a loja tem é muito **normal**: 150 chamados que são exatamente o tipo de
mensagem para o qual a caixa de entrada existe.

Por isso a detecção de anomalias com embeddings inverte a pergunta. Transforme as mensagens normais
em vetores e elas ocupam uma **região** do espaço, a parte onde vivem entrega, devoluções,
pagamentos, contas e e-books. Transforme uma mensagem nova e pergunte quão longe ela está dessa
região. Uma mensagem sobre um pacote atrasado cai dentro dela; uma pergunta de receita cai num
lugar onde os chamados nunca foram.

Isso pede duas decisões, e o resto da aula trata de cada uma:

1. Como medir a distância até uma região. A próxima seção tenta a resposta óbvia, a distância
   até o centro da região, e a seguinte tenta a distância até as mensagens normais mais próximas.
2. Onde cortar. Uma distância ordena as mensagens; ela não diz quais marcar. A seção sobre
   limiares lê o corte em dados normais.

O campo `odd` ("estranha") não entra em nada disso. Um detector que precisasse dele precisaria que
alguém rotulasse cada mensagem antes, que é justamente o trabalho que ele existe para poupar. Ele
está lá para **medir** o detector depois, do mesmo jeito que a aula 4 deixou os 50 chamados de
teste fora do treino.
