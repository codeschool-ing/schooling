---
title: "Adam: um tamanho de passo para cada parâmetro"
version: 1
---

A imagem com que a maioria começa é uma taxa de aprendizado para a rede inteira. A taxa é um número
só, mas **o passo que cada peso dá é a taxa vezes o seu próprio gradiente**, e os gradientes dentro de
uma rede diferem em ordens de grandeza, entre camadas e entre os pesos de uma camada. Uma taxa boa
para os grandes mal mexe os pequenos, e uma taxa boa para os pequenos joga os grandes de um lado
para o outro.

O Adam, publicado por Kingma e Ba em 2014, responde a isso dividindo o gradiente de cada parâmetro
por uma medida corrida do tamanho dos gradientes daquele parâmetro. Ele guarda duas médias por
parâmetro: `m`, do gradiente, que é a velocidade do momentum em outra forma, e `v`, do gradiente ao
quadrado. O programa abaixo dá os cinco primeiros passos em três parâmetros inventados. Salve como
`~/dl/adam_steps.py`:

```schooling-example
{
  "language": "python",
  "file": "adam_steps.py",
  "parts": [
    {
      "code": "\"\"\"adam_steps: Adam's first steps on three parameters with very different gradients.\"\"\"\nimport numpy as np\n\nlr, b1, b2, eps = 0.001, 0.9, 0.999, 1e-8\nm, v = np.zeros(3), np.zeros(3)\nnp.set_printoptions(precision=6, suppress=True)",
      "note": "As configurações do Adam como quase todo mundo as deixa: taxa de 0,001, `beta1` de 0,9 para a média do gradiente, `beta2` de 0,999 para a média do quadrado dele. As duas médias começam em zero."
    },
    {
      "code": "def gradient(t):\n    \"\"\"A large steady gradient, a small steady one, and a small one that flips sign.\"\"\"\n    return np.array([100.0, 0.01, 0.01 * (-1) ** (t + 1)])",
      "note": "Três parâmetros, inventados para que cada um mostre uma coisa: um gradiente de 100 a cada passo, um de 0,01 a cada passo, e um de 0,01 cujo sinal se inverte a cada vez."
    },
    {
      "code": "print(\"plain SGD at the same rate steps\", lr * gradient(1))\nfor t in range(1, 6):\n    g = gradient(t)\n    m = b1 * m + (1 - b1) * g\n    v = b2 * v + (1 - b2) * g * g",
      "note": "`m` acompanha o gradiente e `v` acompanha o quadrado dele, cada um uma média corrida que guarda a maior parte do valor antigo. Toda operação é elemento a elemento, então cada parâmetro tem um `m` e um `v` só seus."
    },
    {
      "code": "    m_hat = m / (1 - b1 ** t)\n    v_hat = v / (1 - b2 ** t)\n    step = lr * m_hat / (np.sqrt(v_hat) + eps)\n    uncorrected = lr * m / (np.sqrt(v) + eps)\n    print(f\"step {t}: Adam {step}   uncorrected {uncorrected}\")",
      "note": "A correção divide cada média por quanto dela já foi preenchido: `1 - 0.9 ** 1` dá 0,1 depois de um passo. O passo é o gradiente médio dividido pela raiz do quadrado médio, então o tamanho dele deixa de depender do tamanho do gradiente."
    }
  ]
}
```

```
ana@vm:~/dl$ python adam_steps.py
plain SGD at the same rate steps [0.1     0.00001 0.00001]
step 1: Adam [0.001 0.001 0.001]   uncorrected [0.003162 0.003162 0.003162]
step 2: Adam [ 0.001     0.001    -0.000053]   uncorrected [ 0.00425   0.004249 -0.000224]
step 3: Adam [0.001    0.001    0.000336]   uncorrected [0.00495  0.00495  0.001662]
step 4: Adam [ 0.001     0.001    -0.000053]   uncorrected [ 0.005442  0.005442 -0.000286]
step 5: Adam [0.001    0.001    0.000204]   uncorrected [0.005797 0.005797 0.001185]
```

Três coisas nessa tabela.

**A escala sumiu.** O SGD simples com a mesma taxa moveria o primeiro parâmetro em 0,1 e o segundo
em 0,00001, dez mil vezes menos. O Adam move os dois em 0,001, que é a própria taxa. Para um gradiente
que mantém o sinal, `m_hat` dividido pela raiz de `v_hat` dá 1, então no Adam **a taxa é mais ou menos
o tamanho de um passo**, medido nas unidades do próprio parâmetro. É por isso que um padrão só, 0,001,
é uma primeira tentativa razoável em redes que não têm mais nada em comum.

**Um gradiente que muda de ideia o tempo todo ganha passos pequenos.** O gradiente do terceiro
parâmetro é do tamanho do segundo, mas o sinal dele se inverte. Em `m` o mais e o menos quase se
cancelam, enquanto `v` faz a média de quadrados e não pode cancelar, e depois do primeiro passo, que
só viu um gradiente, os passos saem em 0,000053, 0,000336, 0,000053 e 0,000204: uma fração da taxa,
em direções alternadas.

**A correção importa no começo, e no sentido que pouca gente adivinha.** `m` e `v` começam em zero,
então depois do primeiro passo `m` guarda um décimo do gradiente e `v` um milésimo do quadrado dele.
O milésimo é a fração menor, e a raiz dele é cerca de 0,0316, então a razão sem correção é 0,1 /
0,0316: o primeiro passo é 0,003162, mais de três vezes a taxa. No passo 5 ele está em 0,005797,
quase seis. Sem a correção os primeiros passos do Adam são grandes demais, no momento em que uma
rede nova está menos pronta para passos grandes. Dividir `m` por `1 - 0.9 ** t` e `v` por
`1 - 0.999 ** t` traz os dois de volta à escala, e os passos são 0,001 desde o primeiro.

**O Adam é momentum mais uma escala para cada parâmetro**, e é a primeira escolha de costume hoje
porque é o que precisa de menos ajuste para funcionar. Menos não é nenhum: a varredura duas seções à
frente mostra a taxa dele importando tanto quanto a de qualquer outro. O AdamW, a variante por trás da
maioria dos modelos grandes, muda só o jeito de aplicar o decaimento de pesos, que é assunto da aula 7.
