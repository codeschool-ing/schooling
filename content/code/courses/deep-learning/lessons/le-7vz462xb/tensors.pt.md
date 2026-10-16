---
title: Tensores, e a memória por trás deles
version: 1
---

Oito aulas treinaram redes em NumPy, escrevendo à mão cada passo para trás. **O tensor do PyTorch é
o array do NumPy com duas coisas a mais**: ele sabe qual dispositivo guarda os seus números, e pode
registrar as operações que o produziram para que os gradientes delas sejam calculados. Todo o resto,
a indexação, o broadcasting e o `@` do produto de matrizes, funciona como as aulas 1 a 8 usaram.

Os dois são próximos o bastante para passar de um ao outro com uma chamada em cada sentido, e essa
proximidade esconde as primeiras surpresas. Salve isto como `~/dl/tensors.py`; ele lê os dados pelo
`digits.py` da aula 1:

```schooling-example
{
  "language": "python",
  "file": "tensors.py",
  "parts": [
    {
      "code": "\"\"\"tensors: shape, dtype and device, the trip from NumPy and back, and a view.\"\"\"\nimport numpy as np\nimport torch\nimport torch.nn as nn\n\nimport digits\n\n(x, y), _, _ = digits.load()\nt = torch.from_numpy(x)\nlabels = torch.from_numpy(y)\nprint(\"images:\", t.shape, t.dtype, t.device)\nprint(\"labels:\", labels.shape, labels.dtype)",
      "note": "Três atributos descrevem todo tensor: o formato, o tipo dos seus números e o dispositivo que os guarda. Os dígitos chegam como o `digits.py` da aula 1 os fez, imagens `float32` e rótulos `int64`."
    },
    {
      "code": "print(\"from Python numbers:\", torch.tensor([1, 2]).dtype, torch.tensor([0.5, 2.0]).dtype)\nprint(\"from NumPy's default:\", torch.from_numpy(np.zeros(3)).dtype)\ntry:\n    nn.Linear(3, 2)(torch.from_numpy(np.zeros((1, 3))))\nexcept RuntimeError as e:\n    print(\"float64 into a layer:\", e)",
      "note": "O padrão do próprio PyTorch para um decimal é `float32`, enquanto o do NumPy é `float64`, e o `from_numpy` mantém o que o NumPy tinha. Os pesos de uma camada são `float32`, e ela se recusa a multiplicá-los por qualquer outra coisa."
    },
    {
      "code": "x[0, 3] = 7.0\nprint(\"changed in NumPy, read from the tensor:\", t[0, 3].item())\ncopy = torch.tensor(x)\nx[0, 3] = 0.0\nprint(\"the tensor:\", t[0, 3].item(), \" the copy:\", copy[0, 3].item())",
      "note": "O `from_numpy` não copia: o array e o tensor são dois nomes para a mesma memória, então uma mudança por um é vista pelo outro. O `torch.tensor` faz uma cópia que segue seu próprio caminho."
    },
    {
      "code": "img = t[0].view(8, 8)\nprint(\"view\", tuple(img.shape), \" same memory:\", img.data_ptr() == t.data_ptr())\nprint(\"strides of t:\", t.stride(), \" of t.T:\", t.T.stride(), \" t.T contiguous:\", t.T.is_contiguous())\ntry:\n    t.T.view(-1)\nexcept RuntimeError as e:\n    print(\"view of t.T:\", str(e).split(\" (\")[0])\nprint(\"reshape of t.T, same memory:\", t.T.reshape(-1).data_ptr() == t.data_ptr())",
      "note": "Uma view é um formato novo sobre os mesmos números. O stride diz quantos números pular a cada passo em cada dimensão; uma transposta só troca os strides, e uma linha do resultado deixa de ser um trecho contínuo de memória, então o `view` recusa e o `reshape` copia."
    },
    {
      "code": "device = \"cuda\" if torch.cuda.is_available() else \"cpu\"\nprint(\"device:\", device, \" moved:\", t.to(device).device)",
      "note": "A linha de costume no topo de um programa de treino: usar a placa de vídeo, se houver. Nesta máquina não há, e `.to(\"cpu\")` num tensor que já está lá o devolve sem mudança."
    }
  ]
}
```

```
ana@vm:~/dl$ python tensors.py
images: torch.Size([1077, 64]) torch.float32 cpu
labels: torch.Size([1077]) torch.int64
from Python numbers: torch.int64 torch.float32
from NumPy's default: torch.float64
float64 into a layer: mat1 and mat2 must have the same dtype, but got Double and Float
changed in NumPy, read from the tensor: 7.0
the tensor: 0.0  the copy: 7.0
view (8, 8)  same memory: True
strides of t: (64, 1)  of t.T: (1, 64)  t.T contiguous: False
view of t.T: view size is not compatible with input tensor's size and stride
reshape of t.T, same memory: False
device: cpu  moved: cpu
```

## Três atributos

**Formato, dtype e dispositivo são as três primeiras coisas a imprimir quando algo não encaixa.** As
imagens são `[1077, 64]` e `float32`, os rótulos `[1077]` e `int64`, e os dois moram na `cpu`. Os
rótulos são inteiros de propósito: a perda os lê como números de classe, um por imagem, como a
entropia cruzada da aula 4 fazia.

O dtype é onde NumPy e PyTorch discordam. Um decimal do Python vira `float32` no PyTorch e `float64`
no NumPy, e o `from_numpy` mantém a escolha do NumPy, então um array feito com `np.zeros` chega como
`float64`. Os pesos de uma camada são `float32`, e o produto se recusa a misturá-los:
`mat1 and mat2 must have the same dtype, but got Double and Float`. O `digits.py` converteu com
`astype(np.float32)` na aula 1, e é por isso que os dígitos nunca encontram esse erro. Dados vindos
de qualquer outro lugar precisam da mesma conversão, ou de `.float()` no tensor.

## Um bloco de memória, vários nomes

**`torch.from_numpy` não copia.** O tensor e o array dividem a memória, então o 7.0 escrito no array
foi lido de volta pelo tensor. `torch.tensor(x)` copia, e a cópia ficou com o seu 7.0 quando o array
voltou a zero.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 274\" role=\"img\" aria-label=\"Um array NumPy x, o tensor t feito dele com from_numpy e a view 8 por 8 da primeira linha de t apontam para um mesmo bloco de memória. Um tensor feito com torch.tensor aponta para um segundo bloco, só dele.\"><rect x=\"20\" y=\"20\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">x</text><text x=\"196\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">array NumPy</text><path d=\"M210 44 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M310.0 91.9 L318 92 L312.5 86.2\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"20\" y=\"82\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">t</text><text x=\"196\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tensor</text><path d=\"M210 106 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M311.1 96.0 L318 92 L310.3 89.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"20\" y=\"144\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">img</text><text x=\"196\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(8, 8)</text><text x=\"36\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">view da imagem 0</text><path d=\"M210 168 L318 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M313.8 98.8 L318 92 L310.2 93.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"320\" y=\"50\" width=\"340\" height=\"84\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M362.5 50 L362.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M405.0 50 L405.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M447.5 50 L447.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490.0 50 L490.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M532.5 50 L532.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M575.0 50 L575.0 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M617.5 50 L617.5 134\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"490\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um bloco de memória: 1.077 × 64 números float32</text><text x=\"490\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">os mesmos números, sem cópia</text><rect x=\"20\" y=\"214\" width=\"190\" height=\"48\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">copy</text><text x=\"196\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">(1077, 64)</text><text x=\"36\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">torch.tensor(x)</text><path d=\"M210 238 L318 238\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M310.6 241.1 L318 238 L310.6 234.9\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"320\" y=\"218\" width=\"340\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">uma cópia, memória própria</text></svg>", "caption": "Três nomes, um bloco de memória. Uma mudança feita por qualquer um deles é vista pelos outros dois; só o torch.tensor faz um bloco próprio.", "same": ["tensor"]}
```

