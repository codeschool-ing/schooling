---
title: Uma rubrica, e duas pessoas lendo
version: 1
---

Uma **rubrica** é o que se diz a quem avalia: o critério, os veredictos possíveis e o que decide entre
eles. O juiz recebe uma no prompt de sistema, no `judge.py`. As pessoas precisam de uma pelo mesmo
motivo, e a primeira versão que a equipe escreveu para relevância é a frase do juiz, arrumada para uma
pessoa:

```
ana@lab:~/obs$ cat data/rubrics/relevance-v1.md
# Relevance, version 1

Read the customer's question and the assistant's reply.

Does the reply address the question the customer asked?

- pass: it does
- fail: it does not
```

Duas escolhas nela são de propósito, e as duas são o conselho de costume para uma primeira rubrica.

**Passa ou falha, não uma nota de 1 a 5.** Uma escala pede que quem avalia ponha a resposta numa linha,
e duas pessoas põem a mesma resposta a um ponto de distância sem discordar de nada: uma dá 4 a tudo o
que é bom e a outra guarda o 5 para o excepcional. Cada degrau de uma escala precisa da sua própria
descrição para significar o mesmo para todos, e uma equipe escrevendo a sua primeira rubrica ainda não
sabe quais são os degraus. Um veredicto binário faz uma pergunta só, e uma discordância nela é uma
discordância de verdade.

**Um critério.** Só relevância, não relevância, fidelidade e tom num veredicto. Uma pessoa avaliando
três coisas de uma vez avalia a que notou primeiro, e uma falha não consegue dizer qual das três falhou.

## Os rótulos

A Ana e o Bruno leram cada um as sessenta respostas, com as perguntas e as fontes, e escreveram um
veredicto para cada uma pela versão 1. Cada rótulo é uma linha de `data/labels.jsonl`, que nomeia a
resposta pelo id da pergunta e pela versão que respondeu:

```
ana@lab:~/obs$ head -3 data/labels.jsonl
{"case": "e01", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
{"case": "e02", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
{"case": "e03", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
ana@lab:~/obs$ wc -l data/labels.jsonl
300 data/labels.jsonl
```

Trezentas linhas: sessenta respostas, rotuladas por duas pessoas pela versão 1, pelas mesmas duas pela
versão 2, e mais uma vez com o veredicto que combinaram depois de conversar, ao qual as próximas seções
chegam.

As respostas são as do conjunto de avaliação, rodado de novo pelo `evalrun.py` da aula 8, uma vez como
cada versão:

```
ana@lab:~/obs$ python evalrun.py old --release 2026.09.4
runs/old.jsonl: 30 questions, release 2026.09.4
ana@lab:~/obs$ python evalrun.py new --release 2026.10.1
runs/new.jsonl: 30 questions, release 2026.10.1
```

A versão da rubrica está em cada rótulo, e isso importa tanto quanto o id da resposta. Um rótulo escrito
pela versão 1 diz o que alguém achou que a versão 1 queria dizer; misturá-lo com rótulos escritos por
uma versão com instruções diferentes não mede nada.
