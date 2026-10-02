---
title: Uma mudança de cada vez
version: 1
---

O jeito óbvio de comparar duas maneiras de escrever um prompt é rodar as duas e ficar com a que
pontua mais. **Isso só funciona quando a redação é a única coisa diferente entre as duas
execuções.** Um experimento muda uma coisa, no mesmo conjunto de teste, com os mesmos parâmetros, ou
o número que ele produz não consegue dizer qual mudança fez o quê.

Veja o que acontece quando essa regra escapa. `prompts/v6-escaped.txt` lista os campos em tópicos, e
`prompts/v7-prose.txt` diz as mesmas coisas num parágrafo. Alguém roda a versão em prosa para ver se
o modelo a entende melhor, e por acaso deixa no comando uma temperatura de amostragem de 0.8, sobra
de um experimento anterior:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl
70 calls, prompt 7864b0b5, written to runs/v7-warm.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/v7-warm.jsonl
runs/v6.jsonl            passes 46/70
runs/v7-warm.jsonl       passes 33/70
fixed 1, broken 14, still passing 32, still failing 23
broken: t06 t08 t10 t13 t18 t20 t21 t22 t25 t29 t37 h05 h07 h12
sign test on the 15 that changed: p = 0.001
```

Catorze mensagens quebraram e uma foi corrigida, e o teste do sinal dá p = 0.001. Como evidência de
que algo mudou, é forte. Como evidência de que **prosa é pior que tópicos, não vale nada**, porque
duas coisas mudaram e a comparação não consegue separá-las. Temperatura é o assunto da aula 8; por
ora basta saber que ela faz o substituto escolher o rótulo por sorteio, e que esta execução são duas
mudanças usando o nome de uma.

É uma armadilha fácil porque o arquivo da execução não registra isso:

```
ana@lab:~/triage$ head -n 1 runs/v7-warm.jsonl
{"case": "t01", "sample": 0, "prompt": "7864b0b5", "cases": "cases/all.jsonl", "text": "{\n  \"category\": \"billing\",\n  \"urgency\": \"high\",\n  \"summary\": \"They were charged twice for order 4471.\"\n}", "stop": "end", "usage": {"input": 121, "cache_read": 0, "cache_write": 0, "output": 32}, "latency_ms": 1127}
```

Cada linha de uma execução guarda a mensagem, o id do prompt, o conjunto de teste, a resposta, o
motivo da parada, os tokens e o tempo. **Ela não guarda os parâmetros que você passou com `--set`.**
O id `7864b0b5` é um hash do arquivo do prompt, então é idêntico para o prompt em prosa com
temperatura 0 e com 0.8. A aula 14 versiona prompts direito; até lá, anote o comando junto com a
execução.

## O que fica fixo

- **O conjunto de teste.** As duas execuções leem `cases/all.jsonl`, as setenta mensagens. Duas
  execuções em mensagens diferentes comparam as mensagens tanto quanto os prompts.
- **Os parâmetros.** Temperatura, o limite de saída e tudo o mais que dá para passar com `--set`.
- **Tudo no prompt, menos a mudança.** Os mesmos rótulos, na mesma ordem, com os mesmos exemplos ou
  nenhum.
- **A comparação é mensagem a mensagem.** O `pl compare` alinha os dois resultados de cada
  mensagem, porque dois totais que diferem em dois podem esconder catorze mensagens andando em
  sentidos opostos.

A próxima seção refaz o experimento, com a temperatura no lugar dela.
