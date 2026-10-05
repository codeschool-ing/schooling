---
title: Vetores menores na mesma chamada
version: 1
---

Um vetor float32 gasta quatro bytes em cada coordenada, e a maior parte dessa precisão não muda qual
artigo fica em primeiro. O endpoint do Cohere pode devolver o mesmo vetor em formas mais baratas,
escolhidas com `embedding_types`, e **uma chamada pode pedir várias**, então a comparação abaixo
custa uma requisição por modelo.

| `embedding_types` | cada coordenada vira | bytes para 384 números |
|---|---|---|
| `float` | um float de 32 bits, como antes | 1.536 |
| `int8` | um número inteiro de −128 a 127 | 384 |
| `uint8` | o mesmo, deslocado para 0 a 255 | 384 |
| `binary` | um bit, oito por byte, como bytes com sinal | 48 |
| `ubinary` | os mesmos bits, como bytes sem sinal | 48 |

**Estas são as codificações do labembed, escritas para este laboratório, e o Cohere calcula as dele
de outro jeito.** O int8 do laboratório escala cada vetor para que a maior coordenada vire 127 e
arredonda o resto; o binário guarda um bit por coordenada, ligado quando o número é maior que zero.
Então os números abaixo descrevem o que a quantização faz com estes dois modelos, e não quanto as
codificações do Cohere tirariam.

## Comparando em cada codificação

Cada codificação precisa do seu jeito de pontuar. Floats e int8 são comparados com um produto
escalar, os int8 em inteiros de 32 bits para que as somas não estourem. Bits são comparados pela
**distância de Hamming**, o número de posições em que duas sequências de bits diferem: menos
diferenças quer dizer mais perto, então o programa troca o sinal para manter *mais alto é mais
perto*.

```schooling-example
{
  "language": "python",
  "file": "quantised.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nimport cohere\n\nco = cohere.ClientV2(api_key=os.environ[\"CO_API_KEY\"], base_url=os.environ[\"CO_API_URL\"])\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\nKINDS = {\"float\": np.float32, \"int8\": np.int8, \"ubinary\": np.uint8}",
      "note": "A mesma preparação, e as três codificações a pedir, com o tipo do NumPy em que cada uma é guardada."
    },
    {
      "code": "def embed(model, texts, input_type):\n    r = co.embed(model=model, texts=texts, input_type=input_type,\n                 embedding_types=list(KINDS))\n    e = r.embeddings\n    return {\"float\": np.array(e.float_, dtype=np.float32),\n            \"int8\": np.array(e.int8, dtype=np.int8),\n            \"ubinary\": np.array(e.ubinary, dtype=np.uint8)}",
      "note": "Uma chamada por lista de textos pede as três codificações, e cada uma volta como lista própria. Cada uma fica no tipo do NumPy em que cabe."
    },
    {
      "code": "def scores(kind, Q, D):\n    if kind == \"ubinary\":\n        q, d = np.unpackbits(Q, axis=1), np.unpackbits(D, axis=1)\n        return -(q[:, None, :] != d[None, :, :]).sum(axis=2)\n    if kind == \"int8\":\n        return Q.astype(np.int32) @ D.astype(np.int32).T\n    return Q @ D.T",
      "note": "Como pontuar cada codificação: distância de Hamming para bits, com sinal trocado para que mais alto seja mais perto; produto escalar em inteiros de 32 bits para int8; produto escalar comum para floats."
    },
    {
      "code": "print(f\"{'model':14} {'type':8} {'bytes':>5}  top 1  top 3  tied at 1\")\nfor model in [\"lab-minilm\", \"lab-wordllama\"]:\n    D = embed(model, [h[\"title\"] + \". \" + h[\"body\"] for h in help], \"search_document\")\n    Q = embed(model, [q[\"text\"] for q in queries], \"search_query\")\n    for kind in KINDS:\n        S = scores(kind, Q[kind], D[kind])\n        top = np.argsort(-S, axis=1, kind=\"stable\")[:, :3]\n        one = sum(ids[t[0]] in q[\"relevant\"] for t, q in zip(top, queries))\n        three = sum(any(ids[j] in q[\"relevant\"] for j in t) for t, q in zip(top, queries))\n        ties = sum(int(row[t[0]] == row[t[1]]) for row, t in zip(S, top))\n        print(f\"{model:14} {kind:8} {D[kind][0].nbytes:5}  {one:5}  {three:5}  {ties:9}\")",
      "note": "Para cada modelo e codificação, os bytes de um vetor, as perguntas respondidas na posição 1 e entre as 3 primeiras, e quantas perguntas tiveram dois artigos empatados em primeiro."
    }
  ],
  "output": "ana@lab:~/emb$ python quantised.py\nmodel          type     bytes  top 1  top 3  tied at 1\nlab-minilm     float     1536     19     22          0\nlab-minilm     int8       384     18     22          0\nlab-minilm     ubinary     48     16     23          1\nlab-wordllama  float     1024     20     24          0\nlab-wordllama  int8       256     20     23          0\nlab-wordllama  ubinary     32     15     21          1"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Barras com os bytes que um vetor ocupa em cada codificação, e quantas das 24 consultas acharam um artigo relevante na posição 1 e entre os 3 primeiros. lab-minilm float: 1536 bytes, 19 na posição 1, 22 entre os 3 primeiros; lab-minilm int8: 384 bytes, 18 na posição 1, 22 entre os 3 primeiros; lab-minilm ubinary: 48 bytes, 16 na posição 1, 23 entre os 3 primeiros; lab-wordllama float: 1024 bytes, 20 na posição 1, 24 entre os 3 primeiros; lab-wordllama int8: 256 bytes, 20 na posição 1, 23 entre os 3 primeiros; lab-wordllama ubinary: 32 bytes, 15 na posição 1, 21 entre os 3 primeiros.\"><text x=\"200\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes por vetor</text><text x=\"628\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">posição 1</text><text x=\"688\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 primeiros</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lab-minilm</text><text x=\"190\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"200\" y=\"59\" width=\"320\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1536</text><text x=\"630\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">19</text><text x=\"690\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">22</text><text x=\"190\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8</text><rect x=\"200\" y=\"89\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"288\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">384</text><text x=\"630\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">18</text><text x=\"690\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">22</text><text x=\"190\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ubinary</text><rect x=\"200\" y=\"119\" width=\"10\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"218\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">48</text><text x=\"630\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">16</text><text x=\"690\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">23</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lab-wordllama</text><text x=\"190\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">float</text><rect x=\"200\" y=\"185\" width=\"213.3\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"421.3\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1024</text><text x=\"630\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"690\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">24</text><text x=\"190\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8</text><rect x=\"200\" y=\"215\" width=\"53.3\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"261.3\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">256</text><text x=\"630\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"690\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">23</text><text x=\"190\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ubinary</text><rect x=\"200\" y=\"245\" width=\"6.7\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"214.7\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">32</text><text x=\"630\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">15</text><text x=\"690\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">21</text><path d=\"M600 34 L600 272\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de 24 consultas</text></svg>", "caption": "Uma requisição, três codificações de cada vetor. Os bytes caem a um quarto com o int8 e a um trinta e dois avos com o binário; as 24 consultas quase não percebem o int8, e o binário custa mais ao WordLlama que ao MiniLM. As codificações são a aritmética do labembed, não a do Cohere."}
```

