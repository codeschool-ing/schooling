---
title: Perguntar ao time, e ler o que ele diz
version: 1
---

Uma pesquisa é o jeito mais barato de medir as dimensões que nenhum sistema registra. Também é fácil de fazer mal, e uma pesquisa ruim é pior que nenhuma, porque as pessoas param de responder com sinceridade no momento em que suspeitam que ela está sendo usada contra elas.

## Cinco regras

- **Poucas perguntas, sempre as mesmas.** Cinco afirmações por trimestre, sem mudança, valem mais que trinta que mudam. O valor está na tendência, e uma tendência precisa da mesma pergunta.
- **Anônima, de verdade.** Sem nomes, sem recortes de time pequenos a ponto de identificar alguém, sem texto livre que possa ser reconhecido pelo estilo se o time for pequeno. Se as pessoas não puderem confiar nisso, as respostas são ficção.
- **Afirmações sobre a experiência, não sobre colegas.** "As revisões do meu trabalho chegam rápido" mede o sistema; "meus colegas revisam com presteza" convida à culpa.
- **Mostre tudo, como distribuições.** Toda resposta a toda afirmação, como contagens. Nada de médias em grupos pequenos.
- **Diga o que vai fazer com ela, e depois faça.** Uma pesquisa seguida de nada ensina as pessoas a não responder a próxima.

## A pesquisa do time de Billing

Aqui está uma pesquisa que o time de Billing poderia ter feito ao fim de cada trimestre, escrita para o curso como o resto do seu histórico. **Salve o programa abaixo como `survey.py`.** Ele não precisa de nenhum outro arquivo.

```schooling-example
{
  "language": "python",
  "file": "survey.py",
  "parts": [
    {
      "code": "\"\"\"survey.py: a team's quarterly survey, read as distributions rather than averages.\"\"\"\nimport statistics\n\n# Five statements, each answered from 1 (strongly disagree) to 5 (strongly agree).\n# One string per quarter, one digit per person, in no particular order: anonymous.\nSURVEY = {\n    \"I can work on one thing without interruption most days\": {\"Q2\": \"221321\", \"Q3\": \"434434\"},\n    \"When I ask for a review, it arrives quickly\": {\"Q2\": \"112212\", \"Q3\": \"454445\"},\n    \"I know what the team is trying to finish this month\": {\"Q2\": \"332423\", \"Q3\": \"444534\"},\n    \"I finished most weeks with energy left\": {\"Q2\": \"333234\", \"Q3\": \"454414\"},\n    \"I would recommend this team to a friend\": {\"Q2\": \"434344\", \"Q3\": \"454544\"},\n}\n",
      "note": "**A pesquisa é o dado.** Cinco afirmações, as mesmas cinco todo trimestre, e seis respostas para cada: a Bia e os cinco devs. As respostas foram escritas para o curso, como o resto do histórico do time de Billing. A ordem dos dígitos não significa nada, então nenhuma resposta pode ser ligada a uma pessoa pela posição."
    },
    {
      "code": "\nfor statement, quarters in SURVEY.items():\n    print(statement)\n    for quarter, answers in quarters.items():\n        scores = [int(a) for a in answers]\n        bars = \"  \".join(f\"{n}:{'#' * scores.count(n):<6}\" for n in range(1, 6))\n        print(f\"  {quarter}  {bars} median {statistics.median(scores)}\")\n",
      "note": "**Toda resposta aparece, como contagem por nota**, com a mediana ao lado. Sem média: com seis pessoas, uma resposta mexe muito numa média, e uma contagem mostra exatamente para que lado."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 survey.py
I can work on one thing without interruption most days
  Q2  1:##      2:###     3:#       4:        5:       median 2.0
  Q3  1:        2:        3:##      4:####    5:       median 4.0
When I ask for a review, it arrives quickly
  Q2  1:###     2:###     3:        4:        5:       median 1.5
  Q3  1:        2:        3:        4:####    5:##     median 4.0
I know what the team is trying to finish this month
  Q2  1:        2:##      3:###     4:#       5:       median 3.0
  Q3  1:        2:        3:#       4:####    5:#      median 4.0
I finished most weeks with energy left
  Q2  1:        2:#       3:####    4:#       5:       median 3.0
  Q3  1:#       2:        3:        4:####    5:#      median 4.0
I would recommend this team to a friend
  Q2  1:        2:        3:##      4:####    5:       median 4.0
  Q3  1:        2:        3:        4:####    5:##     median 4.0
```

## Lendo o resultado

**As duas primeiras afirmações foram as que mais se moveram, e elas concordam com os arquivos.** O foco foi de uma mediana de 2 para 4, e as revisões chegando rápido, de 1,5 para 4. As aulas 2 a 4 mediram a mesma mudança a partir do quadro: um item por pessoa, e revisões feitas primeiro. Quando a pesquisa e os dados do sistema dizem a mesma coisa, cada um torna o outro mais crível.

**A quarta afirmação é a que merece um segundo olhar.** A mediana subiu de 3 para 4, o que um resumo reportaria como boa notícia. Mas uma pessoa respondeu **1**: terminou a maioria das semanas sem energia nenhuma, num trimestre em que os outros se sentiram melhor que antes. Num time de seis, uma única resposta no fundo não é uma estatística; é uma pessoa, e uma média a teria escondido por completo, já que as seis respostas têm média 3,7. Nada na pesquisa diz quem é, e nada deveria dizer. O que ela diz é que a tech lead tem uma conversa a tornar possível, sem perguntar quem: a aula 17 olha para um dos motivos mais comuns, a escala de plantão.

## Times pequenos e anonimato

Um time de seis está perto do limite em que uma pesquisa consegue continuar anônima. Se uma pessoa sempre responde do mesmo jeito e todo mundo sabe quem é, a distribuição a entrega. A prática comum em organizações maiores é mostrar resultados só quando pelo menos cinco pessoas responderam, e nunca recortar um time pequeno ainda mais. Para um time do tamanho do Billing, vale dizer em voz alta, toda vez, para que os resultados serão e não serão usados, e a aula 20 transforma isso num acordo escrito.
