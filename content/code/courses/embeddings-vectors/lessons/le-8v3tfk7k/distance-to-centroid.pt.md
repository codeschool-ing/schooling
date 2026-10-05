---
title: Distância ao centroide
version: 1
---

A descrição mais simples de uma região é o seu centro. Tire a média dos vetores dos 150 chamados
num único **centroide** e dê a cada mensagem da caixa de entrada uma nota pelo quanto ela aponta
para longe dele. A nota é um menos o cosseno, de modo que 0 significa *igual ao chamado médio* e a nota
cresce conforme a mensagem se afasta.

```schooling-example
{
  "language": "python",
  "file": "centroid.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]\nN = embed([t[\"text\"] for t in tickets])\nX = embed([m[\"text\"] for m in inbox])",
      "note": "Transforme em vetor cada chamado, que é toda a descrição do normal, e cada mensagem da caixa de entrada."
    },
    {
      "code": "c = N.mean(axis=0)\nprint(\"length of the mean:\", round(float(np.linalg.norm(c)), 3))\nc /= np.linalg.norm(c)",
      "note": "A média de 150 vetores de comprimento 1 é mais curta que 1, então divida-a pelo comprimento para voltar a ter uma direção."
    },
    {
      "code": "score = 1 - X @ c\norder = np.argsort(-score)\nfor r, i in enumerate(order, 1):\n    m = inbox[i]\n    if r <= 10 or m[\"odd\"]:\n        print(f\"{r:2}  {score[i]:.3f}  {m['id']}  {'ODD' if m['odd'] else '   '}  {m['text'][:44]}\")",
      "note": "A nota é um menos o cosseno com essa direção: 0 é apontar exatamente para o normal, quanto maior, mais longe. Imprima as dez mais altas, e cada mensagem estranha onde quer que tenha caído."
    }
  ]
}
```

```
ana@lab:~/emb$ python centroid.py
length of the mean: 0.425
 1  1.026  m35  ODD  What is the boiling point of water at the to
 2  0.941  m34  ODD  Meu pedido ainda não chegou e já faz duas se
 3  0.923  m40  ODD  Je n'arrive pas à me connecter à mon compte 
 4  0.910  m38  ODD  Can you recommend a good recipe for vegetabl
 5  0.895  m39  ODD  Increase your website traffic by 500% with o
 6  0.791  m36  ODD  asdf qwer zxcv 12345 lkjh
 7  0.740  m37  ODD  Dear hiring manager, please find attached my
 8  0.724  m21       The font in the reading app is impossible to
 9  0.695  m22       How long does shipping to Argentina take?
10  0.692  m20       Two-factor codes from my app are always reje
16  0.642  m33  ODD  Congratulations!!! You have been selected to
```

**Sete das oito mensagens estranhas ocupam os sete primeiros lugares**, e a pergunta do Everest
vem em primeiro com nota acima de 1, o que quer dizer que o cosseno dela com o chamado médio é
levemente negativo. É um bom começo para tão pouco código.

A oitava é o problema. **O spam do iPhone grátis, m33, fica em 16º**, abaixo de oito mensagens
comuns sobre fontes, entrega para a Argentina e códigos de dois fatores. Um detector ajustado para
marcar as oito primeiras deixaria o spam passar e marcaria no lugar dele a reclamação sobre a fonte
do aplicativo de leitura.

## Por que um único centro deixa passar

A primeira linha da saída dá a pista. A média de 150 vetores de comprimento 1 tem comprimento
0,425. Vetores que apontassem todos para o mesmo lado teriam média de comprimento 1; estes ficam
bem abaixo da metade, porque apontam em cinco direções diferentes, uma por tipo de chamado. O
centroide é um ponto **entre** os cinco grupos, onde nenhum chamado de verdade mora.

A distância até esse ponto mede quão longe uma mensagem está da média dos cinco assuntos, e isso
não é o mesmo que quão longe ela está de cada um deles. Uma mensagem normal que fica na borda de um
grupo, como *The font in the reading app is impossible to change* ("é impossível mudar a fonte no
aplicativo de leitura"), fica longe do meio mesmo sendo um chamado de e-book perfeitamente comum. E
uma mensagem que pega um pouco de vocabulário de vários grupos pode ficar mais perto do meio do que
merece. O spam parece um caso desses: fala em receber algo e reivindicar um prêmio, e em
`forced.py` teve nota 0,321 contra o centroide de devoluções, mais do que qualquer outra mensagem
estranha contra qualquer rótulo.

Um único centroide funciona quando o normal é **um** grupo compacto: um tipo de linha de log, as
avaliações de um produto. O normal da Marginalia são cinco grupos, e a próxima seção mede contra os
próprios grupos.
