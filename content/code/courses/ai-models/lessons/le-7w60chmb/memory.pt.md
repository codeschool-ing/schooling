---
title: Quanta memória um modelo precisa
version: 1
---

O tamanho de um modelo na memória é aritmética, e os dados de entrada são publicados. O repositório
da Meta descreve cada Llama que ela lançou como um bloco de números de arquitetura. Esta é a Llama
3.1 8B:

```
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

Esses sete números, com o tamanho do vocabulário, determinam todos os pesos da rede. O
`lab/size.py` lê os números dos três tamanhos da Llama 3.1 e faz a conta:

```schooling-example
{
  "language": "python",
  "file": "lab/size.py",
  "parts": [
    {
      "code": "import re\nimport subprocess\nimport sys\n\nsrc = subprocess.run([\"sources\", \"lines\", \"llama-skus\", \"1\", \"330\"], capture_output=True, text=True).stdout\nVOCAB = 128256  # LLAMA3_VOCAB_SIZE, line 19 of sku_list.py\n\n\n",
      "note": "A arquitetura é lida do próprio arquivo da Meta, pelo `sources`, então os números não têm como se afastar dos publicados. O tamanho do vocabulário é uma constante no topo desse arquivo."
    },
    {
      "code": "def arch(name):\n    block = src[src.index(f'\"meta-llama/{name}\"'):]\n    num = lambda k: float(re.search(rf'\"{k}\": ([0-9.]+)', block).group(1))  # noqa: E731\n    return {k: num(k) for k in (\"dim\", \"n_layers\", \"n_heads\", \"n_kv_heads\", \"ffn_dim_multiplier\", \"multiple_of\")}\n\n\n",
      "note": "O bloco de cada modelo é achado pelo nome do repositório, e seis números são tirados dos `arch_args` que vêm depois."
    },
    {
      "code": "def parameters(a):\n    dim, layers, kv = int(a[\"dim\"]), int(a[\"n_layers\"]), int(a[\"n_kv_heads\"])\n    head = dim // int(a[\"n_heads\"])\n    hidden = int(a[\"ffn_dim_multiplier\"] * int(2 * 4 * dim / 3))\n    hidden = int(a[\"multiple_of\"]) * ((hidden + int(a[\"multiple_of\"]) - 1) // int(a[\"multiple_of\"]))\n    attention = 2 * dim * dim + 2 * dim * kv * head\n    feed_forward = 3 * dim * hidden\n    return 2 * VOCAB * dim + layers * (attention + feed_forward + 2 * dim) + dim\n\n\n",
      "note": "A largura da camada feed-forward não é guardada: a Llama a calcula a partir de `dim`, do multiplicador e de `multiple_of`, e este código faz o mesmo. A atenção são quatro matrizes, duas delas estreitadas pelas cabeças de chave e valor compartilhadas. As camadas de embedding e de saída são o `2 * VOCAB * dim`."
    },
    {
      "code": "def kv_bytes_per_token(a, bytes_per_value=2):\n    head = int(a[\"dim\"]) // int(a[\"n_heads\"])\n    return 2 * int(a[\"n_layers\"]) * int(a[\"n_kv_heads\"]) * head * bytes_per_value\n\n\n",
      "note": "O cache KV guarda uma chave e um valor por camada, por cabeça compartilhada, por token, com dois bytes cada."
    },
    {
      "code": "GB = 1e9\nbandwidth = float(sys.argv[1]) if len(sys.argv) > 1 else 1000  # GB/s, an assumption\nprint(f\"{'model':16} {'parameters':>15} {'16-bit':>8} {'8-bit':>7} {'4-bit':>7} {'KV/token':>9} {'tok/s at 4-bit':>15}\")\nfor name in (\"Llama-3.1-8B\", \"Llama-3.1-70B\", \"Llama-3.1-405B\"):\n    a = arch(name)\n    p = parameters(a)\n    sizes = [p * bits / 8 / GB for bits in (16, 8, 4)]\n    print(f\"{name:16} {p:>15,} {sizes[0]:>6.0f}GB {sizes[1]:>5.0f}GB {sizes[2]:>5.0f}GB \"\n          f\"{kv_bytes_per_token(a) // 1024:>6}KiB {bandwidth / sizes[2]:>15.0f}\")\n",
      "note": "O tamanho em 16, 8 e 4 bits, e o teto de velocidade da seção 05: largura de banda dividida pelo tamanho em 4 bits. A largura de banda é um argumento porque é uma suposição sobre hardware, não um fato do modelo."
    }
  ],
  "output": "model                 parameters   16-bit   8-bit   4-bit  KV/token  tok/s at 4-bit\nLlama-3.1-8B       8,030,261,248     16GB     8GB     4GB    128KiB             249\nLlama-3.1-70B     70,553,706,496    141GB    71GB    35GB    320KiB              28\nLlama-3.1-405B   405,853,388,800    812GB   406GB   203GB    504KiB               5"
}
```

Leia a tabela uma coluna de cada vez.

**Parâmetros.** 8.030.261.248: o "8B" do nome é um arredondamento de um número que você consegue
calcular. A 70B tem 70,6 bilhões e a 405B, 405,9 bilhões.

**Bytes por parâmetro.** Cada peso é guardado com alguma precisão. Em 16 bits, a precisão em que
os modelos são publicados, cada parâmetro ocupa dois bytes, então 8 bilhões de parâmetros ocupam
**16 GB**. Em 8 bits, metade; em 4 bits, um quarto. A seção 04 trata do que isso custa em qualidade.

**O cache que cresce com a conversa.** Enquanto gera, o runtime guarda dois vetores por camada para
cada token de contexto, para não recalcular o prompt inteiro a cada token novo. Esse é o **cache
KV**, e a última coluna de memória é o tamanho dele por token: 128 KiB para o 8B. Um prompt de 8.192
tokens precisa então de 1 GiB de cache além dos pesos, e a janela inteira do modelo, de 131.072
tokens, precisa de **16 GiB**, mais ou menos o mesmo que os próprios pesos em 16 bits. Cada requisição atendida ao mesmo
tempo precisa do seu.

## O que isso significa em hardware

Um modelo cabe quando **pesos mais cache mais a sobrecarga do próprio runtime** cabem na memória do
acelerador. Então:

- o **8B** em 4 bits (4 GB) cabe na placa de vídeo de um notebook ou na memória unificada de um
  notebook recente, com espaço para um contexto modesto;
- o **70B** em 4 bits (35 GB) precisa de um acelerador grande de data center, ou de dois menores
  dividindo as camadas;
- o **405B** em 4 bits (203 GB) precisa de vários dos maiores aceleradores trabalhando juntos, o que
  é um cluster, não uma máquina.

Os números são da Llama, e a aritmética é a mesma para todo modelo com arquitetura publicada. Para um
modelo fechado não há nada a calcular: o provedor não diz, e nem precisa, porque você nunca vai tê-lo.
