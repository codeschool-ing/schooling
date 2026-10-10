---
title: Ler um painel com perguntas
version: 1
---

Aqui está um painel que uma diretora poderia receber sobre o time de Billing no fim de setembro, e duas leituras dele. Os números são os que a aula 5 calculou.

| métrica | junho e julho | agosto e setembro |
|---|---|---|
| deploys por semana | 1,0 | 4,4 |
| lead time de mudanças, mediana | 51 horas | 4,5 horas |
| taxa de falha de mudanças | 22% (2 de 9) | 5% (2 de 38) |
| tempo para restaurar, mediana | 166 minutos | 52 minutos |

## A primeira leitura

"Todos os números melhoraram três vezes ou mais. O time está num lugar muito melhor, então vamos definir as metas do próximo trimestre: oito deploys por semana e uma taxa de falha abaixo de 3%."

Toda frase dessa leitura está correta, menos a última, e a última desfaz o resto. Ela transforma quatro sintomas em quatro metas, que é exatamente o movimento contra o qual esta aula começou alertando, e as define sem perguntar o que produziu a melhora, então ninguém sabe se o time consegue ir além nem quanto isso custaria.

## A segunda leitura

A segunda leitora faz perguntas, e cada pergunta vem de uma das seções desta aula.

- **O que mudou?** Um limite de trabalho em andamento e revisões feitas primeiro. Nenhuma ferramenta, nenhuma pessoa nova. *O sintoma se moveu porque um hábito mudou.*
- **A melhora está nos números ou nas definições?** As definições foram as mesmas nos quatro meses. *Uma mudança de definição parece exatamente uma melhora.*
- **Quantos eventos há por trás de cada taxa?** Nove deploys antes, trinta e oito depois; duas falhas em cada período. A taxa de "antes" é frágil. *Cite contagens quando as taxas forem magras.*
- **O que esses números não conseguem ver?** O backlog: quem fazia pedidos ainda esperava um mês em setembro, a maior parte antes de alguém começar. As pessoas: nada aqui diz se a mudança custou as noites de alguém. O bug bloqueado: quarenta dias de idade, invisível para as quatro. *Todo painel precisa dos seus pontos cegos escritos ao lado.*
- **O que faríamos a seguir?** Encurtar o backlog; fazer os itens bloqueados contarem; manter os hábitos. Não "fazer deploy oito vezes por semana".

A segunda leitura demora mais, e é a única que diz à diretora algo sobre o que ela pode agir. **Quem lê bem um painel DORA passa mais tempo nas bordas do que nos números.** A aula 19 transforma esse hábito na estrutura de um relatório trimestral.
