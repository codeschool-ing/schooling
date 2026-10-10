---
title: Escalar a taxa junto com o lote
version: 1
---

A tabela de épocas iguais da seção anterior não foi justa com o lote grande. Ela manteve a taxa em
0,1, a taxa que serve para um lote de 32, e deu ao lote de 1.077 dez passos desse tamanho. **Tamanho
do lote e taxa de aprendizado são escolhidos juntos**, e mudar um sem o outro é o jeito mais comum de
fazer uma comparação de tamanhos de lote não dizer nada.

O argumento para escalar é curto. Multiplique o lote por *k* e uma época passa a ter *k* vezes menos
passos. Cada um desses passos faz a média de *k* vezes mais imagens, então o gradiente dele tem mais ou
menos o mesmo tamanho, só que com menos ruído. Para cobrir a mesma distância numa época com *k* vezes
menos passos, cada passo precisa ser *k* vezes mais longo. **Essa é a regra de escala linear:
multiplique o lote por *k*, multiplique a taxa por *k*.** Goyal e colegas, no Facebook, usaram-na em
2017 para treinar um classificador de imagens no ImageNet com lote de 8.192 em uma hora, com a
acurácia do lote de 256 que ele substituiu.

Salve isto como `~/dl/batch_lr.py`. Toda execução tem vinte épocas:

```schooling-example
{
  "language": "python",
  "file": "batch_lr.py",
  "parts": [
    {
      "code": "\"\"\"batch_lr: bigger batches at the same rate, and at a rate scaled with the batch.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nRUNS = [(32, 0.1), (128, 0.1), (128, 0.4), (256, 0.1), (256, 0.8), (1077, 0.1), (1077, 1.6), (1077, 3.4)]",
      "note": "Cada lote maior é testado duas vezes: na taxa que serve para um lote de 32, e nessa taxa multiplicada pelo mesmo fator do lote. 128 é quatro vezes 32, então 0,4; 256 é oito vezes, então 0,8. Para o lote inteiro, 3,4 é a regra ao pé da letra e 1,6 é metade dela."
    },
    {
      "code": "for batch, lr in RUNS:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\n    history = fit(net, SGD(net.params(), lr), train, val, epochs=20, batch_size=batch, every=21)\n    _, _, val_loss, val_acc = history[-1]\n    print(f\"batch {batch:4d}  lr {lr:3.1f}  {20 * math.ceil(len(train[1]) / batch):4d} steps  \"\n          f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")",
      "note": "Vinte épocas para todos, então toda execução vê cada imagem vinte vezes e os lotes maiores dão menos passos, e maiores."
    }
  ]
}
```

```
PENDING batch-lr
```

**Até oito vezes o lote, a regra funciona.** Com 128 e a taxa antiga, a acurácia caiu de 0,956 para
0,928; com a taxa escalada de 0,4 ela voltou para 0,958. Com 256, a taxa antiga deu 0,903 e a escalada
de 0,8 deu 0,956, com 100 passos onde o lote de 32 teve 680. As mesmas imagens, cerca de um sétimo dos
passos, e o mesmo resultado.

**No lote inteiro, ela quebra.** A regra pede 3,4, e essa execução terminou em 0,119, que é uma rede
chutando. Reduzir à metade, 1,6, deu 0,358, pior que o 0,1 sem escala. Duas coisas dão errado ao mesmo
tempo. Vinte passos são poucos para se recuperar de um passo ruim, e o argumento acima supôs que a
direção de um passo quase não muda ao longo do comprimento dele, o que deixa de ser verdade quando o
passo é tão longo. A última seção desta aula mostra o que uma taxa de 1,5 faz com uma curva.

A receita de Goyal tinha um segundo ingrediente exatamente por isso: **warm-up**, a subida de uma taxa
pequena até a taxa cheia que a aula 5 desenhou. Os primeiros passos de uma rede nova são os que um
passo longo mais estraga, e o warm-up os mantém curtos. Mesmo com ele, o artigo relata um tamanho de
lote a partir do qual a acurácia caiu, então a regra tem um teto que só se encontra rodando.

O que levar disto para a prática:

- **Quando mudar o tamanho do lote, mude a taxa** na mesma proporção, e depois confira a taxa com uma
  varredura curta em vez de confiar na regra.
- **A taxa de uma receita publicada pertence ao tamanho de lote dela.** Copiar a taxa e usar metade do
  lote, porque a sua placa de vídeo tem metade da memória, é outro experimento.
- **Compare tamanhos de lote cada um na sua melhor taxa**, ou a comparação vira uma comparação de
  taxas.
