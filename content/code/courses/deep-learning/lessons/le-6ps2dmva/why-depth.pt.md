---
title: Duas camadas resolvem o XOR
version: 1
---

O perceptron não aprendia o XOR porque uma unidade desenha uma reta. **Duas camadas o calculam, porque
a segunda combina retas que a primeira desenhou.** Aqui todo peso é escrito à mão, para que o que cada
unidade faz possa ser lido no programa. Salve como `~/dl/xor.py`:

```schooling-example
{
  "language": "python",
  "file": "xor.py",
  "parts": [
    {
      "code": "\"\"\"xor: two layers, every weight set by hand, computing what one unit cannot.\"\"\"\nimport numpy as np\n\nX = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])\nstep = lambda z: (z > 0).astype(int)",
      "note": "As mesmas quatro entradas de `perceptron.py`, e a mesma função degrau, aplicada a cada elemento de um array."
    },
    {
      "code": "W1 = np.array([[1, 1],      # unit 1 fires for \"x1 OR x2\"\n               [1, 1]])     # unit 2 fires for \"x1 AND x2\"\nb1 = np.array([-0.5, -1.5])",
      "note": "A camada oculta. As duas unidades somam as duas entradas; os vieses decidem quanto basta. Mais de 0,5 quer dizer que pelo menos uma entrada está ligada, e mais de 1,5 quer dizer que as duas estão."
    },
    {
      "code": "W2 = np.array([1, -2])      # OR, minus twice AND\nb2 = -0.5",
      "note": "A unidade de saída lê as duas ocultas. OR ligado dá +1; AND ligado tira 2. Acima de 0,5 quer dizer OR sem AND, que é o XOR."
    },
    {
      "code": "h = step(X @ W1 + b1)\nout = step(h @ W2 + b2)\nfor x, hidden, o in zip(X, h, out):\n    print(x, \"-> hidden\", hidden, \"-> output\", o)"
    }
  ]
}
```

```
ana@vm:~/dl$ python xor.py
[0 0] -> hidden [0 0] -> output 0
[0 1] -> hidden [1 0] -> output 1
[1 0] -> hidden [1 0] -> output 1
[1 1] -> hidden [1 1] -> output 0
```

Leia a coluna `hidden`. A unidade 1 responde *pelo menos uma entrada está ligada*, que é o OR; a
unidade 2 responde *as duas estão*, que é o AND. Nenhuma das duas é o XOR. A unidade de saída pega o
OR e tira duas vezes o AND, e dispara em `[0 1]` e `[1 0]`: exatamente os dois casos em que o OR está
ligado e o AND desligado.

**É isso que a profundidade compra.** A primeira camada
transformou as entradas em características que tornam o problema fácil, e a última desenhou uma reta
através dessas características. Com 64 pixels em vez de dois bits, as unidades ocultas de uma rede
treinada passam a responder perguntas como *há um traço atravessando o topo* ou *a parte de baixo é
fechada*, e a saída desenha a sua reta através dessas respostas.

Três limites do que isto mostra:

- Os pesos foram escritos, não aprendidos. Um programa que os encontre a partir dos quatro
  exemplos precisa de uma medida de quão errada a rede está (aula 2) e de um jeito de dividir a culpa
  entre as camadas (aula 3).
- O degrau só funciona aqui porque nada precisa ser treinado. A próxima aula o troca por uma
  função cuja inclinação existe.
- Duas camadas bastam, em princípio, para muito mais que o XOR. O teorema da aproximação universal
  diz que uma única camada oculta com unidades suficientes aproxima qualquer função contínua. Ele não
  diz quantas unidades isso exige nem se o treinamento as encontra, e na prática redes mais profundas,
  com menos unidades por camada, aprendem a mesma coisa com muito menos parâmetros.
