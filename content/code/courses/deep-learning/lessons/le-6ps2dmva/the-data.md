---
title: The digits this course trains on
version: 1
---

**Most of this course trains on 1,797 handwritten digits, each an 8 by 8 grid of grey levels.**
They were published in 1998 and ship inside scikit-learn, which is why the setup needed no
download and why your copy is the same as the one the transcripts used.

Eight by eight is small. The famous MNIST digits are 28 by 28, and a phone photograph has millions
of pixels. That smallness is what makes the course possible on a processor: a network learns these
images in seconds, so an experiment that changes one setting costs a minute rather than an evening,
and the effect of the setting is the thing you watch.

## The split, written once

Every lesson that trains reads the data through one module. Save it as `~/dl/digits.py`:

```schooling-example
{
  "language": "python",
  "file": "digits.py",
  "parts": [
    {
      "code": "\"\"\"digits: the 1,797 handwritten digits that ship inside scikit-learn, split three ways.\"\"\"\nimport numpy as np\nfrom sklearn.datasets import load_digits",
      "note": "The data is inside the scikit-learn package you installed, so nothing is downloaded and every machine gets the same 1,797 images."
    },
    {
      "code": "def load(seed=0):\n    \"\"\"Train, validation and test sets: each image a row of 64 numbers in [0, 1], each label 0 to 9.\"\"\"\n    d = load_digits()\n    x = (d.data / 16.0).astype(np.float32)\n    y = d.target.astype(np.int64)",
      "note": "Each image is 8 by 8 pixels with an ink level from 0 to 16. Dividing by 16 puts every input between 0 and 1, and `float32` is the precision networks train in."
    },
    {
      "code": "    order = np.random.default_rng(seed).permutation(len(y))\n    x, y = x[order], y[order]\n    return (x[:1077], y[:1077]), (x[1077:1437], y[1077:1437]), (x[1437:], y[1437:])",
      "note": "One shuffle with a fixed seed, then 60% to train, 20% to validate and 20% held back for a final test, the split `machine-learning` taught. The same seed gives the same split on every machine."
    }
  ]
}
```

**The test set is not for choosing anything.** `machine-learning` made the point, and it applies
with more force here: a network has dozens of settings, and every one chosen by looking at a set
leaks a little of that set into the model. Validation is where the settings are chosen. Test is
looked at when they are done.

## Looking at it

Save this as `~/dl/look.py` and run it:

```schooling-example
{
  "language": "python",
  "file": "look.py",
  "parts": [
    {
      "code": "\"\"\"look: the data, its split, and one digit drawn in characters.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x_train, y_train), (x_val, y_val), (x_test, y_test) = digits.load()\nprint(\"train\", x_train.shape, \"val\", x_val.shape, \"test\", x_test.shape)\nprint(\"labels in train:\", np.bincount(y_train))",
      "note": "`bincount` counts how many of each label there are. A set where one digit were rare would need a different metric, and this one is close to even."
    },
    {
      "code": "print(\"label of the first image:\", y_train[0])\nfor row in x_train[0].reshape(8, 8):\n    print(\"\".join(\" .:-=+*#@\"[int(v * 8)] for v in row))",
      "note": "The 64 numbers go back into an 8 by 8 grid, and each ink level becomes one of nine characters, from blank to `@`."
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

1,077 images to train, 360 to validate and 360 to test, with every digit between 92 and 121 times
in the training set. The first training image is labelled 6, and the drawing shows why a person
would agree: a stroke coming down the left and a loop at the bottom.

**To a network, that 6 is the 64 numbers and nothing else.** It does not know they were a grid.
Lesson 11 gives it a way to use the fact that neighbouring pixels belong together; until then, the
picture has been flattened into a row, and a network that learns from a row has to learn from
scratch that pixel 9 sits under pixel 1.
