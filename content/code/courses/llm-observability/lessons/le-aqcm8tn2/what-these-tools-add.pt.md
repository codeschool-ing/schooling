---
title: O que uma plataforma acrescenta a um armazém de traces
version: 2
---

Todo trace das aulas 1 a 5 foi para um arquivo, e toda pergunta foi um script Python sobre ele. Isso
escala para uma semana numa máquina. Não escala para uma equipe, e a aula 11 do `observability` já
pôs traces no Jaeger e no Zipkin, que os desenham para qualquer um com um navegador. Então por que
aplicações com LLM têm ferramentas próprias?

Porque as perguntas são outras. Um backend de rastreamento genérico conhece spans, durações e erros.
Ele não sabe que um span foi uma chamada a modelo com um prompt e uma resposta, que os seus tokens têm
preço, que um cliente deu polegar para baixo à resposta, ou que o mesmo modelo de prompt foi editado
quatro vezes este mês. As ferramentas desta aula e da próxima são backends de rastreamento com essas
coisas embutidas:

| o que acrescentam | para que serve | onde este curso construiu à mão |
|---|---|---|
| a chamada a modelo como coisa de primeira classe, com prompt, resposta, tokens e custo | ler uma resposta ruim | aulas 1 e 3 |
| usuários e sessões | acompanhar uma pessoa, ou uma conversa | aulas 2 e 3 |
| **notas** ligadas a um trace | polegares, juízes, pessoas, todos ligados por id | aulas 5 e 9 |
| conjuntos de dados e experimentos | rodar o conjunto de avaliação contra uma mudança | aulas 13 e 14 |
| gestão de prompts | versionar o prompt fora do código | aula 14 |

Duas das ferramentas mais conhecidas feitas para isso ficam nas duas pontas de uma escolha que toda
equipe faz. O **Langfuse** é código aberto sob a licença MIT, e pode rodar nas suas máquinas ou ser
usado como serviço hospedado. O **LangSmith** é o serviço hospedado da LangChain; instalá-lo nas
próprias máquinas é oferecido a clientes corporativos. O resto desta aula roda o primeiro na sua
máquina, e roda o SDK do segundo contra um pequeno gravador seu, porque o serviço em si só roda na
máquina de outra empresa.

## O que continua igual

Nenhuma das duas ferramentas muda o que as aulas 1 a 5 disseram que um trace precisa levar. Uma
plataforma mostra os atributos que recebe. Um trace sem entrada no span de busca é ilegível no Langfuse
exatamente como era no `tree.py`, e um custo calculado com o preço errado está errado numa tela mais
bonita. O trabalho de decidir o que registrar é da aplicação, e as próximas seções mostram que a
principal contribuição da plataforma para ele é um conjunto de nomes que ela espera.
