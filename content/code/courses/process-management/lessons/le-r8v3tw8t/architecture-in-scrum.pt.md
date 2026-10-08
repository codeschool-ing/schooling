---
title: Onde a arquitetura cabe numa Sprint
version: 1
---

O Guia do Scrum não menciona arquitetura, documentos de projeto nem arquitetos. Esse silêncio é lido de dois jeitos, e os dois estão errados: que times Scrum não fazem projeto antecipado nenhum, e que a arquitetura tem de acontecer fora do Scrum, numa fase separada. O que o guia deixa em aberto é **como** o trabalho de projeto é feito e registrado, que é a mesma liberdade que ele dá a qualquer outra prática.

## Arquitetura como trabalho de backlog

O trabalho de projeto de que o produto precisa entra no Product Backlog como qualquer outro, ordenado pelo Product Owner junto com as funcionalidades. Um item como *"escolher e provar a forma de guardar agendamentos para que duas clínicas nunca vejam os pacientes uma da outra"* tem valor porque remove um risco, e a aula 12 mostra como esse valor é pesado contra funcionalidades. O Product Owner não precisa entender o projeto; precisa entender o que acontece com o produto se ele não for feito.

Quando o time não sabe o bastante para estimar um trabalho, pode fazer um **spike**: uma investigação curta, com tempo limitado, cujo resultado é conhecimento e não funcionalidade — um protótipo que responde *"a biblioteca de calendário dá conta das consultas recorrentes da clínica?"*. A palavra vem do Extreme Programming, que a aula 4 cobre, e a prática cabe no backlog do Scrum sem mudança.

## Arquitetura na Definição de Pronto

Atributos de qualidade que toda mudança precisa manter pertencem à Definição de Pronto, como a quinta seção desta aula defendeu: um limite de tempo de resposta, um formato de log, uma varredura de segurança. Isso põe as decisões do arquiteto em toda Sprint sem uma tarefa separada para cada uma.

## Onde fica o arquiteto

Um arquiteto que trabalha com times Scrum está num de dois lugares. **Num time**, como um dos Desenvolvedores, ele pega itens do Sprint Backlog como todo mundo e conduz as discussões de projeto por dentro. **Entre times**, atendendo vários, ele participa dos refinamentos e revisões onde o projeto é decidido, registra as decisões — registros de decisão de arquitetura (ADRs) são a forma habitual — e toma cuidado para não virar um portão por onde todo item tem de passar. A aula 5 volta a isso, porque é a situação normal quando há mais de um time.

## Projeto suficiente, cedo o bastante

A pergunta prática é quanto decidir antes da primeira Sprint. A resposta a que os autores ágeis chegaram é **as decisões que seriam caras de reverter**: o armazenamento de dados, as fronteiras entre serviços, o jeito como a identidade funciona, a plataforma de hospedagem. Essas recebem uma decisão deliberada nas primeiras Sprints, muitas vezes com um spike por trás de cada uma. Tudo o que é barato de mudar depois fica para quando o time souber mais, que é o cone da incerteza da aula 1 posto para trabalhar.
