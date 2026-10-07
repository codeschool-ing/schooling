---
title: Velocidade num processador
version: 1
---

Com um provedor, a velocidade do modelo é problema do provedor e uma linha na tabela de preços dele.
Com um modelo aberto é problema seu, e ela decide quanto tempo leva a primeira indexação, quantas
mensagens por segundo um pipeline acompanha e se você precisa de uma placa de vídeo. E é fácil errar
no chute, então meça na máquina que vai rodá-lo.

Essa máquina, para todos os números abaixo:

```
ana@lab:~/emb$ nproc
4
ana@lab:~/emb$ grep -m1 "model name" /proc/cpuinfo
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ grep -n "num_threads" minilm.py
33:_opts.intra_op_num_threads = 1
34:_opts.inter_op_num_threads = 1
```

Quatro processadores, e **o `minilm.py` usa um deles**: as duas linhas que o `grep` achou mandam o
onnxruntime usar uma thread só. Isso mantém as medições do curso comparáveis entre si enquanto
outros trabalhos rodam na mesma máquina, e quer dizer que os números abaixo são o que um núcleo faz.
Outros processos estavam rodando durante esta medição, então outra rodada imprime outros números.

`speed.py` transforma os 150 tickets em vetores, três vezes para cada configuração, e fica com a
rodada mais rápida:

```schooling-example
{
  "language": "python",
  "file": "speed.py",
  "parts": [
    {
      "code": "import json\nimport time\nfrom minilm import embed\nfrom wordllama import WordLlama\n\ntexts = [json.loads(line)[\"text\"] for line in open(\"data/tickets.jsonl\")]\nwl = WordLlama.load()",
      "note": "Os 150 tickets, e os dois modelos carregados antes de qualquer medição começar."
    },
    {
      "code": "def rate(f, items, runs=3):\n    best = float(\"inf\")\n    for _ in range(runs):\n        t = time.perf_counter()\n        f(items)\n        best = min(best, time.perf_counter() - t)\n    return len(items) / best",
      "note": "Textos por segundo para uma função de embedding: rode três vezes e fique com a mais rápida, que é a rodada menos perturbada por qualquer outra coisa."
    },
    {
      "code": "minilm = []\nfor b in (1, 8, 32, 150):\n    minilm.append(rate(lambda t: embed(t, batch=b), texts))\n    print(f\"all-MiniLM-L6-v2  batch {b:3}           {minilm[-1]:7.0f} texts/s\")",
      "note": "O MiniLM em quatro tamanhos de lote, o último com os 150 tickets de uma vez."
    },
    {
      "code": "minilm.append(rate(lambda t: embed(t, batch=32), sorted(texts, key=len)))\nprint(f\"all-MiniLM-L6-v2  batch  32, sorted   {minilm[-1]:7.0f} texts/s\")\nstatic = rate(lambda t: wl.embed(t, norm=True), texts)\nprint(f\"WordLlama         batch  64           {static:7.0f} texts/s\")",
      "note": "Lote de 32 de novo, com os tickets ordenados por tamanho antes, e o WordLlama no lote padrão de 64."
    },
    {
      "code": "fastest = max(minilm)\nprint(f\"WordLlama / fastest MiniLM: {static / fastest:.0f} times\")\nprint(f\"a million texts at the fastest MiniLM rate: {1e6 / fastest / 60:.0f} minutes\")",
      "note": "Os dois números que a seção usa: quantas vezes o modelo estático foi mais rápido que a linha mais rápida do MiniLM, e quanto tempo um milhão de textos levaria nessa taxa do MiniLM."
    }
  ],
  "output": "ana@lab:~/emb$ python speed.py\nall-MiniLM-L6-v2  batch   1               222 texts/s\nall-MiniLM-L6-v2  batch   8               245 texts/s\nall-MiniLM-L6-v2  batch  32               200 texts/s\nall-MiniLM-L6-v2  batch 150               193 texts/s\nall-MiniLM-L6-v2  batch  32, sorted       231 texts/s\nWordLlama         batch  64             21776 texts/s\nWordLlama / fastest MiniLM: 89 times\na million texts at the fastest MiniLM rate: 68 minutes"
}
```

## Lotes numa thread só

O conselho comum é que lotes maiores são mais rápidos, e numa placa de vídeo ou com muitas threads
isso costuma valer: uma chamada faz a conta de muitos textos de uma vez. **Aqui, numa thread só,
isso valeu só até certo ponto.** O lote de 8 rodou a 245 textos por segundo, contra 222 do lote de
1, e depois o lote de 32 caiu para 200 e o de 150 para 193. O lote economiza o custo fixo de cada
chamada, que é pequeno, e cobra o **preenchimento**, que não é. Um lote é um retângulo da largura do
texto mais longo, então todo ticket mais curto dentro dele é completado com pedaços `[PAD]`. O
transformer faz a conta inteira em cada um deles antes de a máscara jogar o resultado fora. Quanto
maior o lote, maior a chance de ele ter um ticket longo que faz todo o resto pagar.

**Ordenar os textos por tamanho antes de montar os lotes tira a maior parte do preenchimento**: o
lote de 32 foi de 200 textos por segundo para 231. O sentence-transformers ordena por tamanho dentro
do `encode` exatamente por isso e devolve os vetores na sua ordem; um laço escrito à mão precisa
fazer isso de propósito.

## O modelo estático

**O WordLlama transformou 21.776 tickets por segundo em vetores**, 89 vezes a linha mais rápida do
MiniLM, o lote de 8; as duas últimas linhas do programa fazem essa divisão e a conta seguinte. Não
há transformer para rodar: o vetor de cada token é buscado numa tabela e entra numa média, que é a
diferença que a aula 1 traçou entre um modelo estático e um contextual. A seção anterior o achou tão
preciso quanto o MiniLM nas perguntas da central de ajuda, então aqui o modelo mais barato é também
o muito mais rápido. A aula 10 mede os modelos estáticos mais a fundo e pergunta do que eles abrem
mão.

## Para que servem os números

A 245 textos por segundo, os 40 artigos levam bem menos de um segundo, e um milhão de documentos
levam 68 minutos de um núcleo. Essa conta, textos divididos pela taxa medida, é como dimensionar uma
reindexação antes de começar, e a aula 18 a usa para a conta em dinheiro. Meça com os seus próprios
textos: os tickets são curtos, e o tempo de um modelo cresce com o tamanho do que ele lê, até o
limite em que ele para de ler.
