---
title: Três memórias comparadas
version: 2
---

A memória que o `chat.py` chama de `memory` são as duas últimas seções juntas: a recuperação guia a
busca, o estado é uma fonte, os documentos são os da aula 7. Aqui está a conversa inteira da Beatriz
com ela:

```
ana@vm:~/rag$ python chat.py chat-a memory
 1   136 tokens
 2   214 tokens
 3   146 tokens
 4   143 tokens
 5   141 tokens
 6   146 tokens
 7   215 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   According to source [2], you should send the photographs of the damaged cover next to the packaging to our customer service team.
 8   153 tokens
 9   209 tokens  Do I need to send the damaged copy back to you?
   first document: 0.630  If a book arrives with a torn cover, bent ...
   According to source [2], no, you do not need to send the damaged copy back.
10   376 tokens  How do I send back Mansfield Park?
   first document: 0.590  If we sent a different title from the one ...
   To send back Mansfield Park, follow the steps outlined in [3]. 

1. Open the order in your account and choose Return items.
2. Select Mansfield Park as the book you are sending back and a reason. 
3. Print the prepaid label we email you. If you cannot print, choose QR code and show it at the post office counter instead.
4. Pack Mansfield Park so that it cannot move in the box, and drop the parcel at any post office.

Note: Since the customer's order number is MG-20481937, it's recommended to check the order details in the account to ensure the correct return process is followed.
11   324 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   According to source [2], the refund for Middlemarch will be processed within three working days of the return reaching the warehouse.
12   143 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
2346 prompt tokens over 12 turns
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Tokens de prompt em cada um dos doze turnos da conversa da Beatriz, para três memórias. O histórico inteiro sobe de 119 a 1.235 e soma 8.070. A memória fica entre 136 e 376 e soma 2.346. Cada turno sozinho é zero na maioria dos turnos, em que o piso recusa sem chamar o modelo, e soma 908.\"><path d=\"M70 260 L530 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 260 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 260 L70.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M111.81818181818181 260 L111.81818181818181 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"111.81818181818181\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M153.63636363636363 260 L153.63636363636363 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"153.63636363636363\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M195.45454545454547 260 L195.45454545454547 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"195.45454545454547\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M237.27272727272728 260 L237.27272727272728 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"237.27272727272728\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><path d=\"M279.0909090909091 260 L279.0909090909091 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"279.0909090909091\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><path d=\"M320.90909090909093 260 L320.90909090909093 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"320.90909090909093\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><path d=\"M362.72727272727275 260 L362.72727272727275 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"362.72727272727275\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><path d=\"M404.54545454545456 260 L404.54545454545456 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404.54545454545456\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><path d=\"M446.3636363636364 260 L446.3636363636364 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"446.3636363636364\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M488.1818181818182 260 L488.1818181818182 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"488.1818181818182\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><path d=\"M530.0 260 L530.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M65 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 189.2 L70 189.2\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"189.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M65 118.5 L70 118.5\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"118.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><path d=\"M65 47.7 L70 47.7\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"47.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.200</text><text x=\"300.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">turno da conversa</text><text x=\"70\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens de prompt mandados naquele turno</text><path d=\"M70.0 238.9 L111.8 207.1 L153.6 196.7 L195.5 190.5 L237.3 184.6 L279.1 157.9 L320.9 139.0 L362.7 130.1 L404.5 78.7 L446.4 79.7 L488.2 41.5 L530.0 47.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"238.9\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"111.8\" cy=\"207.1\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"153.6\" cy=\"196.7\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"195.5\" cy=\"190.5\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"237.3\" cy=\"184.6\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"279.1\" cy=\"157.9\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"320.9\" cy=\"139.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"362.7\" cy=\"130.1\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"404.5\" cy=\"78.7\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"446.4\" cy=\"79.7\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"488.2\" cy=\"41.5\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"530.0\" cy=\"47.5\" r=\"3\" fill=\"var(--amber)\"></circle><path d=\"M70.0 235.9 L111.8 222.1 L153.6 234.2 L195.5 234.7 L237.3 235.1 L279.1 234.2 L320.9 222.0 L362.7 232.9 L404.5 223.0 L446.4 193.5 L488.2 202.7 L530.0 234.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"235.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"111.8\" cy=\"222.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"153.6\" cy=\"234.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"195.5\" cy=\"234.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"237.3\" cy=\"235.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"279.1\" cy=\"234.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"320.9\" cy=\"222.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"362.7\" cy=\"232.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"404.5\" cy=\"223.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"446.4\" cy=\"193.5\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"488.2\" cy=\"202.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"530.0\" cy=\"234.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><path d=\"M70.0 260.0 L111.8 227.3 L153.6 260.0 L195.5 260.0 L237.3 260.0 L279.1 260.0 L320.9 227.1 L362.7 260.0 L404.5 217.2 L446.4 260.0 L488.2 207.8 L530.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"111.8\" cy=\"227.3\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"153.6\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"195.5\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"237.3\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"279.1\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"320.9\" cy=\"227.1\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"362.7\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"404.5\" cy=\"217.2\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"446.4\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"488.2\" cy=\"207.8\" r=\"3\" fill=\"var(--paper-dim)\"></circle><circle cx=\"530.0\" cy=\"260.0\" r=\"3\" fill=\"var(--paper-dim)\"></circle><rect x=\"556\" y=\"54\" width=\"14\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"576\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">histórico inteiro, 8.070</text><rect x=\"556\" y=\"80\" width=\"14\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"576\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">memória, 2.346</text><rect x=\"556\" y=\"106\" width=\"14\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"576\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cada turno sozinho, 908</text></svg>", "caption": "O histórico inteiro cresce a cada turno, porque todo turno anterior é mandado de novo; a memória fica estável, porque o que vai é um estado de duas frases e os documentos deste turno. Cada turno sozinho é o mais barato e recusa as perguntas que precisavam do passado."}
```

**2.346 tokens para os doze turnos, contra 8.070 do histórico inteiro**, e o prompt não cresce mais: é
o estado, os documentos deste turno e a pergunta, aconteça o que tiver acontecido antes.

As respostas, turno a turno:

- **O turno 7** manda enviar as fotos para a equipe de atendimento, sem endereço inventado: a resposta
  ficou dentro das fontes.
- **O turno 10** agora busca com o turno 3 na frente, e **o primeiro documento é o certo**: "If we sent
  a different title from the one you ordered, tell us within 14 days", com 0,590, onde a pergunta
  sozinha não achava nada acima do piso. A resposta percorre os passos de devolução do *Mansfield
  Park*, citados, e acrescenta uma nota com o número do pedido tirado do estado.
- **O turno 11** recupera o turno 6, acha a seção de reembolsos, e responde: três dias úteis depois que
  a devolução chega ao armazém, para o *Middlemarch*. Sozinho, a mesma seção foi achada e recusada.
- **O turno 12** é recusado, como a seção anterior mostrou, com o número do pedido no estado.

Então a memória mais barata de mandar também respondeu mais: duas das três perguntas que precisavam do
passado, onde o histórico inteiro respondeu uma. Não é coincidência desta conversa: o histórico inteiro
manda tudo para o caso de importar, e a memória manda o que foi escolhido porque importa. É o argumento
da aula 12 de novo, aplicado ao passado em vez dos documentos. A pergunta que ela perdeu é a que nunca
deveria ter sido do modelo.

A medida que decidiria isso para uma implantação é a da aula 8, estendida a conversas: um conjunto de
chats com a pergunta no fim e o fato que a resposta precisa conter, rodado com cada memória contra o
modelo real. Dois chats são uma demonstração, não esse teste.
