---
title: O que um cache reaproveita
version: 1
---

A palavra sugere a coisa errada. Um cache de prompt não guarda respostas, e não lembra uma conversa
anterior. **Ele guarda o trabalho de ler o começo de um prompt**, para que a próxima chamada que
comece exatamente com os mesmos tokens pule essa parte e pague menos por ela. A resposta continua
sendo escrita do zero toda vez.

A maior parte de um prompt de produção é igual em toda chamada. O prompt desta aula é um guia longo
das categorias seguido da mensagem de um cliente, e só a mensagem muda. Um cache é um jeito de não
pagar preço cheio para ler o guia um milhão de vezes.

## O cache do substituto

O `promptlab/model.py` diz no comentário de abertura o que o cache dele faz:

```
ana@lab:~/triage$ grep -n -A6 "It also keeps a prompt cache" promptlab/model.py
12:It also keeps a prompt cache when the prompt file says `cache: on`: the
13-longest run of whole BLOCK-token blocks it has seen before, from the start of
14-the prompt, is read from the cache instead of being processed again. Prompts
15-shorter than MINIMUM are never cached. Real providers do the same thing with
16-their own block size and minimum.
17-"""
18-
ana@lab:~/triage$ grep -n "^BLOCK\|^MINIMUM" promptlab/model.py
24:BLOCK = 32
25:MINIMUM = 64
```

Então, no substituto:

- **O prompt é cortado em blocos inteiros de 32 tokens**, a partir do começo. Uma sobra menor que um
  bloco nunca vai para o cache.
- **Uma chamada lê do cache a sequência mais longa de blocos, a partir do primeiro, que uma chamada
  anterior já teve.** Um bloco diferente encerra a sequência, mesmo que todos os blocos depois dele
  batam.
- **Um prompt com menos de 64 tokens nunca vai para o cache.**
- O cache só liga quando o arquivo do prompt diz `cache: on` acima do `---`, e dura uma execução do
  `pl run`.

O mínimo é fácil de ver. O prompt cru da aula 1 é curto, e ligar o cache para ele não muda nada:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --set cache=on --out runs/short.jsonl
40 calls, prompt a4ffc4b1, written to runs/short.jsonl
ana@lab:~/triage$ pl cost runs/short.jsonl | head -n 5
tokens          count   per call
input            1459       36.5
cache_read          0        0.0
cache_write         0        0.0
output            907       22.7
```

Com 36,5 tokens por chamada, nenhum prompt chegou a 64, então nada foi lido nem gravado. O `--set`
aqui é só para experimentar; a aula 14 diz onde uma configuração deve ficar quando é para valer.

## Caches reais

Os provedores reais também guardam um prefixo, e **todo detalhe que importa é definido por eles**: o
tamanho de um bloco, o menor prompt que aceitam guardar, quanto tempo um prefixo sem uso fica
guardado, e quanto custa ler e gravar. Alguns aplicam o cache sozinhos a qualquer prompt longo o
bastante. A documentação de prompt caching da OpenAI descreve assim. Outros só guardam onde você
marca o fim do prefixo: a documentação da Anthropic pede um marcador `cache_control` na requisição.
Nenhum número do substituto é de algum provedor, então antes de contar com um cache, **leia a
documentação do seu provedor para o modelo que você chama**, e meça o que ele informa.

O que todas as versões têm em comum é a regra desta aula: o cache casa a partir do começo do prompt,
então o que vem primeiro decide o que pode ser reaproveitado.
