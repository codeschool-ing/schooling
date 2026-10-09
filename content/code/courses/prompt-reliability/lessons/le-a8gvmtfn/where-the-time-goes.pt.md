---
title: Para onde vai o tempo
version: 2
---

A imagem intuitiva é que um prompt mais longo é um prompt mais lento: mais para mandar, mais para
ler, uma espera maior. **Para a espera que uma pessoa sente, o tamanho da resposta importa muito mais
que o tamanho do prompt**, e três prompts de aulas anteriores mostram isso na sua própria máquina.

## Por que a saída é a parte lenta

Um modelo lê a entrada inteira numa passada que consegue trabalhar em todos os tokens de uma vez.
Depois escreve a resposta um token de cada vez, cada token esperando o anterior, que é como o
decodificador de *Attention Is All You Need* (Vaswani e outros, 2017) gera texto. Ler cem tokens é um
passo de trabalho espalhado; escrever cem são cem passos em fila. O guia de otimização de latência
publicado pela OpenAI diz isso na prática: põe gerar menos tokens entre os primeiros princípios, e
diz que cortar tokens de entrada costuma ajudar bem menos.

## Três prompts, cronometrados

O `stats.py`, da aula 2, já relata quanto uma execução custou em tokens e em segundos. Aqui estão três
prompts sobre as mesmas quarenta mensagens, na máquina onde estas aulas foram capturadas, quatro
núcleos de processador e nenhuma placa de vídeo:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
ana@lab:~/triage$ python3 stats.py runs/v2.jsonl runs/v3.jsonl runs/v1.jsonl
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.8   total   1230   max 41
  seconds      p50   4.0   p95   5.5   total  171.3
runs/v3.jsonl, 40 calls
  tokens in    mean  248.2   total   9926
  tokens out   mean   30.6   total   1226   max 38
  seconds      p50   4.1   p95   5.0   total  168.2
runs/v1.jsonl, 40 calls
  tokens in    mean   61.1   total   2446
  tokens out   mean  106.2   total   4246   max 183
  seconds      p50  12.4   p95  15.6   total  485.8
```

`p50` é a mediana: metade das chamadas foi mais rápida. `p95` é o tempo que 95 em cada cem chamadas
bateram, o que em quarenta chamadas quer dizer que só duas foram mais lentas. São segundos de relógio,
então a sua máquina vai imprimir os dela; o que deve se manter é a comparação entre os três.

O `v3-examples` manda mais que o dobro da entrada do `v2-json`, 248,2 tokens por chamada contra 106,2,
e escreve o mesmo tanto, 30,6 contra 30,8. A mediana dele é 4,1 segundos contra 4,0: **142 tokens a
mais de prompt custaram um décimo de segundo**. O `v1-bare` manda o menos dos três, 61,1 tokens, e
escreve três vezes e meia mais, 106,2 tokens de resposta falante. A mediana dele é 12,4 segundos, três
vezes a dos outros, e o p95 é 15,6.

**Se você quer uma resposta mais cedo, olhe para o que o modelo escreve antes de olhar para o que
você manda.** Foi o que a aula 3 achou quando o JSON levou as respostas do prompt seco de 107,5
tokens para 30,6 e a chamada mediana de 12,7 segundos para 3,7, e é a mesma aritmética aqui. A aula
17 abre o tempo de uma chamada nas suas duas metades, ler e escrever, e mostra por que o prompt longo
daqui saiu tão barato de ler.
