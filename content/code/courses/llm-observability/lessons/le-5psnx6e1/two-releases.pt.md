---
title: As duas versões, medidas
version: 1
---

Os mesmos cinco números para o conjunto de avaliação respondido por cada versão, das execuções da aula
10:

```
ana@lab:~/obs$ python metrics.py old new
run  release     ctx precision      ctx recall    faithfulness       relevance     correctness
old  2026.09.4     0.91 (n=20)     0.73 (n=26)     1.00 (n=30)     1.00 (n=30)     0.63 (n=30)
new  2026.10.1     0.94 (n=16)     0.56 (n=26)     1.00 (n=30)     1.00 (n=30)     0.53 (n=30)
```

**Duas das cinco não se mexem, e as duas são 1,00.** Não são duas versões perfeitas. A fidelidade é
1,00 porque o extract-1 copia frases das suas fontes, então toda frase tem apoio por construção; a aula
8 de `rag` achou o mesmo com uma regra. A relevância é 1,00 porque o judge-1 no limiar de 0,40 aprova
toda resposta que lê, o que a aula 10 mediu e a seção anterior explicou. **Uma métrica que não consegue
cair não diz nada quando não cai.** Antes de pôr um número ao lado de uma versão, alguém precisa tê-lo
visto falhar numa resposta que merecia.

**As três com referência se mexem, e se mexem juntas.** A correção cai de 0,63 para 0,53, os mesmos 19
e 16 certos em 30 que a aula 8 contou. A context recall cai mais, de 0,73 para 0,56: o piso de 0,62
descarta trechos que tinham a resposta, e em quatro perguntas descarta todos, então o modelo nunca os vê
e recusa. E a context precision **sobe**, de 0,91 para 0,94, porque os trechos que sobrevivem ao piso
mais alto são mais vezes os certos.

Esse último par é a troca da seção anterior, na busca em vez de num juiz. **O piso é um limiar**: subir
o piso comprou precisão com revocação, e a revocação era a que importava, porque um modelo não usa um
trecho que nunca recebeu. Uma equipe olhando só a context precision teria relatado a versão como uma
melhora.

## Ler o n de uma métrica

Todo número leva a sua contagem, e as contagens diferem de propósito:

- **A context recall é sobre 26 perguntas** nas duas execuções: as quatro sem seção gold não têm nada a
  recuperar, e ficam de fora em vez de contar como zero ou um.
- **A context precision é sobre 20 e 16**: só as perguntas em que o modelo recebeu alguma coisa. A versão
  nova recusou mais quatro perguntas sem trechos, então a sua precisão é calculada sobre menos
  recuperações, e melhores.

Uma média sem o seu n esconde exatamente isso. Duas precisões calculadas sobre conjuntos diferentes de
perguntas não são a mesma medição, e um painel que as mostra lado a lado sem as contagens convida à
conclusão errada.
