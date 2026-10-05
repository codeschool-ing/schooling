---
title: A matriz, com uma coluna vazia
version: 1
---

Tudo desta aula vai para uma tabela. As linhas são candidatos, as colunas são critérios, e os limites
vêm primeiro porque tiram linhas antes de qualquer ordenação.

| candidato | saída estruturada | janela ≥ 32k | termos lidos | rascunho, com cache | primeiro token p95 | acurácia na classificação |
|---|---|---|---|---|---|---|
| claude-haiku-4-5 | sim | 200.000 | sim | US$ 18,72 | a medir | aula 5 |
| claude-sonnet-5-5 | sim | 1.000.000 | sim | US$ 37,44 | a medir | aula 5 |
| gemini/gemini-3.5-flash-lite | sim | 1.048.576 | sim | US$ 8,02 | a medir | aula 5 |
| gpt-5.4-mini | sim | 272.000 | sim | US$ 15,84 | a medir | aula 5 |
| mistral/mistral-small-latest | sim | 262.144 | sim | US$ 2,45 | a medir | aula 5 |
| deepseek/deepseek-v3.2 | **não registrada** | 163.840 | sim | US$ 2,84 | a medir | aula 5 |

As colunas de saída estruturada e de janela vêm da tabela, os custos da seção 05, e "termos lidos" é a
anotação da própria ana na aula 2. **As duas últimas colunas estão vazias de propósito.**

## Lendo por tarefa

A matriz responde diferente para cada tarefa da ana, porque cada tarefa tem os seus limites:

- **A extração** precisa de saída estruturada. A DeepSeek V3.2 sai da lista para esta tarefa até
  ela conferir a documentação do próprio provedor; o silêncio de uma tabela é uma pergunta, não um
  não. Todo o resto fica.
- **A classificação** não precisa de contexto longo nem de saída estruturada, e ninguém está
  esperando. Toda linha fica, e vence o modelo mais barato que passar do piso de acurácia.
- **O rascunho** tem uma pessoa esperando, então o teto de latência da seção 06 vale, e é a tarefa
  em que a coluna de qualidade tem mais chance de separar as linhas baratas das caras.

## O passo que transforma isto numa decisão

As seis linhas cobrem um fator de uns quinze em custo, de US$ 2,45 a US$ 37,44, e todas são baratas
em termos absolutos para uma loja deste tamanho. **A decisão vai ser tomada pela coluna vazia.** Um
modelo que classifica 39 casos em 40 por US$ 8 por mês ganha de um que classifica 34 por US$ 2, e o
contrário pode valer para o rascunho.

A aula 5 preenche a coluna. No laboratório deste curso os candidatos são interpretados pelos três
modelos do substituto, um para cada tipo de linha: `standin-large` para a faixa cara,
`standin-small` para a faixa barata, `standin-local` para um modelo aberto que a ana rodaria ela
mesma. **As respostas deles foram escritas pelo curso**, então as notas que eles tiram também são do
curso. O que vale para candidatos reais é o harness, a pontuação e a leitura dos resultados, que são
as partes difíceis de acertar.
