---
title: Para onde vai o tempo
version: 1
---

A imagem intuitiva é que um prompt mais longo é um prompt mais lento: mais para enviar, mais para
ler, uma espera maior. **Para a espera que uma pessoa sente, o tamanho da resposta importa muito mais
que o tamanho do prompt**, e o laboratório consegue mostrar por quê, porque as latências dele são
aritmética.

## O relógio do substituto

O substituto não mede quanto uma chamada demora. O `promptlab/model.py` calcula uma latência para
cada chamada a partir de alguns números declarados, para que duas execuções do mesmo prompt imprimam
a mesma coisa:

```
ana@lab:~/triage$ grep -n "^LATENCY" promptlab/model.py
23:LATENCY = {"per_call": 300, "per_input": 0.4, "per_cached": 0.04, "per_output": 20.0, "jitter": 150}
```

Cada chamada custa 300 ms por menor que seja, 0,4 ms por token de entrada, 20 ms por token de saída,
e até 150 ms de variação que depende do prompt. **Esses números são do curso, não de algum
provedor.** O que eles copiam é uma forma. Um modelo lê toda a entrada numa passada que roda em
paralelo, e depois escreve a resposta um token por vez, cada token esperando o anterior, que é como o
decodificador de *Attention Is All You Need* (Vaswani e outros, 2017) gera texto. O guia de
otimização de latência publicado pela OpenAI faz a observação prática: ele põe gerar menos tokens
entre os primeiros princípios, e diz que cortar tokens de entrada costuma ajudar bem menos.

## Três prompts, cronometrados

O `pl latency` resume as latências de uma execução, e aqui estão três prompts de aulas anteriores
sobre as mesmas quarenta mensagens:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/v8.jsonl
40 calls, prompt d0591569, written to runs/v8.jsonl
ana@lab:~/triage$ pl latency runs/v2.jsonl
calls 40
p50 1186 ms   p95 1397 ms   max 1468 ms
output tokens: mean 39.9, max 50
ana@lab:~/triage$ pl latency runs/v3.jsonl
calls 40
p50 1230 ms   p95 1341 ms   max 1371 ms
output tokens: mean 37.4, max 46
ana@lab:~/triage$ pl latency runs/v8.jsonl
calls 40
p50 1238 ms   p95 1450 ms   max 1503 ms
output tokens: mean 38.4, max 50
```

`p50` é a mediana: metade das chamadas foi mais rápida. `p95` é o tempo que 95 em cada cem chamadas
batem, o que em quarenta chamadas quer dizer que só duas foram mais lentas. `max` é a mais lenta de
todas.

Agora os tokens por chamada dos dois primeiros:

```
ana@lab:~/triage$ pl cost runs/v2.jsonl | head -n 5
tokens          count   per call
input            3139       78.5
cache_read          0        0.0
cache_write         0        0.0
output           1595       39.9
ana@lab:~/triage$ pl cost runs/v3.jsonl | head -n 5
tokens          count   per call
input            9539      238.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4
```

O `v3-examples` envia o triplo da entrada do `v2-json`, 238,5 tokens por chamada contra 78,5, e a
mediana dele é só 44 ms maior. O p95 é menor, 1341 ms contra 1397, porque ele escreve menos: 37,4
tokens de saída por chamada contra 39,9, e no máximo 46 contra 50. O `v8-guide` tem o maior p95 dos
três, 1450 ms, e a resposta mais longa dele tem 50 tokens, como a do `v2-json`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Para onde vai o tempo de uma chamada média, no substituto, em dois prompts. v2-json: 300 ms fixos, 31 ms lendo 78,5 tokens de entrada, 798 ms escrevendo 39,9 tokens de saída, 1129 ms ao todo. v3-examples: 300 ms fixos, 95 ms lendo 238,5 tokens de entrada, 748 ms escrevendo 37,4 tokens de saída, 1143 ms ao todo. Cada chamada ainda ganha até 150 ms de variação.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma chamada média, em milissegundos, antes da variação</text><text x=\"128\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-json</text><rect x=\"140\" y=\"50\" width=\"129.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"269.0\" y=\"50\" width=\"13.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"282.5\" y=\"50\" width=\"343.1\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"635.6\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1129 ms</text><text x=\"140\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 + 31 + 798 = 1129</text><text x=\"128\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v3-examples</text><rect x=\"140\" y=\"122\" width=\"129.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"269.0\" y=\"122\" width=\"41.0\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"310.0\" y=\"122\" width=\"321.6\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"641.7\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1143 ms</text><text x=\"140\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 + 95 + 748 = 1143</text><rect x=\"140\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"158\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fixo, por chamada</text><rect x=\"320\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"338\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lendo a entrada</text><rect x=\"500\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"518\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escrevendo a saída</text></svg>", "caption": "O triplo de entrada acrescenta 64 ms à leitura; 2,5 tokens a menos de saída tiram 50 ms da escrita. Os totais ficam a 14 ms um do outro. Os números são do substituto, tirados do model.py e do pl cost; a forma é a dos modelos reais."}
```

**Cada token de saída custa cinquenta vezes o que custa um de entrada** neste relógio, então 2,5
tokens a menos de resposta quase compensam 160 tokens a mais de prompt. A proporção é do curso, e a
de um modelo real será outra. O sentido não muda: se você quer a resposta mais cedo, olhe para o que
o modelo escreve antes de olhar para o que você envia.
