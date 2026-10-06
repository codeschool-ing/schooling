---
title: De olho na conta
version: 1
---

Um custo medido uma vez é o custo daquela semana. O pipeline o mantém medido registrando-o, o que a aula
9 já faz: o registro de cada consulta leva os tokens de prompt e de resposta. A partir desse registro,
quatro números valem ser acompanhados todo dia.

- **Tokens por consulta respondida**, entrada e saída separadas. Uma alta quer dizer que os prompts
  cresceram: um `k` maior, um histórico mais longo, um documento que virou um pedaço enorme. O orçamento
  da aula 12 deveria deixá-lo estável, e uma alta quer dizer que algo passou por fora do orçamento.
- **A parte das perguntas recusadas antes do modelo.** É a resposta mais barata que o pipeline dá. Uma
  queda repentina pode querer dizer que o piso foi baixado, ou que o índice começou a casar com tudo.
- **A taxa de acerto do cache**, e para um cache semântico, uma amostra dos acertos conferida por uma
  pessoa toda semana. Uma taxa de acerto que sobe depois de uma mudança de limite é um custo descendo e
  um risco subindo.
- **Custo por usuário por dia**, com um limite. Uma única conta mandando milhares de perguntas, por
  script ou por engano, é uma conta que ninguém planejou, e um limite por conta é o controle para o qual o
  teto de gastos do próprio provedor é grosso demais.

O `llm-observability`, mais adiante nesta trilha, constrói os painéis, os traces e os alertas para isso.
O que este curso lhe deixa é o hábito por trás deles: toda decisão que muda o que é mandado a um modelo,
o piso, o orçamento, a memória, o cache, tem um custo em tokens que pode ser contado, e foi contado aqui
antes de ser tomada.
