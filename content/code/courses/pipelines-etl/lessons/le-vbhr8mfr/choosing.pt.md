---
title: Escolher, e o que dura mais que a escolha
version: 1
---

Uma equipe raramente escolhe um orquestrador numa tabela. Ela herda um, ou a plataforma em que roda
oferece um, ou alguém já conhece um. Ainda assim, o laboratório sugere onde cada um se encaixa:

- **Airflow** quando há muitos pipelines em horários fixos, com donos diferentes, e o valor está em um
  lugar que roda todos, tenta de novo e diz o que falhou — e quando as versões gerenciadas que toda
  nuvem vende são uma opção. O custo é a maquinaria: quatro processos no laboratório, um banco de
  metadados e arquivos de DAG que precisam continuar baratos de ler.
- **Luigi** para trabalhos em lote que produzem arquivos, em que *o arquivo existe* de fato quer dizer
  *o trabalho está feito*. Ele é pequeno e tem poucas peças. Também é o menos ativamente desenvolvido
  dos quatro, e a ideia dele de feito combina mal com um banco, como as marcas mostraram.
- **Prefect** quando o pipeline é quase todo Python e a forma dele se decide enquanto roda — um laço
  sobre o que a API devolveu, um desvio conforme um resultado. Nada mais aqui deixa isso tão simples.
- **Dagster** quando o importante são os dados, e as perguntas são *o que está desatualizado e o que
  isso alimenta* — que é perto do que o dbt pergunta dentro do warehouse, e por que os dois costumam
  ser usados juntos.

O que dura mais que a escolha são as quatro perguntas da seção anterior, e três hábitos que o curso
construiu independentemente da ferramenta. **Todo passo seguro para rodar duas vezes**, porque cada
uma destas ferramentas vai, cedo ou tarde, rodar um passo duas vezes. **Toda regra sobre os dados
conferida por uma máquina**, porque nenhuma delas sabe se os números estão certos. **E o dia a
carregar tirado da execução, nunca do relógio**, porque cada uma delas pode refazer ontem. Um pipeline
escrito assim passa de um orquestrador a outro como uma troca de embrulho, que é exatamente o que
esta lição fez três vezes.
