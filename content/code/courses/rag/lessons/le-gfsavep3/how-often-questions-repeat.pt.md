---
title: Com que frequência as perguntas se repetem
version: 1
---

A aula 9 chamou de prematuro um cache semântico acrescentado antes de medir as perguntas repetidas. Aqui
está a medição:

```
ana@lab:~/rag$ python repeats.py
500 questions, 40 distinct as typed, 38 after lower-casing and dropping punctuation, 12 topics
  41  how many days do I have to return a printed book?
  34  how long do I have to return a book
  32  How many days do I have to return a printed book?
  32  Can I still return a book I got 3 weeks ago?
  28  return window for books
```

**500 perguntas, 40 distintas como foram digitadas, 38 ignorando maiúsculas e pontuação, 12 assuntos.** A
redação mais comum foi feita 41 vezes, e as cinco mais comuns são todas sobre o prazo de devolução.

É muito mais repetição do que uma fila real tem, e o motivo está no próprio cabeçalho do registro: ele foi
sorteado de quarenta redações que o curso escreveu. Um registro real de atendimento tem a mesma cabeça,
poucas perguntas feitas o tempo todo, e uma cauda longa de perguntas feitas uma vez, com erros de
digitação, em outras línguas, com um número de pedido dentro. **O formato é o que se transfere**, não os
números: uma equipe mede o próprio registro do mesmo jeito, perguntas distintas sobre o total, antes de
decidir que um cache vale a pena, e espera uma parte bem menor que 92%.

Os três números também dizem que tipo de cache poderia ajudar. Quarenta textos distintos e trinta e oito
depois de normalizar: um cache **exato**, que casa as mesmas palavras, pega quase tudo o que um
normalizador pegaria. Trinta e oito contra doze assuntos: um cache que casasse **sentido** poderia, em
princípio, responder com doze chamadas em vez de trinta e oito. As duas próximas seções testam os dois.
