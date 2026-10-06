---
title: Um teste que reprova o build
version: 1
---

Um teste que uma pessoa precisa lembrar de rodar é rodado quando alguém lembra. O último passo é fazer
da avaliação parte de toda mudança: rodá-la automaticamente, e fazê-la **falhar** quando a qualidade cai
abaixo de uma linha, para que a mudança não possa ser implantada até alguém olhar.

## O conjunto separado, finalmente

As comparações acima foram todas no dev. A decisão que elas apoiam, manter o piso em 0,5 e três fontes,
está tomada, então o terço separado pode ser usado, uma vez, para conferi-la:

```
ana@lab:~/rag$ python evaluate.py --split held-out --min-correct 0.7; echo "exit $?"
held-out: 10 questions, 8 answerable, floor 0.5, k 3
retrieval  recall@1 7/8  recall@3 8/8  recall@5 8/8  MRR 0.94
answers    correct 9/10  refused rightly 2/2  faithful 10/10
exit 0
```

**9 de 10 corretas em perguntas que não tiveram papel em decisão nenhuma**, as duas sem resposta
recusadas, e status de saída 0. O dev disse 15 de 20; o separado diz 9 de 10. Com dez perguntas as duas
não são diferentes de modo significativo, e é isso que se espera: uma nota no separado muito abaixo da
nota no dev diria que as escolhas foram ajustadas às perguntas do dev.

## Uma mudança que não deveria ir ao ar

Suponha que alguém suba o piso para 0,7 para deixar o assistente mais cauteloso:

```
ana@lab:~/rag$ python evaluate.py --split held-out --min-correct 0.7 --floor 0.7; echo "exit $?"
held-out: 10 questions, 8 answerable, floor 0.7, k 3
retrieval  recall@1 7/8  recall@3 8/8  recall@5 8/8  MRR 0.94
answers    correct 6/10  refused rightly 2/2  faithful 10/10
FAIL: 6/10 correct is below 70%
exit 1
```

**A correção caiu para 6 de 10 e a execução saiu com status 1.** A recuperação não mudou, a revocação em 3
continua 8 de 8; o que mudou é que o piso agora recusa perguntas com resposta cujo melhor pedaço marca
entre 0,5 e 0,7. Um job de integração contínua que roda esse comando em todo pull request bloqueia essa
mudança com uma mensagem dizendo por quê.

## Qual deveria ser a barra

O `--min-correct 0.7` é um julgamento, como todo limiar deste curso. Três jeitos de defini-lo, em ordem
crescente de cuidado:

- **Abaixo da nota de hoje, com folga**: o teste impede regressões sem exigir melhorias. Aqui, 9 de 10
  hoje e uma barra de 0,7 deixam espaço para uma pergunta virar num conjunto pequeno.
- **Por propriedade**: barras separadas para revocação em 3, correção e fidelidade, para uma queda numa
  não ficar escondida por um ganho em outra.
- **Por tipo de pergunta**: as perguntas de identificador da aula 6 e as de cliente daqui podem ter barras
  próprias, porque uma mudança pode ajudar umas e prejudicar as outras.

## Quanto custa rodar

A avaliação chama a busca e o gerador uma vez por pergunta. Contra um provedor real isso é uma conta de
verdade, pequena para trinta perguntas e perceptível para três mil, e um juiz a dobra. Dois arranjos
comuns: o conjunto inteiro toda noite, e uma amostra fixa de algumas dezenas em todo pull request. A aula
17 conta quanto custa uma consulta, e uma avaliação é só esse tanto de consultas.

O `check_index.py` da aula 5 confere o índice; este confere as respostas. Juntos são o que deixa uma
equipe mudar o corte, o modelo ou o prompt numa tarde qualquer e saber até a noite se melhorou.
