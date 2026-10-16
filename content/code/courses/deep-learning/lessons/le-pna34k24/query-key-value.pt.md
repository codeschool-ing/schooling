---
title: "Consulta, chave e valor: uma busca que pode ser treinada"
version: 1
---

A atenção costuma ser explicada com a imagem de uma pessoa lendo uma frase e se concentrando nas
palavras que importam. **O que ela calcula é mais simples que isso: uma busca em dicionário, feita
suave.** Um dicionário do Python recebe uma chave, acha a única entrada que bate exatamente com ela e
devolve o valor dessa entrada. A atenção recebe uma consulta, dá uma nota a ela contra cada chave e
devolve uma mistura de todos os valores, ponderada pelo quanto cada chave combinou.

Os nomes vêm dessa imagem. A **consulta** (*query*) é o que um token procura, a **chave** (*key*) é o
que um token oferece para ser encontrado, e o **valor** (*value*) é o que ele entrega quando é
encontrado. O programa abaixo faz a busca dos dois jeitos em quatro entradas, com chaves e valores
escritos à mão. Salve como `~/dl/qkv.py`:

```schooling-example
{
  "language": "python",
  "file": "qkv.py",
  "parts": [
    {
      "code": "\"\"\"qkv: a dictionary lookup, made soft, and the three projections that feed it.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.set_printoptions(precision=3, sci_mode=False)\nkeys = torch.tensor([[1., 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])\nvalues = torch.tensor([[10.], [20.], [30.], [40.]])\nquery = torch.tensor([0., 0.9, 0.3, 0.])\nprint(\"hard lookup:\", values[(keys @ query).argmax()].item())",
      "note": "Quatro chaves, cada uma apontando para uma direção própria, e um valor para cada. A consulta pende mais para a segunda chave e um pouco para a terceira. Um dicionário pegaria a melhor correspondência e devolveria o valor dela, 20, e nada mais."
    },
    {
      "code": "scores = keys @ query\nweights = torch.softmax(scores, dim=0)\nprint(\"scores \", scores)\nprint(\"weights\", weights, \" sum\", round(weights.sum().item(), 3))\nprint(\"soft lookup:\", round((weights @ values).item(), 2))",
      "note": "A versão suave dá nota a toda chave pelo produto escalar com a consulta, transforma as notas em pesos com uma softmax e devolve a soma ponderada de todos os valores."
    },
    {
      "code": "for sharpness in (1, 5, 20):\n    w = torch.softmax(sharpness * scores, dim=0)\n    print(f\"scores x{sharpness:<2d}  weights {w}  result {(w @ values).item():.2f}\")",
      "note": "As mesmas notas multiplicadas por 5 e por 20 antes da softmax. Notas maiores deixam os pesos mais desiguais, e a busca suave escorrega em direção à rígida."
    },
    {
      "code": "q = query.clone().requires_grad_()\n(torch.softmax(keys @ q, dim=0) @ values).sum().backward()\nprint(\"gradient of the soft lookup with respect to the query:\", q.grad)",
      "note": "A busca suave tem gradiente em relação à consulta, então o treino pode mover a consulta em direção à chave que ela deveria ter encontrado. A rígida não tem: o `argmax` devolve um índice."
    },
    {
      "code": "torch.manual_seed(0)\ntokens = torch.randn(4, 16)\nto_q, to_k, to_v = nn.Linear(16, 16), nn.Linear(16, 16), nn.Linear(16, 16)\nq, k, v = to_q(tokens), to_k(tokens), to_v(tokens)\nprint(\"tokens\", tuple(tokens.shape), \" q\", tuple(q.shape), \" k\", tuple(k.shape), \" v\", tuple(v.shape))",
      "note": "Numa rede ninguém escreve as chaves. O vetor de cada token passa por três camadas aprendidas, uma que faz a consulta, uma a chave e uma o valor. Aqui os quatro tokens são vetores aleatórios de 16; a aula 16 trata de onde vêm os de verdade."
    }
  ]
}
```

```
ana@vm:~/dl$ python qkv.py
hard lookup: 20.0
scores  tensor([0.000, 0.900, 0.300, 0.000])
weights tensor([0.172, 0.423, 0.232, 0.172])  sum 1.0
soft lookup: 24.04
scores x1   weights tensor([0.172, 0.423, 0.232, 0.172])  result 24.04
scores x5   weights tensor([0.010, 0.933, 0.046, 0.010])  result 20.57
scores x20  weights tensor([0.000, 1.000, 0.000, 0.000])  result 20.00
gradient of the soft lookup with respect to the query: tensor([-2.418, -1.713,  1.384,  2.746])
tokens (4, 16)  q (4, 16)  k (4, 16)  v (4, 16)
```

**A busca rígida devolveu 20 e a suave, 24,04.** A consulta teve nota 0,9 contra a segunda chave e 0,3
contra a terceira, e a softmax transformou as quatro notas em pesos de 0,172, 0,423, 0,232 e 0,172, que
somam 1. O resultado é esses pesos vezes 10, 20, 30 e 40: quase todo o segundo valor,
puxado um pouco para baixo pelo primeiro e mais para cima pelo terceiro e pelo quarto. O primeiro e o
quarto não combinaram com nada e ainda assim receberam 0,172 cada. Uma softmax de notas finitas nunca dá um peso exatamente 0.

**O tamanho das notas decide o quanto a busca é rígida.** Multiplicadas por 5, as mesmas notas puseram
0,933 na segunda chave e o resultado caiu para 20,57. Multiplicadas por 20, os pesos saíram 1,000 numa chave e 0,000
nas outras, e a busca suave devolveu 20,00, a resposta da rígida. A próxima seção mostra que
essa escala depende da largura dos vetores, e por que é preciso corrigi-la.

Por que não usar a busca rígida, então? **Porque ela não pode ser treinada.** O gradiente da busca suave
em relação à consulta é `[-2.418, -1.713, 1.384, 2.746]`: ele diz que mover a consulta em direção à
terceira e à quarta chaves aumentaria o resultado, e quanto. O `argmax` devolve uma posição, e uma
pequena mudança na consulta não muda nada até o vencedor pular de uma chave para outra. A
retropropagação, assunto da aula 3, precisa de uma inclinação, e só a versão suave tem uma. É assim que
uma rede aprende para onde olhar.

Numa rede de verdade ninguém escreve as chaves. Cada token chega como um vetor, e **três camadas lineares
aprendidas transformam o mesmo vetor numa consulta, numa chave e num valor**: três vetores diferentes,
porque o que um token procura não é o mesmo que ele oferece. As últimas linhas fizeram isso para quatro
tokens aleatórios de 16 números, e cada um de `q`, `k` e `v` saiu `(4, 16)`, uma linha por token. Num
modelo, essas linhas vêm de um embedding: a aula 16 trata de como um símbolo vira um vetor, e aqui o
`nn.Embedding` basta, como na aula 14.
