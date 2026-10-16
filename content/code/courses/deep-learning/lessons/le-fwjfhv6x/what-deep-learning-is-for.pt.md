---
title: Para que serve o deep learning
version: 1
---

Depois de três seções em que a rede perdeu, a pergunta oposta merece o mesmo cuidado: **onde uma rede
vence, e por que ali?** A resposta está no que uma coluna significa. Numa tabela, uma coluna é um
atributo que alguém escolheu, e significa a mesma coisa em toda linha. Numa imagem, o pixel 27 é
tinta num dígito e fundo no seguinte, e o que importa é o arranjo de muitos pixels, onde quer que ele
esteja. Alguém precisa transformar esse arranjo em atributos. **Uma rede aprende esses atributos
sozinha**, e esse é o trabalho que uma árvore sobre pixels crus não consegue fazer.

Os dígitos são um teste pequeno disso, porque com 8 por 8 eles são quase uma tabela: 64 números,
poucos o bastante para o boosting tratar cada pixel como uma coluna. O programa abaixo treina a
regressão logística, o boosting e a CNN da aula 11 uma vez, nos dígitos como são, e depois pergunta
aos três sobre os dígitos de validação deslocados um pixel para cada lado. Ele precisa do `cnn.py`,
do `tdigits.py`, do `loop.py` e do `digits.py` que o `small.py` usou. Salve como `~/dl/moved.py`:

```schooling-example
{
  "language": "python",
  "file": "moved.py",
  "parts": [
    {
      "code": "\"\"\"moved: three models trained on the digits, then shown the same validation digits moved by one pixel.\"\"\"\nimport torch\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.linear_model import LogisticRegression\nfrom threadpoolctl import threadpool_limits\n\nimport cnn\nimport loop\nimport tdigits\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)\n\n(x, y), (vx, vy), _ = tdigits.load()"
    },
    {
      "code": "def move(images, right):\n    \"\"\"Every 8x8 image shifted `right` pixels sideways, the column that comes in left blank.\"\"\"\n    grid = images.reshape(-1, 8, 8)\n    out = torch.zeros_like(grid)\n    if right > 0:\n        out[:, :, right:] = grid[:, :, :-right]\n    elif right < 0:\n        out[:, :, :right] = grid[:, :, -right:]\n    else:\n        out = grid\n    return out.reshape(-1, 64)",
      "note": "O mesmo dígito, uma coluna para a direita ou para a esquerda. Uma pessoa o lê exatamente como antes; para um modelo que aprendeu um peso ou um corte por pixel, todo número de entrada mudou."
    },
    {
      "code": "logistic = LogisticRegression(max_iter=5000).fit(x.numpy(), y.numpy())\nboosting = HistGradientBoostingClassifier(random_state=0).fit(x.numpy(), y.numpy())\ntorch.manual_seed(0)\nnet = cnn.make_cnn()\nloop.fit(net, torch.optim.SGD(net.parameters(), lr=0.1), (x.reshape(-1, 1, 8, 8), y),\n         (vx.reshape(-1, 1, 8, 8), vy), epochs=30, every=10**9)",
      "note": "Os três são treinados uma vez, nos dígitos como eles são. A CNN com a receita da aula 11, então é a rede da aula 11 de novo."
    },
    {
      "code": "for right in (0, 1, -1):\n    v = move(vx, right)\n    print(f\"moved {right:+d}:  logistic {logistic.score(v.numpy(), vy.numpy()):.3f}  \"\n          f\"boosting {boosting.score(v.numpy(), vy.numpy()):.3f}  \"\n          f\"CNN {loop.evaluate(net, v.reshape(-1, 1, 8, 8), vy)[1]:.3f}\")",
      "note": "Nada é treinado de novo: os mesmos três modelos são consultados sobre os dígitos de validação no lugar, depois deslocados um pixel para cada lado."
    }
  ]
}
```

```
ana@vm:~/dl$ python moved.py
moved +0:  logistic 0.967  boosting 0.978  CNN 0.978
moved +1:  logistic 0.381  boosting 0.425  CNN 0.706
moved -1:  logistic 0.400  boosting 0.442  CNN 0.683
```

**Nos dígitos no lugar, o boosting empata com a CNN em 0,978.** Em imagens tão pequenas, a rede não
tem vantagem a mostrar. Deslocar os dígitos em um pixel muda isso por completo. A regressão logística
cai para 0,381 e 0,400, o boosting para 0,425 e 0,442, e a CNN mantém 0,706 e 0,683.

Os dois modelos tabulares aprenderam um peso ou um corte por posição de pixel, então para eles um
dígito deslocado é outra tabela. Os filtros da CNN são os mesmos nove pesos em todo lugar (aula 11),
então um traço que ela aprendeu a achar na coluna 3 é achado na coluna 4 também, e o pooling perdoa
um pouco mais. **Isso é um atributo aprendido da estrutura da entrada, não de uma coluna**, e é por
isso que ela caiu menos. Ela caiu, sim: uma camada de pooling não é invariância completa, e o
aumento de dados da aula 7, mostrando dígitos deslocados no treino, é o caminho de sempre para
fechar o resto.

Aumente a escala e você tem o argumento a favor do deep learning. Uma fotografia são 150.528 números,
um segundo de áudio são dezenas de milhares, uma frase é uma sequência de tokens (aula 16), e em
nenhum deles um número cru isolado significa algo em que uma árvore possa cortar. **Onde os atributos
precisam ser aprendidos a partir de entradas cruas e estruturadas, as redes não têm rival sério**, e
as pré-treinadas (aulas 13 e 17) levam isso também a problemas com poucos dados.

Os dois se encontram com frequência. Uma tabela com uma coluna de texto livre ou uma foto por linha é comum. Um arranjo sensato deixa uma
rede transformar o texto ou a foto num vetor de números, um embedding, e entrega isso ao boosting
como mais colunas ao lado das outras. Cada modelo faz então
aquilo em que é bom.