Leia primeiro as linhas do MiniLM. **O int8 manteve 22 das 24 consultas entre os 3 primeiros com um
quarto dos bytes**, e perdeu uma na posição 1, 18 contra 19. **O binário manteve 23 entre os 3
primeiros com um trinta e dois avos dos bytes**, uma a mais que o float. Isso não é o binário sendo
melhor: com 24 perguntas, uma consulta mudando de lugar é acaso, e a leitura honesta das linhas do
MiniLM é que nenhuma das duas codificações custou nada que esta medida consiga ver.

O WordLlama é onde o custo aparece. O vetor binário dele tem 256 bits, contra 384 do MiniLM, e caiu
para 15 na posição 1 e 21 entre os 3 primeiros, vindo de 20 e 24. Menos coordenadas deixam menos
bits para carregar a diferença entre dois artigos parecidos.

A última coluna é uma armadilha que os bits têm e os floats não. **Uma distância de Hamming é um
número inteiro**, então dois artigos podem empatar exatamente, e uma consulta em cada rodada binária
teve dois artigos empatados na posição 1. O programa desempata pela ordem dos artigos no arquivo, o
que é arbitrário; um sistema de verdade desempata pontuando de novo.

## Para que serve

Um vetor binário é barato de guardar e muito barato de comparar, e o ponto fraco dele é a precisão
no topo. A resposta de costume usa os dois: busque em tudo com os bits, pegue as poucas dezenas
melhores e pontue de novo só essas com os vetores float. A aula 15 encontra a quantização dentro de
um índice, a aula 16 mostra essa nova pontuação, e a aula 18 põe preço nos bytes. O que esta seção
estabeleceu é mais estreito, e é a parte que um provedor decide por você: **a codificação é escolhida
por requisição**, então a codificação em que uma coleção foi guardada decide como cada consulta
futura tem de ser pontuada contra ela.
