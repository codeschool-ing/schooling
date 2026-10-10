---
title: Aumento de dados, mais dados a partir dos que você tem
version: 1
---

As outras curas contêm a rede. **O aumento de dados muda os dados**: ele cria exemplos de treino novos a
partir dos antigos, com mudanças que não podem alterar a resposta. Um 3 movido um pixel para a esquerda
continua sendo um 3, então cada imagem pode render mais quatro, movidas para cima, para baixo, para a
esquerda e para a direita, cada uma com o mesmo rótulo.

É a cura mais forte quando se aplica, porque sobreajuste é falta de exemplos e isto cria mais. Ela também
tem uma condição que não se pode pular: **a mudança precisa manter o rótulo verdadeiro.** Um deslocamento
de um pixel mantém, em dígitos de 8 por 8. Um espelhamento horizontal não manteria, porque transforma
alguns dígitos em formas que nem são dígitos, e a aula 13 mostra uma rotação transformando um 6 num 9.

Salve como `~/dl/shift.py`:

```schooling-example
{
  "language": "python",
  "file": "shift.py",
  "parts": [
    {
      "code": "\"\"\"shift: four more copies of every image, each moved by one pixel.\"\"\"\nimport numpy as np",
      "note": "Só NumPy: as imagens novas são calculadas a partir das antigas."
    },
    {
      "code": "def shifted(x, y):\n    \"\"\"The images, then all of them moved up, down, left and right.\"\"\"\n    img = x.reshape(-1, 8, 8)\n    out = [img]\n    for axis, step in ((1, -1), (1, 1), (2, -1), (2, 1)):\n        moved = np.roll(img, step, axis=axis)\n        edge = 0 if step == 1 else -1\n        if axis == 1:\n            moved[:, edge, :] = 0\n        else:\n            moved[:, :, edge] = 0\n        out.append(moved)\n    return np.concatenate(out).reshape(-1, 64), np.tile(y, 5)",
      "note": "Cada linha de 64 volta a ser 8 por 8. `np.roll` move cada imagem um pixel ao longo de um eixo, e a linha ou coluna que deu a volta para o outro lado vira zero, como se o papel continuasse em branco. Os rótulos são os mesmos cinco vezes, porque mover um dígito um pixel não muda qual dígito ele é."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n    from optim import SGD\n\n    train, val = small.data()\n    big = shifted(*train)\n    print(\"images:\", len(train[1]), \"->\", len(big[1]), \" labels\", big[1][[0, 100, 400]])\n    print(\"original  up        right\")\n    for rows in zip(*(big[0][i].reshape(8, 8) for i in (0, 100, 400))):\n        print(\"  \".join(\"\".join(\" .:#\"[int(v * 3.99)] for v in row) for row in rows))",
      "note": "A primeira imagem em três das suas cinco cópias, desenhada em caracteres: como era, movida para cima e movida para a direita. A imagem 100 é a primeira das cópias movidas para cima, e a 400 a primeira movida para a direita."
    },
    {
      "code": "    net = small.wide()\n    fit(net, SGD(net.params(), lr=0.2), big, val, epochs=300, every=50)\n    loss, acc = evaluate(net, *val)\n    print(f\"train acc {evaluate(net, *train)[1]:.3f}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "A mesma rede e as mesmas 300 épocas do `overfit.py`, com 500 imagens. A acurácia de treino no fim é medida nas 100 originais."
    }
  ]
}
```

```
PENDING shift
```

Os três desenhos são um 6, como era, movido para cima e movido para a direita. A linha de cima da cópia
movida para cima é a antiga segunda linha, e a de baixo está em branco.

**A acurácia melhora mais do que com qualquer outra coisa até aqui**: 0,928 no fim, contra 0,903, nove
imagens de validação a mais acertadas, em 360. A rede viu cada dígito em cinco posições, e o conjunto de
validação também tem dígitos desenhados um pouco fora do centro.

**A perda não melhorou.** Ela termina em 0,3724, mais alta que sem aumento, e sobe da época 50 em diante do
mesmo jeito. Com 500 imagens e 16 passos por época, 300 épocas são cinco vezes mais passos, e a rede ainda
chega a 1,000 nas imagens de treino e continua ficando mais confiante. Cinco cópias deslocadas de 100
imagens não são 500 imagens independentes: são os mesmos 100 desenhos, e uma rede deste tamanho consegue
decorar as cinco versões. O aumento moveu a acurácia; outra coisa ainda precisa parar a execução.

Aqui as 400 imagens novas foram feitas uma vez, antes do treino. Os frameworks mais comumente sorteiam uma
mudança nova a cada vez que uma imagem é usada, para que duas épocas nunca vejam exatamente o mesmo
conjunto, e a aula 10 põe uma transformação desse tipo dentro de um carregador de dados.
