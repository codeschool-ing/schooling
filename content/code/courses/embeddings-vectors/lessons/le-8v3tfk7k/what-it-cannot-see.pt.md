---
title: O que ele não enxerga
version: 1
---

Um detector de embeddings mede uma coisa: quão longe o **assunto** de uma mensagem está dos
assuntos das mensagens normais. A aula 1 mostrou que um embedding captura aquilo de que um texto
trata muito melhor do que aquilo que ele afirma, e esse limite passa direto para as anomalias. Uma
mensagem pode ser perigosa e estar perfeitamente dentro do assunto.

```schooling-example
{
  "language": "python",
  "file": "blind.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\nref = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"train\"])\nheld = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"test\"])\nbest = lambda Q, R: (Q @ R.T).max(axis=1)\ncut = np.percentile(1 - best(held, ref), 95)",
      "note": "A referência e o corte da seção sobre limiares: k=1 contra os 100 chamados de treino, no percentil 95 dos 50 separados."
    },
    {
      "code": "messages = [\n    \"Please refund the 4,800 I paid for order 1182, the book never came.\",\n    \"Change the email on my account to a new address and send the password there.\",\n    \"I want to return all 40 copies of the same novel I bought yesterday.\",\n    \"Meu pedido ainda não chegou e já faz duas semanas, alguém pode me ajudar?\",\n    \"My order still hasn't arrived and it has been two weeks, can somebody help me?\",\n]\nfor text, s in zip(messages, 1 - best(embed(messages), ref)):\n    print(f\"{s:.3f}  {'flag' if s > cut else 'pass'}  {text[:60]}\")",
      "note": "Cinco mensagens escritas para esta seção. Três são perigosas e parecem comuns; as duas últimas são uma mesma reclamação em português e em inglês."
    }
  ]
}
```

```
ana@lab:~/emb$ python blind.py
0.347  pass  Please refund the 4,800 I paid for order 1182, the book neve
0.313  pass  Change the email on my account to a new address and send the
0.317  pass  I want to return all 40 copies of the same novel I bought ye
0.760  flag  Meu pedido ainda não chegou e já faz duas semanas, alguém po
0.334  pass  My order still hasn't arrived and it has been two weeks, can
```

## Perigosas e com cara de normais

As três primeiras mensagens passam, com notas bem abaixo do corte em 0,560.

- Um pedido de reembolso de 4.800 por um pedido que provavelmente é pequeno é um pedido de
  reembolso. O valor é o que o torna suspeito, e um embedding não compara valores.
- Um pedido para trocar o e-mail da conta e mandar a senha para lá é uma pergunta de conta, e
  também é como alguém toma uma conta que não é sua.
- Quarenta exemplares de um mesmo romance devolvidos no dia seguinte à compra são uma devolução. Se
  é fraude depende de quem pede e do que comprou, e isso não está no texto.

As três são anomalias de **conteúdo dentro de um assunto normal**, e pedem verificações que leiam o
conteúdo: regras sobre valores, o histórico de pedidos, o registro da própria conta e uma pessoa. O
detector daqui é um filtro para mensagens que tratam do assunto errado. Não é um sistema
antifraude, e descrevê-lo como tal seria o erro mais caro que esta aula poderia deixar para trás.

## Marcada pelos motivos do modelo

As duas últimas linhas são uma mesma reclamação: um pedido que não chegou depois de duas semanas.
Em inglês fica com 0,334 e passa. Em português fica com 0,760 e é marcada, mais que o dobro da
distância até o normal.

A mensagem não é estranha. O **modelo** é: o all-MiniLM-L6-v2 foi treinado em inglês, e a aula 1
mediu uma frase e a tradução dela em português em −0,015. O curso marcou essa mensagem como
estranha porque para a referência só em inglês desta loja ela é, e o detector concorda pelo mesmo
motivo. Um modelo multilíngue, que a aula 9 ensina a reconhecer, a poria ao lado dos chamados de
entrega e a deixaria passar. Se o que você precisa é saber em que língua está uma mensagem, um
detector de idioma responde isso de forma direta e confiável; um embedding responde por acidente.

## Onde ele vale o que custa

Juntas, as medições da aula dizem para que serve esse tipo de detector:

| pega | deixa passar ou lê errado |
|---|---|
| mensagens sobre o assunto errado: spam, receitas, candidaturas a emprego | uma mensagem com cara de normal e o valor, a conta ou a intenção errados |
| teclado batido a esmo | um assunto novo que chega aos poucos, até você olhar o lote |
| texto que o modelo não sabe ler, como outras línguas para um modelo inglês | a diferença entre uma língua estrangeira e um assunto estranho |

Ele é barato, não precisa de exemplos do que procura e continua funcionando quando o spam da semana
que vem é diferente do desta. Esses são os motivos para usá-lo, na frente de uma pessoa e ao lado
das verificações que leem o que uma mensagem diz.
