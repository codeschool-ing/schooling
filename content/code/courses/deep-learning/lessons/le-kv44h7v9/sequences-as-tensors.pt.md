---
title: Sequências como tensores
version: 1
---

Tudo o que este curso deu a uma rede até aqui tinha tamanho fixo: 64 pixels, ou uma imagem de 8 por 8.
**Uma frase, uma gravação ou uma semana de leituras de um sensor não têm.** As partes vêm numa ordem que
importa, e dois exemplos do mesmo tipo podem ter qualquer comprimento. Uma avaliação de três palavras e
uma de trezentas são, as duas, avaliações.

Um lote de sequências é um tensor com três eixos: **lote, tempo, atributos**. Cada sequência é uma linha
do lote, cada passo dela é uma posição ao longo do tempo, e cada passo carrega um vetor de atributos. Um
som tem um atributo por passo, a amplitude. Uma frase é uma série de símbolos, palavras ou caracteres, e
um símbolo ainda nem é um vetor.

Salve como `~/dl/shapes.py`:

```schooling-example
{
  "language": "python",
  "file": "shapes.py",
  "parts": [
    {
      "code": "\"\"\"shapes: a batch of sequences as a tensor, and the table that turns symbols into vectors.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.manual_seed(0)\nx = torch.randint(0, 8, (4, 6))\nprint(\"symbols\", tuple(x.shape), x.dtype)\nprint(x)",
      "note": "Quatro sequências de seis símbolos cada, tiradas de um alfabeto de oito. Um símbolo é um número inteiro que dá nome a alguma coisa, uma letra, uma palavra ou um evento, e o tamanho dele não quer dizer nada: 7 não é mais que 3."
    },
    {
      "code": "embed = nn.Embedding(8, 3)\ne = embed(x)\nprint(\"embedded\", tuple(e.shape))\nprint(\"sequence 0, step 0:\", e[0, 0].detach().numpy().round(3))\nprint(\"row\", x[0, 0].item(), \"of the table:\", embed.weight[x[0, 0]].detach().numpy().round(3))",
      "note": "Um embedding é uma tabela com uma linha de números por símbolo, aqui oito linhas de três. Cada símbolo é trocado pela sua linha, e o lote ganha um último eixo: lote, tempo, atributos. As linhas são parâmetros, e o treino as move como qualquer peso."
    },
    {
      "code": "dense = nn.Linear(6 * 3, 10)\nprint(\"a dense layer on length 6:\", tuple(dense(e.reshape(4, -1)).shape))\ntry:\n    dense(embed(torch.randint(0, 8, (4, 9))).reshape(4, -1))\nexcept RuntimeError as err:\n    print(\"the same layer on length 9:\", str(err).split(\"\\n\")[0])",
      "note": "O jeito óbvio de ler uma sequência com o que as aulas 9 a 13 construíram: achatá-la e entregá-la a uma camada densa. Funciona para o comprimento 6 e falha para o 9, porque a camada tem um peso por posição e agora há mais posições que pesos."
    }
  ]
}
```

```
ana@vm:~/dl$ python shapes.py
symbols (4, 6) torch.int64
tensor([[4, 7, 5, 0, 3, 3],
        [3, 7, 1, 3, 5, 2],
        [4, 7, 6, 0, 0, 4],
        [2, 1, 6, 7, 7, 6]])
embedded (4, 6, 3)
sequence 0, step 0: [-0.23  -0.392  0.543]
row 4 of the table: [-0.23  -0.392  0.543]
a dense layer on length 6: (4, 10)
the same layer on length 9: mat1 and mat2 shapes cannot be multiplied (4x27 and 18x10)
```

Os símbolos chegam como uma tabela `(4, 6)` de números inteiros, `int64`. **O `nn.Embedding` troca cada
um por uma linha de uma tabela aprendida**: o símbolo 4 virou `[-0.23 -0.392 0.543]`, exatamente a
linha 4 de `embed.weight`, e o lote virou `(4, 6, 3)`. Esse é o formato lote, tempo, atributos que toda
camada recorrente do PyTorch lê. A aula 16 desmonta a tabela e olha o que o treino escreve nela; aqui
ela é só o passo que dá a um símbolo algo que se possa multiplicar.

**As duas últimas linhas são a razão de esta aula existir.** Uma camada densa consegue ler uma sequência
se ela for achatada, e a rede da aula 9 leria estes seis passos como 18 números. Dê a ela nove passos e o
produto falha, `4x27 and 18x10`, porque a camada tem um peso por posição e uma sequência mais longa tem
posições para as quais ela não tem pesos. Completar toda sequência até o tamanho da mais longa é um
remendo com custo: a camada aprende uma regra para o símbolo 3 na posição 2 e outra para o símbolo 3 na
posição 5, como se não tivessem nada em comum.

O que uma sequência pede é uma camada cujos pesos pertençam **ao passo**, não à posição. Ela aplica uma
regra na posição 1, de novo na posição 2, e assim até o fim, e leva o que já viu de cada passo para o
seguinte. Isso é uma rede recorrente, e a próxima seção escreve uma.
