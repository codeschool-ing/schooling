---
title: Entropia cruzada: menos o log da resposta certa
version: 1
---

A última camada de um classificador produz **logits**: uma pontuação por classe, números reais
quaisquer, sem promessa de que somem coisa alguma. **A entropia cruzada os transforma num número só, em
dois passos. O softmax os torna probabilidades, e a perda é menos o log da probabilidade dada à classe
certa.** As probabilidades das outras classes nem aparecem na perda. A mesma coisa também se chama log
loss e log-verossimilhança negativa.

Salve como `~/dl/xent.py`:

```schooling-example
{
  "language": "python",
  "file": "xent.py",
  "parts": [
    {
      "code": "\"\"\"xent: softmax, then minus the log of the right class, on four predictions.\"\"\"\nimport numpy as np\n\n\ndef softmax(z):\n    e = np.exp(z - z.max())\n    return e / e.sum()",
      "note": "O softmax transforma qualquer lista de números em probabilidades: exponencia, depois divide pelo total. Subtrair o maior antes não muda nada na resposta, e a seção depois da próxima diz por que ele está ali."
    },
    {
      "code": "cases = {                          # three classes; the right answer is class 0 every time\n    \"confident, right\": [4.0, 0.0, 0.0],\n    \"unsure\":           [0.5, 0.3, 0.0],\n    \"unsure, wrong\":    [0.0, 0.5, 0.3],\n    \"confident, wrong\": [0.0, 4.0, 0.0],\n}",
      "note": "Quatro conjuntos de logits, as pontuações cruas que a última camada de uma rede produz. A resposta certa é a classe 0 nos quatro; o que muda é quanto a rede acredita nela."
    },
    {
      "code": "for name, logits in cases.items():\n    p = softmax(np.array(logits))\n    loss = -np.log(p[0])\n    grad = p - np.array([1.0, 0.0, 0.0])\n    print(f\"{name:17s} p {np.round(p, 3)}  loss {loss:6.3f}  gradient {np.round(grad, 3)}\")",
      "note": "A perda olha só para a probabilidade da classe certa. O gradiente em relação aos logits é a probabilidade menos o alvo one-hot, o mesmo `p - 1` que o `tinynet.softmax_cross_entropy` calcula."
    },
    {
      "code": "print(\"ten classes, all equal: loss\", round(float(-np.log(softmax(np.zeros(10))[0])), 3))",
      "note": "Uma rede que não sabe nada dá 0,1 a cada um dos dez dígitos. A perda dela é o número a esperar antes do primeiro passo de treinamento."
    }
  ],
  "output": "ana@vm:~/dl$ python xent.py\nconfident, right  p [0.965 0.018 0.018]  loss  0.036  gradient [-0.035  0.018  0.018]\nunsure            p [0.412 0.338 0.25 ]  loss  0.886  gradient [-0.588  0.338  0.25 ]\nunsure, wrong     p [0.25  0.412 0.338]  loss  1.386  gradient [-0.75   0.412  0.338]\nconfident, wrong  p [0.018 0.965 0.018]  loss  4.036  gradient [-0.982  0.965  0.018]\nten classes, all equal: loss 2.303"
}
```

Leia a coluna `loss` de cima para baixo. Confiante e certo custa 0,036. Inseguro, com a classe certa
mal à frente com 0,412, custa 0,886. Inseguro e errado custa 1,386. Confiante e errado custa 4,036,
mais de cem vezes a primeira linha. É o log que faz isso: quando a probabilidade da classe certa cai
para perto de zero, menos o log dela sobe sem limite, então **uma resposta errada e confiante é a coisa
mais cara que um classificador pode fazer**, e nada limita quanto ela custa.

**A coluna do gradiente é o motivo de usar esta perda.** Na classe certa ele vale `p - 1`: -0,035
quando a rede já acertava, -0,982 quando errava com confiança. A correção cresce com o erro e não some
quando o erro piora, que é a propriedade que falta a um erro quadrático sobre as probabilidades; a
seção *MSE num classificador* mede quanto isso custa. Cada classe errada recebe de volta a
probabilidade que tomou, como um empurrão para baixo, então na última linha a classe 1, que tomou
0,965, é a mais empurrada.

**A última linha é um número para saber de cor.** Uma rede que dá 0,1 a cada uma de dez classes tem
perda 2,303, que é o logaritmo natural de 10. É o que um classificador dos dígitos deve relatar antes
de aprender qualquer coisa. Uma primeira perda muito acima disso quer dizer que a rede, ainda sem
treino, já erra com confiança, e os logits iniciais dela são grandes demais.
