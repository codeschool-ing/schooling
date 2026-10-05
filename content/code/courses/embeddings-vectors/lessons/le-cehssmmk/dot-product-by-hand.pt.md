---
title: O produto escalar, à mão
version: 1
---

A aula 1 deu notas aos artigos com `D @ q` e leu o resultado como *mais alto é mais perto*. Essa
operação é o **produto escalar**, e ela é pequena o bastante para fazer no papel. Pegue dois
vetores de três números:

| | primeiro | segundo | terceiro |
|---|---|---|---|
| a | 2 | 1 | 2 |
| b | 1 | 2 | 2 |
| a × b | 2 | 2 | 4 |

Multiplique coordenada por coordenada e some os produtos: 2 + 2 + 4 = **8**. A definição é só
isso. Para dois vetores do all-MiniLM-L6-v2 são 384 multiplicações e uma soma comprida.

```schooling-example
{
  "language": "python",
  "file": "dot.py",
  "parts": [
    {
      "code": "import numpy as np\n\na = np.array([2, 1, 2])\nb = np.array([1, 2, 2])",
      "note": "Os dois vetores da tabela, como arrays do NumPy."
    },
    {
      "code": "print(a * b)\nprint((a * b).sum())\nprint(a @ b)",
      "note": "Os produtos coordenada por coordenada, a soma deles e a mesma soma escrita com `@`, que é como o resto do curso escreve."
    },
    {
      "code": "print((2 * a) @ b)",
      "note": "O mesmo produto escalar com `a` dobrado."
    }
  ]
}
```

```
ana@lab:~/emb$ python dot.py
[2 2 4]
8
8
16
```

A soma é grande quando os dois vetores têm valores grandes **nas mesmas coordenadas e com o mesmo
sinal**. Uma coordenada em que um vetor é positivo e o outro negativo desconta da soma. Então o
produto escalar premia duas setas que se inclinam para o mesmo lado, que é o que uma nota de
significado precisa.

## A armadilha: o comprimento também conta

A última linha dobrou `a` e mais nada. A direção não mudou, então ele se inclina para `b` tanto
quanto antes, e a nota foi de 8 para **16**. Cada coordenada dobrou, então cada produto dobrou,
então a soma dobrou.

**O produto escalar mistura duas coisas: o quanto duas setas se alinham e o quanto elas são
compridas.** Um documento cujo vetor por acaso é comprido ganha de um documento mais bem alinhado
cujo vetor é curto. No all-MiniLM-L6-v2 o problema nunca aparece, porque todo vetor que ele devolve
tem comprimento 1 e o produto escalar fica medindo só o alinhamento. Nem todo modelo faz isso, e a
seção *Vetores que não estão normalizados* encontra um que não faz e põe o artigo errado em
primeiro. A próxima seção tira o comprimento da nota.
