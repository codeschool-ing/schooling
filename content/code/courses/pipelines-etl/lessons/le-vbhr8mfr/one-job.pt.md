---
title: Um trabalho, três ferramentas
version: 1
---

O Airflow é o orquestrador que este curso usa desde a lição 8, e é o mais comum. Não é o único, e
três outros aparecem com frequência suficiente para um engenheiro de dados encontrá-los: o **Luigi**,
que saiu do Spotify em 2012 e é o mais velho dos quatro; o **Prefect**, que nasceu como reação ao
jeito do Airflow de escrever pipelines; e o **Dagster**, que põe no centro os dados que um pipeline
produz, e não os passos que ele dá.

Uma comparação justa é o mesmo trabalho em cada um. O da Ana é a carga noturna que ela já tem,
reduzida a três passos:

1. **carregar o raw**: `python load_raw.py`, como desde a lição 6;
2. **construir os modelos**: `dbt build`, que constrói e testa o projeto das lições 11 e 12;
3. **gravar o relatório**: um dia do `daily_sales` como arquivo CSV em `reports/`, para os gerentes.

Cada passo é o mesmo comando em toda ferramenta, rodado com `subprocess`. Só muda o que cerca os
comandos — como um passo é declarado, como a ordem é dita, o que conta como feito e o que fica
lembrado depois. Essas quatro diferenças são a lição.

Cada ferramenta está instalada num ambiente virtual próprio, porque cada uma fixa as suas próprias
versões das mesmas bibliotecas; o cabeçalho do laboratório explica o arranjo. E estas ferramentas
mudam rápido. As versões aqui são as do laboratório, os nomes das coisas podem ser outros na próxima
versão principal, e uma ou outra das três pode não ter mais manutenção quando isto for lido. **As
perguntas das últimas seções sobrevivem às ferramentas**, e é por isso que a lição termina nelas.
