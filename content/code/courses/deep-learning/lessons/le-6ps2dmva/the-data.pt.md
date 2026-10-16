---
title: Os dígitos com que este curso treina
version: 1
---

**A maior parte deste curso treina com 1.797 dígitos manuscritos, cada um uma grade de 8 por 8 tons
de cinza.** Eles foram publicados em 1998 e vêm dentro do scikit-learn, e é por isso que a montagem
não precisou de download e que a sua cópia é a mesma que as transcrições usaram.

Oito por oito é pouco. Os famosos dígitos do MNIST têm 28 por 28, e uma foto de celular tem milhões
de pixels. É esse tamanho pequeno que torna o curso possível num processador: uma rede aprende estas
imagens em segundos, então um experimento que muda uma configuração custa um minuto em vez de uma
noite, e o efeito da configuração é o que você observa.

## A divisão, escrita uma vez

Toda aula que treina lê os dados por um único módulo. Salve-o como `~/dl/digits.py`:

```schooling-example
{
  "language": "python",
  "file": "digits.py",
  "parts": [
    {
      "code": "\"\"\"digits: the 1,797 handwritten digits that ship inside scikit-learn, split three ways.\"\"\"\nimport numpy as np\nfrom sklearn.datasets import load_digits",
      "note": "Os dados estão dentro do pacote scikit-learn que você instalou: nada é baixado, e toda máquina recebe as mesmas 1.797 imagens."
    },
    {
      "code": "def load(seed=0):\n    \"\"\"Train, validation and test sets: each image a row of 64 numbers in [0, 1], each label 0 to 9.\"\"\"\n    d = load_digits()\n    x = (d.data / 16.0).astype(np.float32)\n    y = d.target.astype(np.int64)",
      "note": "Cada imagem tem 8 por 8 pixels, com um nível de tinta de 0 a 16. Dividir por 16 põe toda entrada entre 0 e 1, e `float32` é a precisão em que redes treinam."
    },
    {
      "code": "    order = np.random.default_rng(seed).permutation(len(y))\n    x, y = x[order], y[order]\n    return (x[:1077], y[:1077]), (x[1077:1437], y[1077:1437]), (x[1437:], y[1437:])",
      "note": "Um embaralhamento com semente fixa, depois 60% para treinar, 20% para validar e 20% guardados para um teste final, a divisão que `machine-learning` ensinou. A mesma semente dá a mesma divisão em qualquer máquina."
    }
  ]
}
```

**O conjunto de teste não serve para escolher nada.** `machine-learning` já disse isso, e aqui vale
com mais força: uma rede tem dezenas de configurações, e cada uma escolhida olhando um conjunto vaza
um pouco desse conjunto para o modelo. A validação é onde as configurações são escolhidas. O teste é
olhado quando elas estão prontas.

## Olhando para eles

Salve isto como `~/dl/look.py` e rode:

```schooling-example
{
  "language": "python",
  "file": "look.py",
  "parts": [
    {
      "code": "\"\"\"look: the data, its split, and one digit drawn in characters.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x_train, y_train), (x_val, y_val), (x_test, y_test) = digits.load()\nprint(\"train\", x_train.shape, \"val\", x_val.shape, \"test\", x_test.shape)\nprint(\"labels in train:\", np.bincount(y_train))",
      "note": "`bincount` conta quantos rótulos de cada tipo existem. Um conjunto em que um dígito fosse raro pediria outra métrica, e este é quase uniforme."
    },
    {
      "code": "print(\"label of the first image:\", y_train[0])\nfor row in x_train[0].reshape(8, 8):\n    print(\"\".join(\" .:-=+*#@\"[int(v * 8)] for v in row))",
      "note": "Os 64 números voltam a ser uma grade de 8 por 8, e cada nível de tinta vira um de nove caracteres, do branco ao `@`."
    }
  ]
}
```

```
ana@vm:~/dl$ python look.py
train (1077, 64) val (360, 64) test (360, 64)
labels in train: [106 109  92 117 104 110 102 121 109 107]
label of the first image: 6
   *-   
  -#.   
  *:    
  @.    
 .@+**. 
 .@+:=* 
  *+:*+ 
   *@+. 
```

1.077 imagens para treinar, 360 para validar e 360 para testar, com cada dígito aparecendo entre 92 e
121 vezes no treino. A primeira imagem de treino tem o rótulo 6, e o desenho mostra por que uma pessoa
concordaria: um traço descendo pela esquerda e uma volta embaixo.

**Para uma rede, esse 6 são os 64 números e mais nada.** Ela não sabe que eles eram uma grade. A aula
11 dá a ela um jeito de usar o fato de que pixels vizinhos andam juntos; até lá, a figura foi
achatada numa linha, e uma rede que aprende a partir de uma linha tem de aprender do zero que o pixel
9 fica embaixo do pixel 1.
