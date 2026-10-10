---
title: Large logits, nan, and log-sum-exp
version: 1
---

On paper, softmax is the exponential of each logit divided by the sum of the exponentials.
**Typed exactly as written, that formula fails on numbers a network really produces.** A logit is
an unbounded score, and the exponential of a large one does not fit in a float.

Save as `~/dl/stable.py`. It uses the `tinynet.py` from lesson 3:

```schooling-example
{
  "language": "python",
  "file": "stable.py",
  "parts": [
    {
      "code": "\"\"\"stable: one cross-entropy computed three ways, on logits a network can produce.\"\"\"\nimport numpy as np\n\nfrom tinynet import softmax_cross_entropy\n\n\ndef naive(logits, y):\n    p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n    return -np.log(p[np.arange(len(y)), y]).mean()",
      "note": "The formula exactly as it is written on paper. `np.exp(1000)` is far beyond the largest float, so it becomes infinity, and infinity divided by infinity is `nan`."
    },
    {
      "code": "def log_sum_exp(logits, y):\n    z = logits - logits.max(axis=1, keepdims=True)\n    return (np.log(np.exp(z).sum(axis=1)) - z[np.arange(len(y)), y]).mean()",
      "note": "The loss without ever forming a probability. Minus the log of a softmax is the log of the sum of exponentials minus the right logit, and after the shift the largest exponential is `exp(0) = 1`, so the sum is at least 1 and its log is never minus infinity."
    },
    {
      "code": "print(\"largest float32\", np.finfo(np.float32).max, \"= exp of\", np.log(np.finfo(np.float32).max))\ny = np.array([0])                                                # class 0 is right in both\nlarge = np.array([[1000.0, 998.0, 990.0]], dtype=np.float32)\nfar_wrong = np.array([[0.0, 120.0, 0.0]], dtype=np.float32)\nfor name, logits in ((\"large\", large), (\"far wrong\", far_wrong)):\n    loss, grad = softmax_cross_entropy(logits, y)\n    print(f\"{name:9s}  naive {naive(logits, y):.4f}   tinynet {loss:.4f}\"\n          f\"   log-sum-exp {log_sum_exp(logits, y):.4f}   tinynet's gradient {np.round(grad[0], 3)}\")",
      "note": "First the ceiling: the largest number `float32` can hold, and the logit whose exponential reaches it. Then two cases in `float32`, the precision the network trains in: large logits close together, and a network that gives the wrong class 120 more than the right one."
    }
  ],
  "output": "ana@vm:~/dl$ python stable.py\n/home/ana/dl/stable.py:8: RuntimeWarning: overflow encountered in exp\n  p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n/home/ana/dl/stable.py:8: RuntimeWarning: invalid value encountered in divide\n  p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n/home/ana/dl/tinynet.py:66: RuntimeWarning: divide by zero encountered in log\n  loss = -np.log(p[rows, y]).mean()\n/home/ana/dl/stable.py:9: RuntimeWarning: divide by zero encountered in log\n  return -np.log(p[np.arange(len(y)), y]).mean()\nlargest float32 3.4028235e+38 = exp of 88.72284\nlarge      naive nan   tinynet 0.1270   log-sum-exp 0.1270   tinynet's gradient [-0.119  0.119  0.   ]\nfar wrong  naive inf   tinynet inf   log-sum-exp 120.0000   tinynet's gradient [-1.  1.  0.]"
}
```

The first line is the ceiling. **`float32` holds nothing above 3.4 × 10³⁸, which is the exponential of
88.72**, so a logit of 89 already overflows. With logits near 1,000 the naive version returns `nan`
and two warnings on the way: the exponentials overflowed to infinity, and infinity divided by infinity
has no value. Nothing stops the program. A `nan` loss then makes a `nan` gradient, and one update
with it turns every weight it touches into `nan`.

The four warnings sit above every printed line because the capture wrote to a file, and Python holds
ordinary output back until the end when it is not printing to a terminal. In your terminal each
warning appears just before the line it belongs to.

**tinynet's version gives 0.1270 because its first line subtracts the largest logit from all of
them.** Softmax does not change when one number is subtracted from every logit, because that number
becomes a factor `exp(-m)` above and below the fraction, and it cancels. After the shift the largest
exponential is `exp(0) = 1`, and nothing can overflow.

The second case is the opposite problem. The network gave a wrong class a score 120 above the right
one. After the shift the right class's exponential is `exp(-120)`, smaller than the smallest
`float32`, so it becomes 0, its log is minus infinity, and both the naive loss and tinynet's print
`inf`. **tinynet's gradient is still right**: `[-1, 1, 0]` is exactly `p` minus the one-hot target,
so training corrects the mistake as it should. Only the reported loss is useless, and the mean loss of
any batch holding that image is `inf` too.

**Log-sum-exp never forms the probability, so neither failure can happen.** Minus the log of a
softmax is the log of the sum of the exponentials, minus the right logit. Computed after the shift,
the sum is at least 1, its log is at least 0, and the loss comes out as 120.0000, the right answer.

**This is why the frameworks want logits, not probabilities.** PyTorch's cross-entropy, which lesson
9 introduces, takes the raw scores and does the log-sum-exp itself. Applying a softmax first and
handing it the result is one of the classic bugs lesson 9 runs on purpose.
