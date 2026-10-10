---
title: O que uma augmentation precisa preservar
version: 1
---

A leitura tentadora da seção anterior é que mais variedade é sempre melhor: girar os dígitos por
qualquer ângulo, espelhá-los, e a rede vê mais do mundo. **Uma augmentation é uma afirmação de que a
mudança não altera o rótulo, e para algumas mudanças em algumas imagens a afirmação é falsa.** Um 6
de cabeça para baixo é um 9. Um 2 espelhado da esquerda para a direita não é o 2 de caligrafia
nenhuma.

Dá para medir isso antes de qualquer treino com augmentation, perguntando a uma rede que nunca viu um
dígito girado ou espelhado o que ela acha deles. Salve como `~/dl/preserve.py`:

```schooling-example
{
  "language": "python",
  "file": "preserve.py",
  "parts": [
    {
      "code": "\"\"\"preserve: a trained CNN reads flipped and turned digits.\"\"\"\nimport torch\nfrom torchvision.transforms import v2\n\nimport cnn\nimport loop\nimport tdigits\n\ntrain, (x, y), _ = tdigits.load(images=True)\ntorch.manual_seed(0)\nmodel = cnn.make_cnn()\nloop.fit(model, torch.optim.Adam(model.parameters(), lr=1e-3), train, (x, y), epochs=20, every=20)\nmodel.eval()",
      "note": "A CNN da aula 11, treinada nos dez dígitos sem augmentation nenhuma. `x` e `y` são o conjunto de validação, que é o que o resto do programa lê."
    },
    {
      "code": "def predict(images):\n    with torch.no_grad():\n        return model(images).argmax(dim=1)\n\n\nviews = {\"as drawn\": x, \"mirrored\": v2.functional.horizontal_flip(x),\n         \"upside down\": v2.functional.rotate(x, 180)}",
      "note": "As formas funcionais das transformações aplicam uma mudança fixa, sem nada de aleatório, ao conjunto inteiro: o espelho da esquerda para a direita, e meia volta."
    },
    {
      "code": "print(\"digit \" + \"\".join(f\"{name:>13}\" for name in views))\nfor d in range(10):\n    keep = y == d\n    row = [(predict(v[keep]) == d).float().mean().item() for v in views.values()]\n    print(f\"{d:5d} \" + \"\".join(f\"{a:13.2f}\" for a in row))",
      "note": "Para cada dígito, a fração das imagens de validação que a rede ainda chama pelo próprio rótulo, em cada uma das três versões."
    },
    {
      "code": "for d in (6, 9):\n    guesses = predict(views[\"upside down\"][y == d])\n    print(f\"{d}s turned upside down are read as:\", torch.bincount(guesses, minlength=10).tolist())",
      "note": "Para onde foram os 6 e os 9 de cabeça para baixo: uma contagem por resposta, de 0 a 9."
    }
  ]
}
```

```
PENDING preserve
```

A primeira coluna é a rede nas imagens como foram desenhadas, entre 0,92 e 1,00 para todo dígito. As
outras duas são as mesmas imagens mudadas, e **o que sobrevive é exatamente o que uma pessoa
preveria pelas formas**. O 0 e o 8 são simétricos nos dois sentidos e mantêm 0,94 e 0,91
espelhados, 0,91 e 0,89 de cabeça para baixo. O 3, o 6 e o 2 têm direção, e caem para 0,00, 0,00 e
0,11 quando espelhados.

As duas últimas linhas são a armadilha na forma mais simples. **Dos 6 de cabeça para baixo, 40
foram lidos como 9**. Os 9 de cabeça para baixo se espalharam mais, com 18 lidos como 6, mas nenhum
foi lido como 9. Se o treino tivesse usado uma rotação de até 180 graus, cada uma dessas imagens
teria entrado na perda com o rótulo antigo, e a rede teria aprendido que uma forma é ao mesmo tempo
um 6 e um 9.

## A regra, e onde ela cede

Escolha uma augmentation perguntando se uma pessoa ainda daria à imagem o mesmo rótulo depois dela.
Para estes dígitos, pequenos giros e deslocamentos passam, e giros grandes e espelhamento não passam.
A resposta pertence à tarefa, não à transformação:

| imagens | um espelhamento horizontal | uma rotação grande |
| --- | --- | --- |
| dígitos e letras manuscritos | muda o rótulo | muda o rótulo |
| fotos de animais ou carros | mantém | raramente certo: o mundo tem um lado de cima |
| imagens de satélite ou de microscópio | mantém | mantém: não existe lado de cima |
| placas de trânsito com setas | transforma uma seta para a esquerda numa para a direita | muda o rótulo |

Uma mudança também pode respeitar o rótulo e ainda assim quebrar algo de que a tarefa precisa. Um
recorte que corta fora o objeto, uma mudança de cor numa tarefa sobre maturação, ou um desfoque
quando a resposta está no detalhe fino mantêm o rótulo escrito e removem a evidência dele.
