---
title: Avisar alguém, e quando
version: 1
---

Um retry absorve o que passa. O que não passa precisa chegar a uma pessoa, e há duas perguntas
diferentes que uma pessoa quer ver respondidas: **algo falhou?** e **algo está atrasado?** Não são
a mesma pergunta, e o Airflow as responde com dois mecanismos diferentes.

## Um callback de falha

O `on_failure_callback` é uma função que o Airflow chama quando uma instância de tarefa termina em
`failed` — não quando uma tentativa falha, mas quando **a tarefa falhou de vez**: os retries
acabaram, ou ela levantou `AirflowFailException`, ou estourou o tempo sem retries sobrando. Ele roda
no mesmo processo que a tarefa, depois dela, e recebe o contexto dela. O `failed` da Ana escreve uma
linha com o que uma pessoa precisa para começar: o DAG e a tarefa, a execução, a tentativa a que ela
chegou e a exceção.

Posto em `default_args`, ele vale para toda tarefa do DAG. Em geral isso é o certo: um pipeline em
que uma tarefa pode falhar sem ninguém ficar sabendo é a falha silenciosa que este curso vem evitando
desde a lição 1.

Existe também o `on_retry_callback`, chamado a cada tentativa falha que vai ser repetida, e o
`on_success_callback`. A Ana não usa nenhum dos dois: um retry não é notícia, e um sucesso é o que
deve acontecer. **Um canal de alertas que fala quando nada está errado ensina as pessoas a pararem de
lê-lo.**

## Um prazo

Um callback de falha não enxerga uma execução lenta. Uma noite em que a API responde cada página em
vinte segundos em vez de um, ou uma tarefa presa atrás do lock de outro DAG, nunca falha — ela só
termina às nove da manhã, depois que o relatório que precisava dela saiu com os preços de ontem.
**A pergunta ali não é se algo falhou, e sim se o trabalho fica pronto quando é preciso.**

O Airflow 2 chamava isso de SLA, e o Airflow 3 o removeu. O que entra no lugar é um **prazo**
(*deadline*): um momento de referência, um intervalo depois dele, e um callback a rodar se a execução
não tiver terminado até lá. O da Ana é `DeadlineReference.DAGRUN_QUEUED_AT` mais dois minutos — a
escala do laboratório; em produção, algo como *a data lógica mais três horas*, a hora em que o
relatório da manhã é lido.

O prazo pertence à **execução** e é vigiado pelo agendador, não por uma tarefa, então ele dispara
mesmo enquanto toda tarefa está esperando ou tentando de novo. O callback dele roda no triggerer, e é
por isso que ele precisa ser `async`, e por isso que o `oncall.py` fica na pasta de plugins.

A próxima seção é a noite para a qual os dois foram escritos.
