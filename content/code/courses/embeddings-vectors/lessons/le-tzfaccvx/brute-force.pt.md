---
title: Ler todos os vetores
version: 1
---

Toda busca das aulas 3 a 10 foi a mesma linha de NumPy: multiplicar o vetor da pergunta por cada
vetor guardado e ordenar as notas. É fácil arquivar essa linha como "brinquedo" e supor que um
sistema de verdade faz algo mais esperto desde o começo. **Não é brinquedo. É busca exata**, o
método que devolve os vizinhos mais próximos de verdade, e é a régua contra a qual todo método mais
rápido é medido; a aula 15 mede índices aproximados por quantas vezes eles concordam com ela. O
assunto aqui é o que ela custa, e o custo tem uma forma simples: **cada consulta lê todos os
vetores.**

`brute.py` mede isso em três tamanhos. Os vetores são aleatórios, e não textos transformados em
vetor, porque um milhão de números aleatórios levam segundos para fazer e um milhão de textos
levariam horas, e a aritmética não se importa com o que os números significam.

```schooling-example
{
  "language": "python",
  "file": "brute.py",
  "parts": [
    {
      "code": "import os\nos.environ[\"OPENBLAS_NUM_THREADS\"] = \"1\"\nimport time\nimport numpy as np\n\nrng = np.random.default_rng(11)\nd = 384\nq = rng.standard_normal(d).astype(np.float32)\nq /= np.linalg.norm(q)",
      "note": "Mande a biblioteca de matrizes do NumPy usar uma thread antes de importar o NumPy, para que as medições sejam de um núcleo. Depois uma consulta aleatória de 384 números, com comprimento 1 como todo vetor que este curso guarda."
    },
    {
      "code": "print(f\"{'vectors':>9} {'memory':>9} {'per query':>10} {'queries/s':>9} {'multiply-adds':>14}\")\nfor n in (10_000, 100_000, 1_000_000):\n    D = rng.standard_normal((n, d), dtype=np.float32)\n    D /= np.linalg.norm(D, axis=1, keepdims=True)",
      "note": "Três coleções de vetores aleatórios de comprimento 1: dez mil, cem mil e um milhão. Números aleatórios custam exatamente o mesmo que embeddings de verdade para multiplicar."
    },
    {
      "code": "    times = []\n    for _ in range(50):\n        t = time.perf_counter()\n        scores = D @ q\n        top = np.argpartition(-scores, 10)[:10]\n        times.append(time.perf_counter() - t)\n    s = min(times)",
      "note": "Uma busca é o método inteiro da aula 3: um produto escalar com cada vetor, depois os dez melhores. Rode 50 vezes e fique com a mais rápida."
    },
    {
      "code": "    print(f\"{n:>9,} {D.nbytes / 1e6:>6.0f} MB {s * 1000:>7.2f} ms {1 / s:>9.0f} {n * d:>14,}\")",
      "note": "Imprima a memória que os vetores ocupam, o tempo por consulta, quantas consultas por segundo isso permite e as multiplicações que uma consulta exige."
    }
  ]
}
```

```
ana@lab:~/emb$ nproc; grep -m1 "model name" /proc/cpuinfo
4
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ python brute.py
  vectors    memory  per query queries/s  multiply-adds
   10,000     15 MB    0.66 ms      1526      3,840,000
  100,000    154 MB    5.86 ms       171     38,400,000
1,000,000   1536 MB  129.16 ms         8    384,000,000
```

**O tempo acompanha a quantidade.** Dez vezes mais vetores levaram 8,9 vezes mais tempo da
primeira linha para a segunda, de 0,66 ms para 5,86 ms. O trabalho é uma multiplicação com soma por
número guardado, e a última coluna é a quantidade de vetores vezes 384. Da segunda linha
para a terceira levou 22 vezes mais, 129,16 ms. Um milhão de vetores são 1.536 MB, e cada consulta
precisa passar tudo isso pelo processador; nesse tamanho, o limite mais provável é a velocidade de
leitura da memória, e não a das multiplicações.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um gráfico de barras com eixo logarítmico do tempo que uma busca exata leva num núcleo, contra o número de vetores de 384 dimensões buscados: 10.000 vetores 0,66 ms, 100.000 vetores 5,86 ms, 1.000.000 vetores 129,16 ms. Cada passo tem dez vezes mais vetores.\"><path d=\"M170 200 L640 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M170 200 L170 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"170\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M287.5 200 L287.5 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"287.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M405 200 L405 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"405\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M522.5 200 L522.5 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"522.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M640 200 L640 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><text x=\"405\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milissegundos por consulta, escala logarítmica</text><text x=\"158\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10,000</text><text x=\"158\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15 MB</text><rect x=\"170\" y=\"44\" width=\"96.3\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"274.3\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.66 ms</text><text x=\"158\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">100,000</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">154 MB</text><rect x=\"170\" y=\"98\" width=\"207.7\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"385.7\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5.86 ms</text><text x=\"158\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1,000,000</text><text x=\"158\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1536 MB</text><rect x=\"170\" y=\"152\" width=\"365.6\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"543.6\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">129.16 ms</text><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vetores</text><text x=\"700\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dez vezes os vetores, umas dez vezes o tempo ou mais</text></svg>", "caption": "Uma busca exata num núcleo, medida por brute.py. Cada consulta lê todos os vetores, então o tempo acompanha a quantidade; a coluna de memória é o que precisa ser lido a cada vez."}
```

A coluna de consultas por segundo é a mesma medição vista ao contrário, e é ela que decide se isso
basta. Com dez mil vetores, um núcleo responde 1.526 buscas por segundo, mais do que a maioria das
centrais de ajuda vai receber um dia. Com um milhão, responde 8. Cada resposta continua exata; só
que são oito por segundo por núcleo, e um segundo núcleo apenas dobra isso.

## Quando ler tudo é a resposta certa

**Para uma coleção pequena, a busca exata é o método certo, e não um quebra-galho.** Os 40 artigos
da Marginalia custam 40 × 384 multiplicações com soma por pergunta, nada que valha um índice. A
busca exata não precisa de construção, de ajuste nem de memória além dos vetores, e nunca erra. A
aula 13 mostra o FAISS chamando isso de `IndexFlatIP`, e a aula 15 mostra quando deixa de bastar.

O que muda a resposta não é só o tamanho. O mesmo milhão de vetores a 8 consultas por segundo serve
para um trabalho noturno que procura quase-duplicatas e é inútil para uma caixa de busca em que mil
pessoas digitam ao mesmo tempo. A quantidade de vetores e a quantidade de consultas, juntas, decidem
quando o custo de ler tudo deixa de ser aceitável, e a medição acima dá os dois números para um
núcleo.