Uma view vai um passo além: os mesmos números sob outro formato. `t[0].view(8, 8)` é a primeira
imagem como grade, e a memória dela começa onde a de `t` começa. Dois números por dimensão tornam
isso possível, o tamanho e o stride, que diz quanto pular na memória para dar um passo naquela
dimensão. `t` tem strides `(64, 1)`: 64 números até a próxima imagem, 1 até o próximo pixel.

Uma transposta também é uma view: ela troca os strides para `(1, 64)` e não move nada. O preço é que
uma linha de `t.T` deixa de ser um trecho contínuo de memória, o que o PyTorch chama de não contíguo,
e o `view` se recusa a achatá-la. O `reshape` faz o mesmo trabalho e copia quando precisa, e é por
isso que o resultado dele não divide a memória de `t`. **Dividir é o que torna uma view de graça, e é
também por que escrever por uma delas muda as outras**, como o 7.0 mudou.

## O dispositivo

A última linha é a que todo programa de treino tem no começo, escolhendo a placa de vídeo quando há
uma. Aqui não há, então a resposta é `cpu`. Pedir uma placa mesmo assim falha na hora:

```
ana@vm:~/dl$ python -c "import torch; torch.zeros(1, device='cuda')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/torch/cuda/__init__.py", line 591, in _lazy_init
    torch._C._cuda_init()
RuntimeError: Found no NVIDIA driver on your system. Please check that you have an NVIDIA GPU and installed a driver from http://www.nvidia.com/Download/index.aspx
```

Numa máquina com placa NVIDIA e o driver dela, a mesma linha põe o tensor na memória da placa, e toda
operação sobre ele roda lá. Um modelo e os seus dados precisam estar no mesmo dispositivo, e movê-los
é assunto da aula 10. Este curso roda tudo no processador.
