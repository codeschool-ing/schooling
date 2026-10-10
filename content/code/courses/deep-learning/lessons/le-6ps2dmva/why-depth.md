---
title: Two layers solve XOR
version: 1
---

The perceptron could not learn XOR because one unit draws one line. **Two layers can compute it,
because the second layer combines lines the first one drew.** Here every weight is set by hand, so
that what each unit does can be read off the program. Save as `~/dl/xor.py`:

```schooling-example
{
  "language": "python",
  "file": "xor.py",
  "parts": [
    {
      "code": "\"\"\"xor: two layers, every weight set by hand, computing what one unit cannot.\"\"\"\nimport numpy as np\n\nX = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])\nstep = lambda z: (z > 0).astype(int)",
      "note": "The same four inputs as `perceptron.py`, and the same step function, applied to every element of an array."
    },
    {
      "code": "W1 = np.array([[1, 1],      # unit 1 fires for \"x1 OR x2\"\n               [1, 1]])     # unit 2 fires for \"x1 AND x2\"\nb1 = np.array([-0.5, -1.5])",
      "note": "The hidden layer. Both units add the two inputs; the biases decide how much is enough. More than 0.5 means at least one input is on, and more than 1.5 means both are."
    },
    {
      "code": "W2 = np.array([1, -2])      # OR, minus twice AND\nb2 = -0.5",
      "note": "The output unit reads the two hidden ones. OR switched on gives +1; AND switched on takes 2 away. Above 0.5 means OR without AND, which is XOR."
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

Read the hidden column. Unit 1 answers *at least one input is on*, which is OR; unit 2 answers *both
are*, which is AND. Neither is XOR. The output unit takes OR and subtracts twice AND, and fires on
`[0 1]` and `[1 0]`: exactly the two cases where OR is on and AND is off.

**This is what depth buys, and it is the whole idea of the course in miniature.** The first layer
turned the inputs into features that make the problem easy, and the last layer drew one straight line
through those features. With 64 pixels instead of two bits, the hidden units of a trained network
come to answer questions like *is there a stroke across the top* or *is the bottom closed*, and the
output draws its line through those answers.

Three honest limits on what this shows:

- **The weights were written, not learnt.** A program that finds them from the four examples needs
  a measure of how wrong the network is (lesson 2) and a way to share the blame among layers
  (lesson 3).
- **The step function only works here because nothing has to be trained.** The next lesson replaces
  it with a function whose slope exists.
- **Two layers are enough in principle for much more than XOR.** The universal approximation theorem
  says a single hidden layer with enough units can approximate any continuous function. It says
  nothing about how many units that takes or whether training finds them, and in practice deeper
  networks with fewer units per layer learn the same thing with far fewer parameters.
