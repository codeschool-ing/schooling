---
title: As duas versões, medidas
version: 2
---

As mesmas cinco métricas para o conjunto de avaliação respondido por cada versão, das execuções da aula
10:

```
ana@dev:~/obs$ python metrics.py old new
run  release     ctx precision      ctx recall    faithfulness       relevance     correctness
old  2026.09.4     1.00 (n=19)     1.00 (n=19)     0.46 (n=24)     0.67 (n=24)     0.92 (n=24)
new  2026.10.1     1.00 (n=17)     0.89 (n=19)     0.45 (n=24)     0.58 (n=24)     0.67 (n=24)
```

**A correção cai de 0,92 para 0,67**, 22 e 16 certas de 24, e essa é a versão que a aula 5 ligou ao
piso. Os quatro números ao lado dizem para onde foram as seis respostas perdidas, e cada um pede leitura
cuidadosa.

**O context precision é 1,00 nas duas.** Sempre que o modelo recebeu alguma coisa, o trecho gold estava
lá e no topo. Não foi na busca que as respostas erraram.

**O context recall cai de 1,00 para 0,89**: na versão nova, duas perguntas que têm resposta, o
parcelamento e o direito de arrependimento, não receberam trecho nenhum, porque nenhum passou o piso mais
alto. São duas das seis. As outras quatro não são de recuperação: nas duas versões o modelo recebeu o
trecho certo para o e-book baixado e para o Kindle e recusou mesmo assim, e na nova fez o mesmo com o
exemplar autografado. **Context recall de 1,00 não quer dizer que a resposta chegou ao cliente**; quer
dizer que chegou ao modelo.

**A fidelidade é 0,46 e 0,45**, a nota do próprio juiz, e quase não se mexe. É baixa porque este juiz
dá notas baixas; a aula 10 mediu quanto se pode confiar nele, e a nota de fidelidade dele nunca foi
medida. **Uma métrica que ninguém conferiu contra pessoas é um número com um nome.**

**A relevância cai de 0,67 para 0,58**: as recusas decididas pelo gabarito, e os veredictos do juiz em
todo o resto. Ela se mexe pelo motivo certo, as recusas a mais, e continua feita de um juiz que reprovou
onze respostas boas na aula 10.

Então dois dos cinco números explicam a versão, a correção e o context recall, e são os dois com uma
referência por trás. Os dois que não precisam de referência, os que uma equipe consegue rodar em
produção, são aqueles em que este juiz é pior.

## Ler o n de uma métrica

Todo número leva a sua contagem, e as contagens diferem de propósito:

- **A context recall é sobre 19 perguntas** nas duas execuções: as cinco sem trecho gold não têm nada a
  recuperar, e ficam de fora em vez de contar como zero ou um.
- **A context precision é sobre 19 e 17**: só as perguntas em que o modelo recebeu alguma coisa. A
  versão nova não deu nada a mais duas perguntas, então a sua precisão é calculada sobre menos
  recuperações.

Uma média sem o seu n esconde exatamente isso. Duas precisões calculadas sobre conjuntos diferentes de
perguntas não são a mesma medição, e um painel que as mostra lado a lado sem as contagens convida à
conclusão errada.
