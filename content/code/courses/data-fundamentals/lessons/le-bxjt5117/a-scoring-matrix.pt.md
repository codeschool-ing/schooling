---
title: Uma matriz de pontuação, e o que ela não decide
version: 1
---

**Uma matriz de decisão ponderada transforma uma escolha em aritmética, e a aritmética é a parte menos
importante dela.** O método é curto. Liste as opções. Liste os critérios. Dê uma nota a cada opção em
cada critério. Dê a cada critério um peso pelo quanto ele importa, multiplique, some. O maior total
vence, e a armadilha é acreditar nessa última frase.

A Roda Livre tem uma escolha de verdade para fazer. O relatório da van de Marta precisa de tabelas em
algum lugar onde possam ser consultadas, e o time reduziu as opções a três: um **servidor PostgreSQL
que o próprio time roda**, um **warehouse gerenciado** de um provedor de nuvem, ou **arquivos Parquet
num armazenamento de objetos**, com um motor de consulta lendo-os. Davi dá notas a elas em cinco
critérios tirados da seção anterior. Salve isto como `matrix.py`:

```schooling-example
{"language": "python", "file": "choose/matrix.py", "parts": [
{"code": "# choose/matrix.py\nCRITERIA = [\"known\", \"bill\", \"upkeep\", \"growth\", \"exit\"]\n\nSCORES = {                    # 1 is poor and 5 is good, in Davi's judgement\n    \"PostgreSQL we run\":  [5, 4, 2, 2, 5],\n    \"managed warehouse\":  [3, 2, 5, 5, 2],\n    \"Parquet in storage\": [2, 5, 3, 4, 4],\n}\n", "note": "Cinco critérios: o quanto o time já conhece, o quanto a conta é pequena, quão poucas horas leva para manter funcionando, quanto espaço tem para crescer e quão fácil é sair. O 5 é sempre a ponta boa, então uma opção barata tira nota alta em `bill`."},
{"code": "\nWEIGHTS = {\n    \"a team of two\":    [3, 2, 3, 1, 1],\n    \"a year of growth\": [1, 1, 2, 4, 2],\n}\n", "note": "Dois conjuntos de pesos, cada um somando dez, para duas visões do ano que vem. O primeiro diz que as horas do time importam mais; o segundo, que o espaço para crescer importa mais."},
{"code": "\nfor label, weights in WEIGHTS.items():\n    print(f\"weighted for {label}:\", dict(zip(CRITERIA, weights)))\n    totals = {\n        option: sum(w * s for w, s in zip(weights, scores))\n        for option, scores in SCORES.items()\n    }\n    for option, total in sorted(totals.items(), key=lambda kv: -kv[1]):\n        print(f\"  {option:20}{total:3}\")\n", "note": "Para cada conjunto de pesos, cada nota é multiplicada pelo peso do seu critério e os produtos são somados. As opções saem da maior para a menor."}
]}
```

Rode:

```
ana@lab:~/roda/choose$ python matrix.py
weighted for a team of two: {'known': 3, 'bill': 2, 'upkeep': 3, 'growth': 1, 'exit': 1}
  PostgreSQL we run    36
  managed warehouse    35
  Parquet in storage   33
weighted for a year of growth: {'known': 1, 'bill': 1, 'upkeep': 2, 'growth': 4, 'exit': 2}
  managed warehouse    39
  Parquet in storage   37
  PostgreSQL we run    31
```

## Os pesos escolhem o vencedor

Com os pesos de um time de dois, o servidor que o time roda vence por um ponto, 36 a 35. Com os pesos
de um ano de crescimento, as mesmas notas põem o warehouse gerenciado em primeiro, com 39, e o servidor
em último, com 31. **Nada nas opções mudou entre as duas execuções. Só as prioridades mudaram.**

E um ponto é menos do que a incerteza de qualquer nota sozinha. Davi deu 3 ao warehouse gerenciado em
quanto o time o conhece. Caio, que usou um no emprego anterior, diria 4. Mude essa única célula com
`sed`, como a aula 1 fez, e rode de novo a primeira classificação:

```
ana@lab:~/roda/choose$ sed "s/\[3, 2, 5, 5, 2\]/[4, 2, 5, 5, 2]/" matrix.py > nudged.py
ana@lab:~/roda/choose$ python nudged.py | head -4
weighted for a team of two: {'known': 3, 'bill': 2, 'upkeep': 3, 'growth': 1, 'exit': 1}
  managed warehouse    38
  PostgreSQL we run    36
  Parquet in storage   33
```

O warehouse gerenciado agora vence com 38. Um julgamento, movido em um, num critério, inverteu o
resultado.

## Então, para que serve?

Não para produzir a resposta. Uma matriz é útil para outras três coisas, e as três são sobre pessoas.

- **Ela mostra onde as pessoas discordam.** Davi e Caio não discordam sobre o warehouse; discordam
  sobre se o próximo ano é sobre as horas do time ou sobre crescimento. Essa é uma pergunta para
  Marta, e foi a matriz que a tornou visível.
- **Ela obriga a escrever cada critério.** Um critério que ninguém escreveu continua decidindo o
  resultado, pela boca de quem fala mais alto.
- **Ela registra o raciocínio.** Daqui a um ano alguém vai perguntar por que o time escolheu o que
  escolheu. Uma matriz com seus pesos responde melhor do que a memória de qualquer pessoa.

Dois hábitos a estragam. **Dar as notas depois de decidir**: quem já prefere uma opção ajusta os
números até ela vencer, e a matriz lava uma preferência transformando-a em cálculo. E **contar a mesma
coisa duas vezes**: `bill`, a conta, e `upkeep`, a manutenção, são ambos custo, e uma matriz com cinco critérios de custo e
um para todo o resto decidiu antes de alguém dar nota. Quando os totais estão tão próximos quanto 36 e
35, a saída honesta é "estas duas são equivalentes nos nossos critérios", e a escolha passa para algo
que a matriz não contém, como qual erro é mais fácil de desfazer.
