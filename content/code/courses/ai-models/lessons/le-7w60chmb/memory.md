---
title: How much memory a model needs
version: 1
---

The size of a model in memory is arithmetic, and the inputs are published. Meta's repository
describes every Llama it released as a block of architecture numbers. This is Llama 3.1 8B:

```
ana@desk:~/desk$ sources lines llama-skus 235 246
# meta-llama/llama-models@0e0b8c51 models/sku_list.py
 235|             arch_args={
 236|                 "dim": 4096,
 237|                 "n_layers": 32,
 238|                 "n_heads": 32,
 239|                 "n_kv_heads": 8,
 240|                 "vocab_size": LLAMA3_VOCAB_SIZE,
 241|                 "ffn_dim_multiplier": 1.3,
 242|                 "multiple_of": 1024,
 243|                 "norm_eps": 1e-05,
 244|                 "rope_theta": 500000.0,
 245|                 "use_scaled_rope": True,
 246|             },
```

Those seven numbers, with the vocabulary size, determine every weight in the network. `lab/size.py`
reads them for the three Llama 3.1 sizes and does the sum:

```schooling-example
{
  "language": "python",
  "file": "lab/size.py",
  "parts": [
    {
      "code": "import re\nimport subprocess\nimport sys\n\nsrc = subprocess.run([\"sources\", \"lines\", \"llama-skus\", \"1\", \"330\"], capture_output=True, text=True).stdout\nVOCAB = 128256  # LLAMA3_VOCAB_SIZE, line 19 of sku_list.py\n\n\n",
      "note": "The architecture is read from Meta's own file, through `sources`, so the numbers cannot drift from the published ones. The vocabulary size is a constant at the top of that file."
    },
    {
      "code": "def arch(name):\n    block = src[src.index(f'\"meta-llama/{name}\"'):]\n    num = lambda k: float(re.search(rf'\"{k}\": ([0-9.]+)', block).group(1))  # noqa: E731\n    return {k: num(k) for k in (\"dim\", \"n_layers\", \"n_heads\", \"n_kv_heads\", \"ffn_dim_multiplier\", \"multiple_of\")}\n\n\n",
      "note": "Each model's block is found by its repository name, and six numbers are pulled out of the `arch_args` that follow it."
    },
    {
      "code": "def parameters(a):\n    dim, layers, kv = int(a[\"dim\"]), int(a[\"n_layers\"]), int(a[\"n_kv_heads\"])\n    head = dim // int(a[\"n_heads\"])\n    hidden = int(a[\"ffn_dim_multiplier\"] * int(2 * 4 * dim / 3))\n    hidden = int(a[\"multiple_of\"]) * ((hidden + int(a[\"multiple_of\"]) - 1) // int(a[\"multiple_of\"]))\n    attention = 2 * dim * dim + 2 * dim * kv * head\n    feed_forward = 3 * dim * hidden\n    return 2 * VOCAB * dim + layers * (attention + feed_forward + 2 * dim) + dim\n\n\n",
      "note": "The feed-forward width is not stored: Llama computes it from `dim`, the multiplier and `multiple_of`, and so does this. Attention is four matrices, two of them narrowed by the shared key and value heads. The embedding and output layers are the `2 * VOCAB * dim`."
    },
    {
      "code": "def kv_bytes_per_token(a, bytes_per_value=2):\n    head = int(a[\"dim\"]) // int(a[\"n_heads\"])\n    return 2 * int(a[\"n_layers\"]) * int(a[\"n_kv_heads\"]) * head * bytes_per_value\n\n\n",
      "note": "The KV cache keeps a key and a value per layer, per shared head, per token, at two bytes each."
    },
    {
      "code": "GB = 1e9\nbandwidth = float(sys.argv[1]) if len(sys.argv) > 1 else 1000  # GB/s, an assumption\nprint(f\"{'model':16} {'parameters':>15} {'16-bit':>8} {'8-bit':>7} {'4-bit':>7} {'KV/token':>9} {'tok/s at 4-bit':>15}\")\nfor name in (\"Llama-3.1-8B\", \"Llama-3.1-70B\", \"Llama-3.1-405B\"):\n    a = arch(name)\n    p = parameters(a)\n    sizes = [p * bits / 8 / GB for bits in (16, 8, 4)]\n    print(f\"{name:16} {p:>15,} {sizes[0]:>6.0f}GB {sizes[1]:>5.0f}GB {sizes[2]:>5.0f}GB \"\n          f\"{kv_bytes_per_token(a) // 1024:>6}KiB {bandwidth / sizes[2]:>15.0f}\")\n",
      "note": "Size at 16, 8 and 4 bits, and the speed ceiling from section 05: bandwidth divided by the 4-bit size. The bandwidth is an argument because it is an assumption about hardware, not a fact about the model."
    }
  ],
  "output": "model                 parameters   16-bit   8-bit   4-bit  KV/token  tok/s at 4-bit\nLlama-3.1-8B       8,030,261,248     16GB     8GB     4GB    128KiB             249\nLlama-3.1-70B     70,553,706,496    141GB    71GB    35GB    320KiB              28\nLlama-3.1-405B   405,853,388,800    812GB   406GB   203GB    504KiB               5"
}
```

Read the table one column at a time.

**Parameters.** 8,030,261,248: the "8B" in the name is a rounding of a number you can compute. The
70B is 70.6 billion and the 405B is 405.9 billion.

**Bytes per parameter.** Each weight is stored at some precision. At 16 bits, the precision the
models are released in, each parameter takes two bytes, so 8 billion parameters take **16 GB**. At
8 bits, half that; at 4 bits, a quarter. Section 04 is about what that costs in quality.

**The cache that grows with the conversation.** While generating, the runtime keeps two vectors per
layer per token of context, so that it does not recompute the whole prompt for every new token.
That is the **KV cache**, and the last memory column is its size per token: 128 KiB for the 8B. A
prompt of 8,192 tokens therefore needs 1 GiB of cache on top of the weights, and the model's full
window of 131,072 tokens needs **16 GiB**, about as much again as the weights themselves at 16
bits. Every
request being served at the same time needs its own.

## What that means in hardware

A model fits when **weights plus cache plus the runtime's own overhead** fit in the accelerator's
memory. So:

- the **8B** at 4 bits (4 GB) fits on a laptop's graphics card or in a recent laptop's unified
  memory, with room for a modest context;
- the **70B** at 4 bits (35 GB) needs a large data-centre accelerator, or two smaller ones sharing
  the layers;
- the **405B** at 4 bits (203 GB) needs several of the largest accelerators working together,
  which is a cluster rather than a machine.

The numbers are Llama's, and the arithmetic is the same for every model whose architecture is
published. For a closed model there is nothing to compute: the provider does not say, and does
not need to, because you will never hold it.
