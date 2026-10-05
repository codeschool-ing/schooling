---
title: Quantização dentro do índice
version: 1
---

Todo índice até aqui guardou cada vetor inteiro: 384 números de 4 bytes, 1.536 bytes por vetor,
lidos e multiplicados por completo sempre que a busca chega a ele. **A quantização troca o vetor por
um código mais curto** e calcula a nota a partir do código. É fácil imaginar isso como um controle
deslizante em que cada byte removido custa a mesma quantidade de qualidade. A medida abaixo não é uma
linha reta: os primeiros três quartos dos bytes não custam quase nada, e cada passo depois disso
custa muito.

## Dois jeitos de fazer um código

A **quantização escalar** trata cada número sozinho. O treino registra a faixa que cada uma das 384
coordenadas ocupa na coleção, e cada número é guardado como um byte que diz em que ponto da faixa da
sua coordenada ele cai. O FAISS a chama de `SQ8`: 384 bytes por vetor, um quarto do original.

A **quantização por produto** trata o vetor em pedaços. `PQ96` corta os 384 números em 96 pedaços de
4, e o treino roda um k-means separado para cada posição de pedaço, achando 256 valores típicos para
ela. Cada pedaço é então guardado como um byte, o número do valor típico mais próximo dele, e o vetor
vira 96 bytes. `PQ48` usa 48 pedaços de 8, e `PQ16` 16 pedaços de 24. Dentro de um índice IVF, o
FAISS codifica a diferença entre cada vetor e o centro da sua célula, e não o próprio vetor, o que
deixa menos para codificar. Para dar nota a um código, a busca primeiro compara os pedaços da
consulta com os 256 valores típicos de cada posição, uma vez por consulta. Depois disso, a nota de cada
vetor é uma soma de 96 números consultados nessa tabela, em vez de 384 multiplicações.

## O que cada um guarda

`quant.py` constrói índices IVF com 1.024 células e cada tipo de código, treina todos em 40.000 dos
vetores e busca em 16 células:

```schooling-example
{
  "language": "python",
  "file": "quant.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\nfrom bench import X, recall, timed\n\nsample = X[np.random.default_rng(2).choice(len(X), size=40_000, replace=False)]\nprint(f\"{'index':>13} {'bytes/vector':>12} {'train':>7} {'recall@10':>9} {'per query':>10}\")\nfor spec in (\"IVF1024,Flat\", \"IVF1024,SQ8\", \"IVF1024,PQ96\", \"IVF1024,PQ48\", \"IVF1024,PQ16\"):\n    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)\n    start = time.perf_counter()\n    index.train(sample)\n    trained = time.perf_counter() - start\n    index.add(X)\n    index.nprobe = 16\n    I, ms = timed(lambda Q: index.search(Q, 10)[1])\n    print(f\"{spec:>13} {index.code_size:>12} {trained:>5.1f} s {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "Cinco índices IVF com 1.024 células, montados a partir de strings de fábrica: vetores completos, um byte por número e códigos de produto de 96, 48 e 16 bytes. Cada um é treinado nos mesmos 40.000 vetores e buscado com `nprobe` 16. `code_size` é o número de bytes guardados por vetor."
    }
  ],
  "output": "ana@lab:~/emb$ python quant.py\n        index bytes/vector   train recall@10  per query\n IVF1024,Flat         1536   7.0 s     0.999   0.309 ms\n  IVF1024,SQ8          384   7.5 s     0.987   0.223 ms\n IVF1024,PQ96           96  60.8 s     0.693   0.138 ms\n IVF1024,PQ48           48  38.2 s     0.450   0.085 ms\n IVF1024,PQ16           16  20.0 s     0.230   0.096 ms"
}
```

**O `SQ8` guardou 0,987 dos vizinhos verdadeiros com um quarto do tamanho.** Um byte por número é
fino o bastante para manter quase toda ordenação que os números completos fazem, e o treino levou
7,5 s, mais ou menos o mesmo que as células sozinhas.

**A quantização por produto perdeu muito mais que a sua parte.** O `PQ96` tem um dezesseis avos do
tamanho e guardou 0,693; o `PQ48` guardou 0,450 e o `PQ16`, 0,230. O treino dela foi o passo lento
de toda esta aula, 60,8 s para o `PQ96`, porque são 96 execuções separadas de k-means. A aula 13 viu
códigos de 16 bytes perderem a maior parte dos vizinhos em cópias muito juntas de vetores reais e
esperava que vetores mais espalhados perdessem menos; nestas misturas eles perderam quase o mesmo. O
motivo é a faixa estreita que a seção sobre busca exata mediu. Os dez vetores mais próximos de uma
consulta têm notas a poucos centésimos uns dos outros, e um código que borra cada nota mais do que
isso os reordena. A vizinhança ainda é achada; a ordem dentro dela, não.

É por isso que a quantização por produto raramente é o último passo. O desenho comum mantém os
códigos na memória para escolher algumas centenas de candidatos depressa, e guarda os vetores
completos num lugar mais barato, como o disco, para dar nova nota só a esses. A aula 16 mediu esse
padrão com códigos binários, a forma mais extrema: um bit por número, 48 bytes para estes vetores.

## Para onde vão os bytes

A coluna `bytes/vector` é só os códigos. O índice também guarda o id de cada vetor e os centros das
células, e a aula 18 pesa arquivos de índice inteiros e põe preço em cada forma, junto com vetores
`float16`, int8 e binários guardados fora de um índice. O pgvector 0.6.0, a versão do laboratório,
não tem nenhum índice quantizado: o `hnsw` e o `ivfflat` dele guardam os vetores completos.

O que levar desta tabela é a ordem das perguntas. Pergunte primeiro se os vetores completos cabem na
memória; com 1.536 bytes, 100.000 deles são 153,6 MB. Se não couberem, tente o `SQ8` antes de algo
mais engenhoso, medido como este programa mede. Recorra à quantização por produto quando a coleção
for grande demais para qualquer outra coisa, e planeje junto o passo de dar nova nota.
